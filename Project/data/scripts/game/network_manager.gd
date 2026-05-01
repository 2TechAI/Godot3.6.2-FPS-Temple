extends Node

# Network configuration
const DEFAULT_PORT = 7777
const MAX_PLAYERS = 8

# Player info
var local_player_id = 0
var players = {}  # { peer_id: { name, ready } }

# Signals
signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal connection_failed()
signal connection_succeeded()
signal server_disconnected()
signal player_list_changed()

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func create_server(port = DEFAULT_PORT):
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Failed to create server: " + str(err))
		return false
	get_tree().network_peer = peer
	local_player_id = get_tree().get_network_unique_id()
	players[local_player_id] = { "name": "Host", "ready": true }
	print("Server created on port ", port)
	return true

func join_server(ip = "127.0.0.1", port = DEFAULT_PORT):
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("Failed to create client: " + str(err))
		return false
	get_tree().network_peer = peer
	local_player_id = get_tree().get_network_unique_id()
	print("Connecting to ", ip, ":", port)
	return true

func is_server() -> bool:
	return get_tree().is_network_server()

func is_multiplayer() -> bool:
	return get_tree().network_peer != null

func close_connection():
	if get_tree().network_peer:
		get_tree().network_peer.close_connection()
		get_tree().network_peer = null
	players.clear()

# Callbacks
func _on_player_connected(peer_id):
	print("Player connected: ", peer_id)
	if is_server():
		# Send existing players to new player
		for pid in players:
			rpc_id(peer_id, "_register_player", pid, players[pid])
		# Register new player
		players[peer_id] = { "name": "Player " + str(peer_id), "ready": false }
		# Notify all players about new player
		rpc("_register_player", peer_id, players[peer_id])
	emit_signal("player_connected", peer_id)
	emit_signal("player_list_changed")

func _on_player_disconnected(peer_id):
	print("Player disconnected: ", peer_id)
	players.erase(peer_id)
	emit_signal("player_disconnected", peer_id)
	emit_signal("player_list_changed")
	# Despawn player character in game
	_despawn_player(peer_id)

func _on_connected_to_server():
	local_player_id = get_tree().get_network_unique_id()
	players[local_player_id] = { "name": "Player " + str(local_player_id), "ready": true }
	emit_signal("connection_succeeded")

func _on_connection_failed():
	get_tree().network_peer = null
	emit_signal("connection_failed")

func _on_server_disconnected():
	get_tree().network_peer = null
	players.clear()
	emit_signal("server_disconnected")

remote func _register_player(peer_id, player_info):
	players[peer_id] = player_info
	emit_signal("player_list_changed")

# In-game player spawning
var player_scene = preload("res://data/scenes/character.tscn")
var remote_player_scene = preload("res://data/scenes/remote_player.tscn")
var spawned_players = {}  # { peer_id: node }

func spawn_players_in_game(main_scene):
	if not is_multiplayer():
		# Single player - spawn local only
		return
	
	# Spawn local player
	_spawn_local_player(main_scene)
	
	# If server, spawn remote players that are already connected
	if is_server():
		for peer_id in players:
			if peer_id != local_player_id:
				_rpc_spawn_player(peer_id)

func _spawn_local_player(main_scene):
	var existing = main_scene.get_node_or_null("character")
	if existing:
		existing.name = "player_" + str(local_player_id)
		existing.set_network_master(local_player_id)
		spawned_players[local_player_id] = existing

master func _request_spawn(peer_id):
	if not is_server():
		return
	_rpc_spawn_player(peer_id)

func _rpc_spawn_player(peer_id):
	# Only server calls this to spawn a remote player for all clients
	rpc("_spawn_remote_player", peer_id)

remotesync func _spawn_remote_player(peer_id):
	var main_scene = get_tree().get_root().get_child(0)
	if not main_scene:
		return
	if spawned_players.has(peer_id):
		return
	
	var is_local = (peer_id == local_player_id)
	var player_node
	
	if is_local:
		player_node = player_scene.instance()
	else:
		player_node = remote_player_scene.instance()
	
	player_node.name = "player_" + str(peer_id)
	player_node.set_network_master(peer_id)
	
	# Set spawn position
	var spawn_pos = _get_spawn_position(peer_id)
	player_node.global_transform.origin = spawn_pos
	
	main_scene.add_child(player_node)
	spawned_players[peer_id] = player_node
	
	# If local player, update wave_manager reference
	if is_local and main_scene.has_node("wave_manager"):
		main_scene.get_node("wave_manager").player_path = NodePath("../player_" + str(peer_id))
		main_scene.get_node("wave_manager").player = player_node

func _get_spawn_position(peer_id) -> Vector3:
	# CT spawn area
	var ct_spawns = [
		Vector3(-20, 2, -20),
		Vector3(-15, 2, -20),
		Vector3(-20, 2, -15),
		Vector3(-15, 2, -15),
	]
	# T spawn area
	var t_spawns = [
		Vector3(20, 2, 20),
		Vector3(15, 2, 20),
		Vector3(20, 2, 15),
		Vector3(15, 2, 15),
	]
	var idx = peer_id % 4
	if is_server() and peer_id == local_player_id:
		return ct_spawns[idx]
	return t_spawns[idx]

func _despawn_player(peer_id):
	if spawned_players.has(peer_id):
		var node = spawned_players[peer_id]
		if is_instance_valid(node):
			node.queue_free()
		spawned_players.erase(peer_id)

func get_player_node(peer_id):
	if spawned_players.has(peer_id):
		return spawned_players[peer_id]
	return null

# Player state broadcast for position sync
func broadcast_player_state(pos, rot_y, vel):
	if not is_multiplayer():
		return
	for peer_id in players:
		if peer_id != local_player_id:
			rpc_id(peer_id, "_receive_player_state", local_player_id, pos, rot_y, vel)

remote func _receive_player_state(peer_id, pos, rot_y, vel):
	var main = get_tree().get_root().get_child(0)
	if main:
		var rp = main.get_node_or_null("player_" + str(peer_id))
		if rp and rp.has_method("update_state"):
			rp.update_state(pos, rot_y, vel)
