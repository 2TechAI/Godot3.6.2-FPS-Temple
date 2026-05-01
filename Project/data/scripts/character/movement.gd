extends KinematicBody

func _ready():
	input["left"] = 0
	input["right"] = 0
	input["forward"] = 0
	input["back"] = 0
	input["jump"] = 0
	input["crouch"] = 0
	input["sprint"] = 0

# All speed variables
var n_speed : float = 4.0 # Normal
var s_speed : float = 8.0 # Sprint
var w_speed : float = 4.0 # Walking
var c_speed : float = 10.0 # Crouch

# Physics variables
var gravity : float = 25.0 # Gravity force
var jump_height : float = 10.0 # Jump height
var friction : float = 8.0 # friction

# All vectors
var velocity : = Vector3() # Velocity vector
var direction : = Vector3() # Direction Vector

# All character inputs
var input : Dictionary = {}

# Health system
var max_health : int = 200
var health : int = 200
var is_critical : bool = false
var is_dead : bool = false

# Network sync
var sync_timer = 0.0
var sync_interval = 0.05

func _physics_process(_delta) -> void:
	if is_dead:
		return
	
	# Function for movement
	_movement(_delta)
	
	# Function for crouch
	_crouch(_delta)
	
	# Function for jump
	_jump(_delta)
	
	# Function for sprint
	_sprint(_delta)
	
	# Apply gravity every frame
	velocity.y -= gravity * _delta
	
	# Use move_and_slide for proper physics
	velocity = move_and_slide(velocity, Vector3.UP, true, 4, deg2rad(45))
	
	# Network sync
	_sync_position(_delta)

func _movement(_delta) -> void:
	# Inputs
	input["left"]   = int(Input.is_action_pressed("KEY_A"))
	input["right"]  = int(Input.is_action_pressed("KEY_D"))
	input["forward"] = int(Input.is_action_pressed("KEY_W"))
	input["back"]   = int(Input.is_action_pressed("KEY_S"))
	
	# Get head basis for movement direction
	var head = get_node_or_null("head")
	if not head:
		return
	var basis = head.global_transform.basis
	
	# Build direction vector
	direction = Vector3()
	direction += (-input["left"] + input["right"]) * basis.x
	direction += (-input["forward"] + input["back"]) * basis.z
	direction.y = 0
	direction = direction.normalized()
	
	# Apply friction when on floor
	if is_on_floor():
		if direction.length() < 0.01:
			velocity.x = lerp(velocity.x, 0.0, friction * _delta)
			velocity.z = lerp(velocity.z, 0.0, friction * _delta)
		else:
			velocity.x = lerp(velocity.x, direction.x * n_speed, friction * _delta)
			velocity.z = lerp(velocity.z, direction.z * n_speed, friction * _delta)
	else:
		# Air control - limited movement influence
		velocity.x += direction.x * n_speed * 2.0 * _delta
		velocity.z += direction.z * n_speed * 2.0 * _delta
		# Cap air speed
		var flat_vel = Vector2(velocity.x, velocity.z)
		if flat_vel.length() > s_speed:
			flat_vel = flat_vel.normalized() * s_speed
			velocity.x = flat_vel.x
			velocity.z = flat_vel.y

func _crouch(_delta) -> void:
	# Inputs
	input["crouch"] = int(Input.is_action_pressed("KEY_CTRL"))
	
	# Get the character's head node
	var head = get_node_or_null("head")
	if not head:
		return
	
	# If the head node is not touching the ceiling
	if not head.is_colliding():
		# Takes the character collision node
		var collision = get_node_or_null("collision")
		if not collision:
			return
		
		# Get the character's collision shape
		var shape = collision.shape.height
		
		# Changes the shape of the character's collision
		shape = lerp(shape, 2.0 - (input["crouch"] * 1.5), c_speed * _delta)
		
		# Apply the new character collision shape
		collision.shape.height = shape

func _jump(_delta) -> void:
	# Inputs
	input["jump"] = int(Input.is_action_pressed("KEY_SPACE"))
	
	# Makes the player jump if he is on the ground
	if input["jump"] and is_on_floor():
		velocity.y = jump_height

func _sprint(_delta) -> void:
	# Inputs
	input["sprint"] = int(Input.is_action_pressed("KEY_SHIFT"))
	
	# Make the character sprint
	if not input["crouch"]: # If you are not crouching
		# switch between sprint and walking
		var toggle_speed : float = w_speed + ((s_speed - w_speed) * input["sprint"])
		
		# Create a character speed interpolation
		n_speed = lerp(n_speed, toggle_speed, 5.0 * _delta)
	else:
		# Create a character speed interpolation
		n_speed = lerp(n_speed, w_speed, 5.0 * _delta)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		health = 0
		_die()
	_update_critical_status()

func heal(amount: int) -> bool:
	if is_dead or health >= max_health:
		return false
	health += amount
	if health > max_health:
		health = max_health
	_update_critical_status()
	return true

func _update_critical_status() -> void:
	is_critical = health < 20 and health > 0
	if has_node("hud"):
		var hud = $"hud"
		if hud.has_node("critical_overlay"):
			hud.get_node("critical_overlay").visible = is_critical

func _die() -> void:
	is_dead = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var t = Timer.new()
	t.wait_time = 0.5
	t.one_shot = true
	t.connect("timeout", self, "_respawn_player")
	add_child(t)
	t.start()

func _respawn_player():
	var main = get_tree().get_root().get_child(0)
	if main.has_node("wave_manager"):
		var wm = main.get_node("wave_manager")
		wm._respawn_player_at_current_wave(self)
	else:
		get_tree().reload_current_scene()

func reset_player():
	is_dead = false
	health = max_health
	is_critical = false
	velocity = Vector3()
	global_transform.origin = Vector3(0, 2, 0)
	if has_node("hud"):
		var hud = $"hud"
		if hud.has_node("critical_overlay"):
			hud.get_node("critical_overlay").visible = false
	_update_critical_status()

func _sync_position(delta):
	if not get_tree().network_peer:
		return
	if get_tree().get_network_unique_id() == 0:
		return
	
	sync_timer += delta
	if sync_timer >= sync_interval:
		sync_timer = 0.0
		var head = get_node_or_null("head")
		var rot_y = rotation.y
		if head:
			rot_y = head.rotation.y
		var nm = get_node_or_null("/root/NetworkManager")
		if nm:
			nm.broadcast_player_state(global_transform.origin, rot_y, velocity)
