extends KinematicBody

signal died

export var health = 100
export var damage = 10
export var speed = 5.5
export var attack_range = 2.5
export var shoot_range = 20.0
export var fire_rate = 1.5

var strafe_timer = 0.0
var strafe_direction = 1
var strafe_change_interval = 1.5

var player = null
var velocity = Vector3()
var gravity = 30.0
var is_dead = false

var shoot_timer = 0.0
var attack_timer = 0.0
var shoot_cooldown = 0.0
var footstep_timer = 0.0
var footstep_interval = 0.5

func _ready():
	add_to_group("enemy")
	add_to_group("prop")
	
	# Body colors - military outfit (guard for compatibility with custom models)
	if has_node("body/mesh"):
		$body/mesh.get_surface_material(0).albedo_color = Color(0.15, 0.25, 0.15)
	if has_node("body/left_arm"):
		$body/left_arm.get_surface_material(0).albedo_color = Color(0.25, 0.2, 0.15)
	if has_node("body/right_arm"):
		$body/right_arm.get_surface_material(0).albedo_color = Color(0.25, 0.2, 0.15)
	if has_node("body/left_leg"):
		$body/left_leg.get_surface_material(0).albedo_color = Color(0.2, 0.18, 0.12)
	if has_node("body/right_leg"):
		$body/right_leg.get_surface_material(0).albedo_color = Color(0.2, 0.18, 0.12)
	if has_node("body/backpack"):
		$body/backpack.get_surface_material(0).albedo_color = Color(0.1, 0.1, 0.12)
	# Head colors - skin + helmet
	if has_node("head/mesh"):
		$head/mesh.get_surface_material(0).albedo_color = Color(0.85, 0.7, 0.55)
	if has_node("head/eye"):
		$head/eye.get_surface_material(0).albedo_color = Color(0.9, 0.1, 0.1)
	if has_node("head/pupil"):
		$head/pupil.get_surface_material(0).albedo_color = Color(0.1, 0.1, 0.1)
	if has_node("head/helmet"):
		$head/helmet.get_surface_material(0).albedo_color = Color(0.6, 0.5, 0.35)
	
	var shoot_stream = preload("res://data/audios/weapons/glock_17/fire.ogg")
	$shoot_audio.stream = shoot_stream
	$shoot_audio.unit_db = 0.0
	$shoot_audio.max_db = 3.0
	
	var attack_stream = preload("res://data/audios/weapons/glock_17/fire.ogg")
	$attack_audio.stream = attack_stream
	$attack_audio.unit_db = 0.0
	$attack_audio.max_db = 3.0
	
	var hit_stream = preload("res://data/audios/barrel/impact.ogg")
	$hit_audio.stream = hit_stream
	
	var death_stream = preload("res://data/audios/character/fall/die.ogg")
	$death_audio.stream = death_stream
	
	# Load weapon model only
	_load_player_weapon_model()

func _load_player_weapon_model():
	# Load weapon model
	var weapon_scene = load("res://data/models/weapons/glock_17/scene.gltf")
	if weapon_scene and weapon_scene is PackedScene:
		var weapon_model = weapon_scene.instance()
		if weapon_model:
			weapon_model.name = "player_weapon"
			weapon_model.transform = Transform(
				Vector3(0.01, 0, 0),
				Vector3(0, 0, 0.01),
				Vector3(0, -0.01, 0),
				Vector3(-0.05, -0.05, 0.1)
			)
			$weapon.add_child(weapon_model)
			if $weapon.has_node("mesh"):
				for child in $weapon/mesh.get_children():
					if child.name != "muzzle" and child.name != "muzzle_flash":
						child.visible = false

func _physics_process(delta):
	if is_dead:
		return
	
	# Update target to nearest living player
	if not player or player.is_dead:
		player = _find_nearest_player()
	if not player:
		return
	
	var to_player = player.global_transform.origin - global_transform.origin
	var distance = to_player.length()
	
	# Look at player (only Y rotation)
	look_at(Vector3(player.global_transform.origin.x, global_transform.origin.y, player.global_transform.origin.z), Vector3.UP)
	
	var is_moving = false
	if distance > attack_range:
		var direction = to_player.normalized()
		direction.y = 0
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		is_moving = true
	else:
		velocity.x = 0
		velocity.z = 0
		_attack_player(delta)
	
	# Apply gravity
	velocity.y -= gravity * delta
	
	velocity = move_and_slide(velocity, Vector3.UP)
	
	# Footstep sound
	if is_moving and is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0:
			footstep_timer = footstep_interval
			_play_footstep()
	
	# Shooting logic
	if distance <= shoot_range and distance > attack_range:
		_shoot_at_player(delta)

func _find_nearest_player():
	var players = get_tree().get_nodes_in_group("player")
	var nearest = null
	var nearest_dist = 999999.0
	for p in players:
		if is_instance_valid(p) and not p.is_dead:
			var d = p.global_transform.origin.distance_to(global_transform.origin)
			if d < nearest_dist:
				nearest_dist = d
				nearest = p
	return nearest

func _play_footstep():
	var idx = randi() % 7
	var path = "res://data/audios/character/footsteep/concrete/" + str(idx) + ".ogg"
	var stream = load(path)
	if stream:
		var player3d = AudioStreamPlayer3D.new()
		player3d.stream = stream
		player3d.unit_db = -10.0
		add_child(player3d)
		player3d.play()
		player3d.connect("finished", player3d, "queue_free")

