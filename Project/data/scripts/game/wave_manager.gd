extends Node

export(PackedScene) var robot_scene
export(NodePath) var player_path
export(NodePath) var spawn_area_path

var player
var spawn_area

var current_wave = 0
var robots_alive = 0
var robots_to_spawn = 0
var wave_active = false
var rest_active = false
var free_mode = false

var rest_timer = 0.0
var rest_duration = 30.0
var spawn_timer = 0.0
var spawn_interval = 1.5

var base_robot_count = 3
var max_robot_count = 25
var robot_health_multiplier = 1.0
var robot_damage_multiplier = 1.0

var max_health_reward = 80
var max_ammo_reward = 120

var kill_count = 0
var medkit_scene = preload("res://data/scenes/medkit.tscn")
var medkit_spawn_positions = [
	Vector3(0, 0.5, 0),
	Vector3(15, 0.5, 15),
	Vector3(-15, 0.5, -15),
	Vector3(20, 0.5, -20),
	Vector3(-20, 0.5, 20)
]

const MAX_WAVES = 15

func _ready():
	player = get_node(player_path)
	spawn_area = get_node(spawn_area_path)
	_setup_wave_ui_fonts()
	
	# In multiplayer, only server spawns enemies
	if get_tree().network_peer and not get_tree().is_network_server():
		return
	
	_start_next_wave()

func _process(delta):
	if free_mode:
		return
	
	# Only server runs wave logic in multiplayer
	if get_tree().network_peer and not get_tree().is_network_server():
		return
	
	if rest_active:
		rest_timer -= delta
		_update_rest_ui()
		if rest_timer <= 0:
			_end_rest()
	elif wave_active:
		if robots_to_spawn > 0:
			spawn_timer -= delta
			if spawn_timer <= 0:
				_spawn_robot()
				spawn_timer = max(0.5, spawn_interval - (current_wave * 0.05))
				robots_to_spawn -= 1
		else:
			var living = _count_living_enemies()
			if living == 0 and robots_alive <= 0:
				_start_rest()

func _count_living_enemies() -> int:
	var count = 0
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and not e.is_dead:
			count += 1
	return count

func _start_next_wave():
	if current_wave >= MAX_WAVES:
		_enter_free_mode()
		return
	current_wave += 1
	wave_active = true
	rest_active = false
	
	var robot_count = min(base_robot_count + (current_wave * 2), max_robot_count)
	robots_to_spawn = robot_count
	robots_alive = 0
	
	robot_health_multiplier = min(1.0 + (current_wave * 0.15), 4.0)
	robot_damage_multiplier = min(1.0 + (current_wave * 0.1), 3.0)
	
	spawn_timer = 0.0
	
	_update_wave_ui()
	_show_wave_start_message()

func _start_rest():
	wave_active = false
	rest_active = true
	rest_timer = rest_duration
	
	_give_wave_rewards()
	_update_rest_ui()
	_show_rest_message()

func _end_rest():
	rest_active = false
	_start_next_wave()

func _enter_free_mode():
	free_mode = true
	wave_active = false
	rest_active = false
	_show_free_mode_message()

func _spawn_robot():
	if not robot_scene:
		return
	
	# Only server spawns in multiplayer
	if get_tree().network_peer and not get_tree().is_network_server():
		return
	
	var robot = robot_scene.instance()
	
	var spawn_pos = _get_random_spawn_point()
	robot.translation = spawn_pos
	
	robot.health = int(robot.health * robot_health_multiplier)
	robot.damage = int(robot.damage * robot_damage_multiplier)
	
	# Find nearest player as target (supports multiplayer)
	robot.player = _get_nearest_player(spawn_pos)
	
	robot.connect("died", self, "_on_robot_died")
	
	get_parent().add_child(robot)
	robots_alive += 1
	
	# Let robot fall to ground naturally via move_and_slide
	
	# Sync to clients in multiplayer
	if get_tree().network_peer and get_tree().is_network_server():
		robot.set_network_master(1)
		rpc("_sync_spawn_robot", spawn_pos, robot.health, robot.damage)

remote func _sync_spawn_robot(spawn_pos, health, dmg):
	# Clients receive this but don't spawn (server handles it)
	pass

func _get_nearest_player(from_pos: Vector3) -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return player
	
	var nearest = null
	var nearest_dist = 999999.0
	for p in players:
		if is_instance_valid(p) and not p.is_dead:
			var d = p.global_transform.origin.distance_to(from_pos)
			if d < nearest_dist:
				nearest_dist = d
				nearest = p
	
	if nearest:
		return nearest
	return player

func _respawn_player_at_current_wave(character):
	# Clear all existing enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	
	robots_alive = 0
	robots_to_spawn = 0
	
	# Reset player state
	if is_instance_valid(character):
		character.reset_player()
	
	# Restart current wave (not increment)
	wave_active = true
	rest_active = false
	free_mode = false
	
	var robot_count = min(base_robot_count + (current_wave * 2), max_robot_count)
	robots_to_spawn = robot_count
	
	robot_health_multiplier = min(1.0 + (current_wave * 0.15), 4.0)
	robot_damage_multiplier = min(1.0 + (current_wave * 0.1), 3.0)
	
	spawn_timer = 0.0
	
	_update_wave_ui()
	_show_wave_start_message()

