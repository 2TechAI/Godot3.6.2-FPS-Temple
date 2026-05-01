extends KinematicBody

# Remote player - controlled by network sync
var target_position = Vector3()
var target_rotation = Vector3()
var sync_velocity = Vector3()

puppet func update_state(pos, rot_y, vel):
	target_position = pos
	target_rotation.y = rot_y
	sync_velocity = vel

func _physics_process(delta):
	# Smooth interpolation to target state
	global_transform.origin = global_transform.origin.linear_interpolate(target_position, 10 * delta)
	rotation.y = lerp_angle(rotation.y, target_rotation.y, 10 * delta)
	
	# Simple gravity
	if not is_on_floor():
		sync_velocity.y -= 30 * delta
	else:
		sync_velocity.y = 0
	
	move_and_slide(sync_velocity, Vector3.UP)

func set_player_name(pname):
	if has_node("head/name_label"):
		$head/name_label.text = pname

func take_damage(amount):
	# Remote players take damage via RPC from server
	pass