func _attack_player(delta):
	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = fire_rate
		if player and player.has_method("take_damage"):
			# Melee damage: 10-20 based on distance
			var melee_dmg = int(rand_range(10, 21))
			player.take_damage(melee_dmg)
		$attack_audio.play()

func _shoot_at_player(delta):
	shoot_cooldown -= delta
	if shoot_cooldown <= 0:
		shoot_cooldown = fire_rate
		# Raycast to check if we can hit player
		var space_state = get_world().direct_space_state
		var from
		if has_node("weapon/muzzle"):
			from = $weapon/muzzle.global_transform.origin
		else:
			from = $weapon.global_transform.origin
		var to = player.global_transform.origin + Vector3(0, 1.5, 0)
		var result = space_state.intersect_ray(from, to, [self])
		if result and result.collider == player:
			if player.has_method("take_damage"):
				player.take_damage(int(damage * 0.6))
				$shoot_audio.play()
				# Muzzle flash
				if has_node("weapon/muzzle_flash"):
					$weapon/muzzle_flash.visible = true
					var t = Timer.new()
					t.wait_time = 0.1
					t.one_shot = true
					t.connect("timeout", self, "_hide_muzzle_flash", [t])
					add_child(t)
					t.start()

func _hide_muzzle_flash(timer):
	if has_node("weapon/muzzle_flash"):
		$weapon/muzzle_flash.visible = false
	if timer:
		timer.queue_free()

func _damage(dmg):
	if is_dead:
		return
	health -= dmg
	$hit_audio.play()
	# Flash red on all body parts
	_flash_red()
	var t = Timer.new()
	t.wait_time = 0.1
	t.one_shot = true
	t.connect("timeout", self, "_reset_color", [t])
	add_child(t)
	t.start()
	
	if health <= 0:
		_die()

func _flash_red():
	if has_node("body/mesh"):
		$body/mesh.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("body/vest"):
		$body/vest.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("body/belt"):
		$body/belt.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("body/left_arm"):
		$body/left_arm.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("body/right_arm"):
		$body/right_arm.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("body/left_leg"):
		$body/left_leg.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("body/right_leg"):
		$body/right_leg.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("body/left_boot"):
		$body/left_boot.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("body/right_boot"):
		$body/right_boot.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("body/backpack"):
		$body/backpack.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("head/mesh"):
		$head/mesh.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)
	if has_node("head/helmet"):
		$head/helmet.get_surface_material(0).albedo_color = Color(1, 0.3, 0.3)

func _reset_color(timer):
	if has_node("body/mesh"):
		$body/mesh.get_surface_material(0).albedo_color = Color(0.18, 0.22, 0.28)
	if has_node("body/vest"):
		$body/vest.get_surface_material(0).albedo_color = Color(0.15, 0.18, 0.24)
	if has_node("body/belt"):
		$body/belt.get_surface_material(0).albedo_color = Color(0.1, 0.12, 0.18)
	if has_node("body/left_arm"):
		$body/left_arm.get_surface_material(0).albedo_color = Color(0.18, 0.22, 0.28)
	if has_node("body/right_arm"):
		$body/right_arm.get_surface_material(0).albedo_color = Color(0.18, 0.22, 0.28)
	if has_node("body/left_leg"):
		$body/left_leg.get_surface_material(0).albedo_color = Color(0.18, 0.22, 0.28)
	if has_node("body/right_leg"):
		$body/right_leg.get_surface_material(0).albedo_color = Color(0.18, 0.22, 0.28)
	if has_node("body/left_boot"):
		$body/left_boot.get_surface_material(0).albedo_color = Color(0.12, 0.15, 0.2)
	if has_node("body/right_boot"):
		$body/right_boot.get_surface_material(0).albedo_color = Color(0.12, 0.15, 0.2)
	if has_node("body/backpack"):
		$body/backpack.get_surface_material(0).albedo_color = Color(0.2, 0.24, 0.3)
	if has_node("head/mesh"):
		$head/mesh.get_surface_material(0).albedo_color = Color(0.82, 0.68, 0.52)
	if has_node("head/helmet"):
		$head/helmet.get_surface_material(0).albedo_color = Color(0.2, 0.24, 0.3)
	if timer:
		timer.queue_free()

func _die():
	is_dead = true
	$collision.disabled = true
	if has_node("body"):
		$body.visible = false
	if has_node("head"):
		$head.visible = false
	if has_node("weapon"):
		$weapon.visible = false
	$death_particles.emitting = true
	$death_audio.play()
	emit_signal("died")
	
	# Drop a small heal item on death
	_drop_medkit()
	
	var t = Timer.new()
	t.wait_time = 2.0
	t.one_shot = true
	t.connect("timeout", self, "queue_free")
	add_child(t)
	t.start()

func _drop_medkit():
	var medkit_scene = preload("res://data/scenes/medkit.tscn")
	var drop = medkit_scene.instance()
	drop.item_type = "bandage"
	drop.custom_heal_amount = true
	drop.heal_amount = 25
	# Add to main scene first, then set position
	var main = get_tree().get_root().get_child(0)
	if main:
		main.add_child(drop)
		drop.global_transform.origin = global_transform.origin + Vector3(0, 0.3, 0)