func _get_random_spawn_point() -> Vector3:
	if spawn_area and spawn_area is CollisionShape:
		var shape = spawn_area.shape
		if shape is BoxShape:
			var ext = shape.extents
			var area_origin = spawn_area.global_transform.origin
			return area_origin + Vector3(
				rand_range(-ext.x, ext.x),
				0,
				rand_range(-ext.z, ext.z)
			)
	return Vector3(rand_range(-40, 40), 0, rand_range(-40, 40))

func _give_wave_rewards():
	if not player:
		return
	
	var health_restore = min(20 + current_wave * 5, max_health_reward)
	var ammo_reward = min(30 + current_wave * 10, max_ammo_reward)
	
	if player.has_method("heal"):
		player.heal(health_restore)
	
	if player.has_node("weapons"):
		var weapons = player.get_node("weapons")
		for w in weapons.arsenal.values():
			w.ammo += ammo_reward
	
	_show_reward_message(health_restore, ammo_reward)

func _spawn_medkit_at_fixed_position():
	if not medkit_scene:
		return
	var idx = randi() % medkit_spawn_positions.size()
	var medkit = medkit_scene.instance()
	medkit.item_type = "medkit"
	medkit.global_transform.origin = medkit_spawn_positions[idx]
	get_parent().add_child(medkit)

func _on_robot_died():
	if wave_active and robots_alive > 0:
		robots_alive -= 1
	
	kill_count += 1
	if kill_count >= 10:
		kill_count = 0
		_spawn_medkit_at_fixed_position()

func _update_wave_ui():
	if has_node("/root/main/wave_ui"):
		var ui = $"/root/main/wave_ui"
		if free_mode:
			ui.get_node("wave_label").text = "自由模式"
		else:
			ui.get_node("wave_label").text = "第 " + str(current_wave) + " 波"

func _update_rest_ui():
	if has_node("/root/main/wave_ui"):
		var ui = $"/root/main/wave_ui"
		if rest_active:
			ui.get_node("rest_label").text = "休息时间: " + str(int(rest_timer)) + " 秒"
			ui.get_node("rest_label").visible = true
		else:
			ui.get_node("rest_label").visible = false

func _show_wave_start_message():
	if has_node("/root/main/wave_ui"):
		var ui = $"/root/main/wave_ui"
		ui.get_node("message_label").text = "第 " + str(current_wave) + " 波 来袭!"
		ui.get_node("message_label").visible = true
		var t = Timer.new()
		t.wait_time = 2.0
		t.one_shot = true
		t.connect("timeout", self, "_hide_message", [t])
		add_child(t)
		t.start()

func _show_rest_message():
	if has_node("/root/main/wave_ui"):
		var ui = $"/root/main/wave_ui"
		ui.get_node("message_label").text = "现在是休息时间，请及时捡起补给，并准备新一轮挑战"
		ui.get_node("message_label").visible = true

func _show_reward_message(health, ammo):
	if has_node("/root/main/wave_ui"):
		var ui = $"/root/main/wave_ui"
		ui.get_node("message_label").text = "奖励: +" + str(health) + " 生命, +" + str(ammo) + " 弹药"
		ui.get_node("message_label").visible = true
		var t = Timer.new()
		t.wait_time = 2.0
		t.one_shot = true
		t.connect("timeout", self, "_hide_message", [t])
		add_child(t)
		t.start()

func _show_free_mode_message():
	if has_node("/root/main/wave_ui"):
		var ui = $"/root/main/wave_ui"
		ui.get_node("wave_label").text = "自由模式"
		ui.get_node("message_label").text = "恭喜完成15轮挑战！自由时间开始！"
		ui.get_node("message_label").visible = true
		var t = Timer.new()
		t.wait_time = 3.0
		t.one_shot = true
		t.connect("timeout", self, "_hide_message", [t])
		add_child(t)
		t.start()

func _hide_message(timer):
	if has_node("/root/main/wave_ui"):
		var ui = $"/root/main/wave_ui"
		ui.get_node("message_label").visible = false
	if timer:
		timer.queue_free()

func _setup_wave_ui_fonts():
	var font = _load_chinese_font()
	if not font:
		return
	if has_node("/root/main/wave_ui"):
		var ui = $"/root/main/wave_ui"
		for lbl in ui.get_children():
			if lbl is Label:
				var f = font.duplicate()
				f.size = 24
				lbl.add_font_override("font", f)

func _load_chinese_font():
	var paths = [
		"C:/Windows/Fonts/simhei.ttf",
		"C:/Windows/Fonts/msyh.ttc",
		"C:/Windows/Fonts/simsun.ttc",
		"C:/Windows/Fonts/msyhbd.ttc"
	]
	var file = File.new()
	for p in paths:
		if file.file_exists(p):
			var data = DynamicFontData.new()
			data.font_path = p
			var f = DynamicFont.new()
			f.font_data = data
			return f
	return null
