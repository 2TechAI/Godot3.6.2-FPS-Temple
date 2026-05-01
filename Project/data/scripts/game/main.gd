extends Node

func _ready():
	# Initialize multiplayer if active
	if get_tree().network_peer:
		_initialize_multiplayer()
	
	# Add in-game pause menu
	var pause_menu = preload("res://data/scenes/pause_menu.tscn").instance()
	add_child(pause_menu)

func _initialize_multiplayer():
	var nm = get_node("/root/NetworkManager")
	if not nm:
		return
	
	# Rename local character to include peer id
	var local_id = get_tree().get_network_unique_id()
	var character = get_node_or_null("character")
	if character:
		character.name = "player_" + str(local_id)
		character.set_network_master(local_id)
		nm.spawned_players[local_id] = character
	
	# If server, spawn remote players for existing clients
	if get_tree().is_network_server():
		for peer_id in nm.players:
			if peer_id != local_id:
				_spawn_remote_player(peer_id)
	else:
		# Client: request spawn from server
		nm.rpc_id(1, "_request_spawn", local_id)
	
	# Connect to player connection signals for late joiners
	nm.connect("player_connected", self, "_on_remote_player_connected")
	nm.connect("player_disconnected", self, "_on_remote_player_disconnected")

func _on_remote_player_connected(peer_id):
	if get_tree().is_network_server():
		# Server spawns remote player for all
		_spawn_remote_player(peer_id)

func _on_remote_player_disconnected(peer_id):
	var node = get_node_or_null("player_" + str(peer_id))
	if node:
		node.queue_free()

func _spawn_remote_player(peer_id):
	if get_node_or_null("player_" + str(peer_id)):
		return
	
	var remote_scene = preload("res://data/scenes/remote_player.tscn")
	var node = remote_scene.instance()
	node.name = "player_" + str(peer_id)
	node.set_network_master(peer_id)
	
	# Set initial position
	var spawn_pos = _get_spawn_position(peer_id)
	node.global_transform.origin = spawn_pos
	
	add_child(node)
	
	var nm = get_node("/root/NetworkManager")
	if nm:
		nm.spawned_players[peer_id] = node
	
	# Set player name
	if nm and nm.players.has(peer_id):
		node.set_player_name(nm.players[peer_id].name)

func _get_spawn_position(peer_id) -> Vector3:
	var ct_spawns = [
		Vector3(-20, 2, -20),
		Vector3(-15, 2, -20),
		Vector3(-20, 2, -15),
		Vector3(-15, 2, -15),
	]
	var t_spawns = [
		Vector3(20, 2, 20),
		Vector3(15, 2, 20),
		Vector3(20, 2, 15),
		Vector3(15, 2, 15),
	]
	var idx = peer_id % 4
	if get_tree().is_network_server():
		return ct_spawns[idx]
	return t_spawns[idx]
