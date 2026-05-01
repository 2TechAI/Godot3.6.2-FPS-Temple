class weapon:
	var owner : Node;
	var name : String;
	var firerate : float;
	var bullets : int;
	var ammo : int;
	var max_bullets : int;
	var damage : int;
	var reload_speed : float;
	var anim = null;
	var animc = "";
	var mesh = null;
	var has_anim = false;
	
	func _init(owner, name, firerate, bullets, ammo, max_bullets, damage, reload_speed) -> void:
		self.owner = owner;
		self.name = name;
		self.firerate = firerate;
		self.bullets = bullets;
		self.ammo = ammo;
		self.max_bullets = max_bullets;
		self.damage = damage;
		self.reload_speed = reload_speed;
	
	func _ready() -> void:
		# Knife doesn't have animation node, so check first
		if owner.has_node("{}/mesh/anim".format([name], "{}")):
			anim = owner.get_node("{}/mesh/anim".format([name], "{}"));
			has_anim = true;
		
		if owner.has_node("{}".format([name], "{}")):
			mesh = owner.get_node("{}".format([name], "{}"));
	
	# Get animation node (lazy, only when needed)
	func get_anim():
		if anim == null and owner.has_node("{}/mesh/anim".format([name], "{}")):
			anim = owner.get_node("{}/mesh/anim".format([name], "{}"));
			has_anim = true;
		return anim
	
	# Get current animation
	func get_animc():
		var a = get_anim()
		if a:
			animc = a.current_animation;
		return animc;
	
	# Get mesh node (lazy)
	func get_mesh():
		if mesh == null and owner.has_node("{}".format([name], "{}")):
			mesh = owner.get_node("{}".format([name], "{}"));
		return mesh
	
	func _draw() -> void:
		var m = get_mesh()
		var a = get_anim()
		if m and not m.visible:
			m.visible = true
			if a:
				a.play("Draw")
	
	func _hide() -> void:
		var m = get_mesh()
		var a = get_anim()
		if m and m.visible:
			m.visible = false
			if a:
				a.play("Hide")
	
	func _sprint(sprint, _delta) -> void:
		var m = get_mesh()
		if not m:
			return
		if sprint and owner.character.direction:
			m.rotation.x = lerp(m.rotation.x, -deg2rad(40), 5 * _delta);
		else:
			m.rotation.x = lerp(m.rotation.x, 0, 5 * _delta);
	
	func _shoot(_delta) -> void:
		# Knife melee attack - no ammo needed
		if name == "knife":
			var a = get_anim()
			var ac = get_animc()
			if ac != "Shoot" and ac != "Draw" and ac != "Hide" and a:
				# Play slash animation
				a.play("Shoot", 0, firerate);
				
				# Melee raycast from camera
				var space_state = owner.get_world().direct_space_state
				var from = owner.camera.global_transform.origin
				var to = from + owner.camera.global_transform.basis.z * -2.5
				var result = space_state.intersect_ray(from, to, [owner.character])
				
				if result:
					var local_damage = int(rand_range(damage * 0.8, damage))
					if result.collider.is_in_group("prop"):
						if result.collider.has_method("_damage"):
							result.collider._damage(local_damage)
						# Blood/spark effect
						var spark = preload("res://data/scenes/spark.tscn").instance()
						result.collider.add_child(spark)
						spark.global_transform.origin = result.position
						spark.emitting = true
			return
		
		# Get audio node
		var audio = owner.get_node("{}/audio".format([name], "{}"));
		
		# Get effects node
		var effect = owner.get_node("{}/effect".format([name], "{}"));
		
		if bullets > 0:
			# Play shoot animation if not reloading
			var ac = get_animc()
			var a = get_anim()
			if ac != "Shoot" and ac != "Reload" and ac != "Draw" and ac != "Hide":
				bullets -= 1;
				
				# recoil
				owner.camera.rotation.x = lerp(owner.camera.rotation.x, rand_range(1, 2), _delta);
				owner.camera.rotation.y = lerp(owner.camera.rotation.y, rand_range(-1, 1), _delta);
				
				# Shake the camera
				owner.camera.shake_force = 0.002;
				owner.camera.shake_time = 0.2;
				
				# Change light energy
				effect.get_node("shoot").light_energy = 2;
				
				# Emitt fire particles
				effect.get_node("fire").emitting = true;
				
				# Emitt smoke particles
				effect.get_node("smoke").emitting = true;
				
				# Play shoot sound
				audio.get_node("shoot").pitch_scale = rand_range(0.9, 1.1);
				audio.get_node("shoot").play();
				
				# Play shoot animation using firate speed
				if a:
					a.play("Shoot", 0, firerate);
				
				# Get barrel node
				var barrel = owner.get_node("{}/barrel".format([name], "{}"));
				
				# Get main scene
				var main = owner.get_tree().get_root().get_child(0);
				
				# Create a instance of trail scene
				var trail = preload("res://data/scenes/trail.tscn").instance();
				
				# Change trail position to out of barrel position
				trail.translation = barrel.global_transform.origin;
				
				# Change trail rotation to camera rotation
				trail.rotation = owner.camera.global_transform.basis.get_euler();
				
				# Add the trail to main scene
				main.add_child(trail);
				
				# Get raycast weapon range
				var ray = owner.get_node("{}/ray".format([name], "{}"));
				
				# Check raycast is colliding
				if ray.is_colliding():
					var local_damage = int(rand_range(damage/1.5, damage))
					
					# Do damage
					if ray.get_collider() is RigidBody:
						ray.get_collider().apply_central_impulse(-ray.get_collision_normal() * (local_damage * 0.3));
					
					if ray.get_collider().is_in_group("prop"):
						if ray.get_collider().is_in_group("metal"):
							var spark = preload("res://data/scenes/spark.tscn").instance();
							
							# Add spark scene in collider
							ray.get_collider().add_child(spark);
							
							# Change spark position to collider position
							spark.global_transform.origin = ray.get_collision_point();
							
							spark.emitting = true;
						
						if ray.get_collider().has_method("_damage"):
							ray.get_collider()._damage(local_damage);
					
					# Create a instance of decal scene
					var decal = preload("res://data/scenes/decal.tscn").instance();
					
					# Add decal scene in collider
					ray.get_collider().add_child(decal);
					
					# Change decal position to collider position
					decal.global_transform.origin = ray.get_collision_point();
					
					# decal spins to collider normal
					decal.look_at(ray.get_collision_point() + ray.get_collision_normal(), Vector3(1, 1, 0));
		else:
			# Play out sound
			if not audio.get_node("out").playing:
				audio.get_node("out").pitch_scale = rand_range(0.9, 1.1);
				audio.get_node("out").play();

	func _reload() -> void:
		# Knife doesn't need reloading
		if name == "knife":
			return
		
		if bullets < max_bullets and ammo > 0:
			var ac = get_animc()
			var a = get_anim()
			if ac != "Reload" and ac != "Shoot" and ac != "Draw" and ac != "Hide" and a:
				# Play reload animation
				a.play("Reload", 0.2, reload_speed);
				
				for b in ammo:
					bullets += 1
					ammo -= 1;
					
					if bullets >= max_bullets:
						break;

	func _inspect(_delta) -> void:
		var ac = get_animc()
		var a = get_anim()
		if a and a.has_animation("Inspect") and ac != "Reload" and ac != "Shoot" and ac != "Draw" and ac != "Hide" and ac != "Inspect":
			a.play("Inspect", 0.2, 1.0)

	func _zoom(input, _delta) -> void:
		# Knife can't zoom
		if name == "knife":
			return
		
		var lerp_speed : int = 30;
		var camera = owner.camera;
		var m = get_mesh()
		var ac = get_animc()
		
		if not m:
			return
		
		if input and ac != "Reload" and ac != "Hide" and ac != "Draw" and ac != "Inspect":
			camera.fov = lerp(camera.fov, 40, lerp_speed * _delta);
			m.translation.y = lerp(m.translation.y, 0.001, lerp_speed * _delta);
			m.translation.x = lerp(m.translation.x, -0.088, lerp_speed * _delta);
		else:
			camera.fov = lerp(camera.fov, 70, lerp_speed * _delta);
			m.translation.y = lerp(m.translation.y, 0, lerp_speed * _delta);
			m.translation.x = lerp(m.translation.x, 0, lerp_speed * _delta);

	func _update(_delta) -> void:
		var ac = get_animc()
		if ac != "Shoot":
			if owner.arsenal.values()[owner.current] == self:
				owner.camera.rotation.x = lerp(owner.camera.rotation.x, 0, 10 * _delta);
				owner.camera.rotation.y = lerp(owner.camera.rotation.y, 0, 10 * _delta);
		
		# Get current animation
		var a = get_anim()
		if a:
			animc = a.current_animation;
		
		# Knife has no effect node
		if name == "knife":
			# Remove recoil
			var m = get_mesh()
			if m:
				m.rotation.x = lerp(m.rotation.x, 0, 5 * _delta);
			return
		
		# Get effect node
		var effect = owner.get_node("{}/effect".format([name], "{}"));
		
		# Change light energy
		effect.get_node("shoot").light_energy = lerp(effect.get_node("shoot").light_energy, 0, 5 * _delta);
		
		# Remove recoil
		var m = get_mesh()
		if m:
			m.rotation.x = lerp(m.rotation.x, 0, 5 * _delta);
