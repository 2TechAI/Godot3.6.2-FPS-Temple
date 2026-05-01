extends Area

export var heal_amount = 25
export var item_type = "medkit"  # medkit, bandage, syringe
var custom_heal_amount = false

func _ready():
	_set_appearance()

func _set_appearance():
	var mesh = $mesh
	var mat = mesh.get_surface_material(0)
	if not mat:
		return
	mat = mat.duplicate()
	mesh.set_surface_material(0, mat)
	if item_type == "medkit":
		if not custom_heal_amount:
			heal_amount = 50
		mat.albedo_color = Color(0.8, 0.1, 0.1)
	elif item_type == "bandage":
		if not custom_heal_amount:
			heal_amount = 25
		mat.albedo_color = Color(0.9, 0.9, 0.9)
	elif item_type == "syringe":
		if not custom_heal_amount:
			heal_amount = 35
		mat.albedo_color = Color(0.1, 0.8, 0.3)

func _physics_process(delta):
	# Rotate item for visibility
	rotation.y += delta * 2.0
	# Bob up and down
	$mesh.translation.y = 0.5 + sin(OS.get_ticks_msec() / 500.0) * 0.1
	
	# Distance-based pickup check - bypasses Godot 3 Area collision quirks entirely
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("heal"):
			# Use horizontal distance only, allow some height tolerance
			var diff = p.global_transform.origin - global_transform.origin
			var h_dist = Vector2(diff.x, diff.z).length()
			var v_dist = abs(diff.y)
			if h_dist < 1.2 and v_dist < 2.0:
				var healed = p.heal(heal_amount)
				if healed:
					queue_free()
					return
