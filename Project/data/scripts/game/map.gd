extends StaticBody

# Dust2-inspired geometry map with extra verticality and interesting cover
# Colors
var ground_color = Color(0.72, 0.62, 0.42)
var wall_color = Color(0.55, 0.45, 0.30)
var crate_color = Color(0.45, 0.30, 0.15)
var ramp_color = Color(0.60, 0.50, 0.35)
var pillar_color = Color(0.50, 0.40, 0.28)
var platform_color = Color(0.68, 0.58, 0.38)

func _ready():
	_generate_map()
	
	# Keep spawn area for wave manager
	var spawn_area = get_node_or_null("spawn_area")
	if spawn_area:
		spawn_area.global_transform.origin = Vector3(0, 1, 0)

func _generate_map():
	# Main ground plane
	_create_box("ground", Vector3(120, 1, 120), Vector3(0, -0.5, 0), ground_color)
	
	# ===== OUTER WALLS (taller) =====
	_create_box("wall_n", Vector3(120, 14, 2), Vector3(0, 7, -61), wall_color)
	_create_box("wall_s", Vector3(120, 14, 2), Vector3(0, 7, 61), wall_color)
	_create_box("wall_w", Vector3(2, 14, 120), Vector3(-61, 7, 0), wall_color)
	_create_box("wall_e", Vector3(2, 14, 120), Vector3(61, 7, 0), wall_color)
	
	# ===== CT SPAWN AREA (West side, raised platform) =====
	_create_box("ct_platform", Vector3(25, 2, 20), Vector3(-35, 1, -30), ground_color)
	_create_box("ct_wall1", Vector3(25, 8, 1), Vector3(-35, 5, -41), wall_color)
	_create_box("ct_wall2", Vector3(1, 8, 20), Vector3(-48, 5, -30), wall_color)
	# CT spawn crates
	_create_box("ct_crate1", Vector3(3, 2, 3), Vector3(-40, 2, -25), crate_color)
	_create_box("ct_crate2", Vector3(4, 3, 2), Vector3(-30, 2.5, -35), crate_color)
	_create_box("ct_crate3", Vector3(2, 2, 4), Vector3(-45, 2, -32), crate_color)
	
	# ===== T SPAWN AREA (East side, raised platform) =====
	_create_box("t_platform", Vector3(25, 2, 20), Vector3(35, 1, 30), ground_color)
	_create_box("t_wall1", Vector3(25, 8, 1), Vector3(35, 5, 41), wall_color)
	_create_box("t_wall2", Vector3(1, 8, 20), Vector3(48, 5, 30), wall_color)
	# T spawn crates
	_create_box("t_crate1", Vector3(3, 3, 3), Vector3(40, 2.5, 35), crate_color)
	_create_box("t_crate2", Vector3(4, 2, 3), Vector3(30, 2, 25), crate_color)
	_create_box("t_crate3", Vector3(2, 4, 2), Vector3(45, 3, 28), crate_color)
	
	# ===== CENTRAL TOWER / WATCHTOWER =====
	# Tower base pillars
	_create_box("tower_pillar_nw", Vector3(2, 8, 2), Vector3(-3, 4, -3), pillar_color)
	_create_box("tower_pillar_ne", Vector3(2, 8, 2), Vector3(3, 4, -3), pillar_color)
	_create_box("tower_pillar_sw", Vector3(2, 8, 2), Vector3(-3, 4, 3), pillar_color)
	_create_box("tower_pillar_se", Vector3(2, 8, 2), Vector3(3, 4, 3), pillar_color)
	# Tower platform
	_create_box("tower_platform", Vector3(10, 1, 10), Vector3(0, 8.5, 0), platform_color)
	# Tower railings
	_create_box("tower_rail_n", Vector3(10, 1.5, 0.5), Vector3(0, 9.5, -4.75), wall_color)
	_create_box("tower_rail_s", Vector3(10, 1.5, 0.5), Vector3(0, 9.5, 4.75), wall_color)
	_create_box("tower_rail_w", Vector3(0.5, 1.5, 10), Vector3(-4.75, 9.5, 0), wall_color)
	_create_box("tower_rail_e", Vector3(0.5, 1.5, 10), Vector3(4.75, 9.5, 0), wall_color)
	# Stairs to tower
	for i in range(10):
		_create_box("tower_stairs_" + str(i), Vector3(2.5, 0.5, 1.2), Vector3(6 + i * 0.3, 0.25 + i * 0.5, 0), ramp_color)
	
	# ===== A SITE (North-West, multi-level) =====
	# Lower A site
	_create_box("a_site_lower", Vector3(30, 2, 25), Vector3(-30, 1, -40), ground_color)
	# Upper A site balcony
	_create_box("a_site_upper", Vector3(20, 1, 12), Vector3(-30, 6, -48), platform_color)
	# Upper support pillars
	_create_box("a_pillar_1", Vector3(2, 5, 2), Vector3(-38, 3.5, -52), pillar_color)
	_create_box("a_pillar_2", Vector3(2, 5, 2), Vector3(-22, 3.5, -52), pillar_color)
	_create_box("a_pillar_3", Vector3(2, 5, 2), Vector3(-38, 3.5, -44), pillar_color)
	_create_box("a_pillar_4", Vector3(2, 5, 2), Vector3(-22, 3.5, -44), pillar_color)
	# Stairs to upper A
	for i in range(6):
		_create_box("a_stairs_" + str(i), Vector3(1.5, 0.5, 1), Vector3(-15 + i * 0.3, 0.25 + i * 0.5, -48), ramp_color)
	# A site back wall (taller)
	_create_box("a_wall_back", Vector3(30, 10, 2), Vector3(-30, 6, -54), wall_color)
	# A site side wall
	_create_box("a_wall_side", Vector3(2, 10, 25), Vector3(-46, 6, -40), wall_color)
	# A site boxes
	_create_box("a_box1", Vector3(4, 3, 4), Vector3(-25, 1.5, -35), crate_color)
	_create_box("a_box2", Vector3(3, 2, 3), Vector3(-20, 1, -45), crate_color)
	_create_box("a_box3", Vector3(5, 4, 2), Vector3(-35, 2, -35), crate_color)
	_create_box("a_box4", Vector3(3, 2, 3), Vector3(-32, 7, -48), crate_color)
	# A site ramp from ground
	_create_box("a_ramp", Vector3(8, 1, 12), Vector3(-15, 0.5, -42), ramp_color)
	# A site L-shaped wall
	_create_box("a_lwall_1", Vector3(8, 5, 1), Vector3(-30, 3.5, -32), wall_color)
	_create_box("a_lwall_2", Vector3(1, 5, 6), Vector3(-26, 3.5, -29), wall_color)
	
	# ===== B SITE (South-East, enclosed with tunnel) =====
	_create_box("b_site", Vector3(28, 2, 22), Vector3(32, 1, 42), ground_color)
	_create_box("b_wall_n", Vector3(28, 8, 2), Vector3(32, 5, 31), wall_color)
	_create_box("b_wall_s", Vector3(28, 8, 2), Vector3(32, 5, 53), wall_color)
	_create_box("b_wall_e", Vector3(2, 8, 22), Vector3(46, 5, 42), wall_color)
	_create_box("b_entrance_l", Vector3(2, 8, 8), Vector3(18, 5, 38), wall_color)
	_create_box("b_entrance_r", Vector3(2, 8, 8), Vector3(18, 5, 46), wall_color)
	# B site upper ledge
	_create_box("b_ledge", Vector3(20, 1, 4), Vector3(32, 5.5, 35), platform_color)
	_create_box("b_ledge_support", Vector3(2, 4, 2), Vector3(32, 3, 35), pillar_color)
	# B site boxes
	_create_box("b_box1", Vector3(4, 3, 4), Vector3(30, 1.5, 40), crate_color)
	_create_box("b_box2", Vector3(3, 2, 5), Vector3(38, 1, 44), crate_color)
	_create_box("b_box3", Vector3(2, 4, 2), Vector3(35, 2, 38), crate_color)
	_create_box("b_box4", Vector3(3, 2, 3), Vector3(32, 6, 35), crate_color)
	# B tunnel (low ceiling corridor)
	_create_box("b_tunnel_floor", Vector3(12, 1, 20), Vector3(15, 0.5, 42), ground_color)
	_create_box("b_tunnel_wall_l", Vector3(1, 4, 20), Vector3(9, 2.5, 42), wall_color)
	_create_box("b_tunnel_wall_r", Vector3(1, 4, 20), Vector3(21, 2.5, 42), wall_color)
	_create_box("b_tunnel_ceiling", Vector3(12, 0.5, 20), Vector3(15, 4.5, 42), wall_color)
	
	# ===== MID (Central area with more cover) =====
	# Mid divider wall (partial, with opening)
	_create_box("mid_divider_n", Vector3(4, 6, 12), Vector3(0, 3, -10), wall_color)
	_create_box("mid_divider_s", Vector3(4, 6, 12), Vector3(0, 3, 10), wall_color)
	# Mid connector walls
	_create_box("mid_north_l", Vector3(20, 6, 4), Vector3(-18, 3, -20), wall_color)
	_create_box("mid_north_r", Vector3(20, 6, 4), Vector3(18, 3, -20), wall_color)
	_create_box("mid_south_l", Vector3(20, 6, 4), Vector3(-18, 3, 20), wall_color)
	_create_box("mid_south_r", Vector3(20, 6, 4), Vector3(18, 3, 20), wall_color)
	# Mid pillars
	_create_box("mid_pillar_1", Vector3(2, 6, 2), Vector3(-8, 3, 0), pillar_color)
	_create_box("mid_pillar_2", Vector3(2, 6, 2), Vector3(8, 3, 0), pillar_color)
	_create_box("mid_pillar_3", Vector3(2, 6, 2), Vector3(0, 3, -18), pillar_color)
	_create_box("mid_pillar_4", Vector3(2, 6, 2), Vector3(0, 3, 18), pillar_color)
	# Mid crates
	_create_box("mid_crate1", Vector3(3, 2, 3), Vector3(-5, 1, -8), crate_color)
	_create_box("mid_crate2", Vector3(4, 2, 2), Vector3(6, 1, 5), crate_color)
	_create_box("mid_crate3", Vector3(2, 3, 2), Vector3(-10, 1.5, 12), crate_color)
	
	# ===== LONG A (North side corridor, elevated) =====
	_create_box("longa_floor", Vector3(50, 1, 10), Vector3(-5, 1, -50), ground_color)
	_create_box("longa_wall_n", Vector3(50, 8, 2), Vector3(-5, 5, -56), wall_color)
	_create_box("longa_wall_s", Vector3(50, 6, 2), Vector3(-5, 4, -44), wall_color)
	# Long A crates
	_create_box("longa_crate1", Vector3(3, 2, 3), Vector3(-10, 2, -50), crate_color)
	_create_box("longa_crate2", Vector3(4, 3, 2), Vector3(5, 2.5, -50), crate_color)
	_create_box("longa_crate3", Vector3(2, 2, 4), Vector3(15, 2, -50), crate_color)
	_create_box("longa_crate4", Vector3(3, 3, 3), Vector3(-20, 2.5, -50), crate_color)
	# Long A double stack
	_create_box("longa_stack_b", Vector3(3, 2, 3), Vector3(0, 2, -50), crate_color)
	_create_box("longa_stack_t", Vector3(2.5, 1.5, 2.5), Vector3(0, 3.75, -50), crate_color)
	
	# ===== SHORT A (connecting mid to A, with stairs) =====
	_create_box("shorta_wall", Vector3(2, 6, 15), Vector3(-12, 3, -28), wall_color)
	_create_box("shorta_crate", Vector3(3, 2, 3), Vector3(-8, 1, -25), crate_color)
	# Short A stairs
	for i in range(5):
		_create_box("shorta_stairs_" + str(i), Vector3(3, 0.5, 1), Vector3(-12, 0.25 + i * 0.5, -20 + i * 1.2), ramp_color)
	
	# ===== CATWALK / UPPER MID (expanded) =====
	_create_box("catwalk_main", Vector3(10, 1, 20), Vector3(8, 4, -5), platform_color)
	_create_box("catwalk_ramp", Vector3(6, 0.5, 10), Vector3(8, 2.25, 7.5), ramp_color)
	_create_box("catwalk_wall_w", Vector3(1, 6, 20), Vector3(3, 7, -5), wall_color)
	_create_box("catwalk_wall_n", Vector3(10, 6, 1), Vector3(8, 7, -15), wall_color)
	# Catwalk crates
	_create_box("catwalk_crate1", Vector3(2, 2, 2), Vector3(8, 5, -10), crate_color)
	_create_box("catwalk_crate2", Vector3(3, 2, 2), Vector3(6, 5, -2), crate_color)
	
	# ===== SKY BRIDGE (connecting A upper to Tower) =====
	_create_box("skybridge", Vector3(20, 1, 3), Vector3(-15, 9, -24), platform_color)
	_create_box("skybridge_rail_l", Vector3(20, 1.5, 0.5), Vector3(-15, 10, -25.25), wall_color)
	_create_box("skybridge_rail_r", Vector3(20, 1.5, 0.5), Vector3(-15, 10, -22.75), wall_color)
	
	# ===== TUNNEL TO B (extended) =====
	_create_box("tunnel_wall_n", Vector3(15, 6, 2), Vector3(15, 3, 30), wall_color)
	_create_box("tunnel_wall_s", Vector3(15, 6, 2), Vector3(15, 3, 50), wall_color)
	_create_box("tunnel_divider", Vector3(2, 5, 10), Vector3(10, 3, 40), wall_color)
	_create_box("tunnel_crate1", Vector3(3, 2, 3), Vector3(18, 1, 35), crate_color)
	_create_box("tunnel_crate2", Vector3(2, 2, 2), Vector3(12, 1, 45), crate_color)
	
	# ===== SCATTERED CRATES FOR COVER (more variety) =====
	_create_box("crate_mid1", Vector3(3, 2, 3), Vector3(0, 1, 15), crate_color)
	_create_box("crate_mid2", Vector3(2, 2, 2), Vector3(-8, 1, 8), crate_color)
	_create_box("crate_mid3", Vector3(4, 2, 2), Vector3(10, 1, -15), crate_color)
	_create_box("crate_ct1", Vector3(3, 3, 3), Vector3(-40, 1.5, -20), crate_color)
	_create_box("crate_t1", Vector3(3, 2, 4), Vector3(40, 1, 25), crate_color)
	_create_box("crate_t2", Vector3(2, 3, 2), Vector3(30, 1.5, 20), crate_color)
	_create_box("crate_long", Vector3(6, 2, 2), Vector3(-5, 1, -48), crate_color)
	_create_box("crate_short", Vector3(2, 2, 4), Vector3(25, 1, 5), crate_color)
	_create_box("crate_corner", Vector3(3, 2, 3), Vector3(-15, 1, 15), crate_color)
	_create_box("crate_island", Vector3(4, 2, 4), Vector3(20, 1, -10), crate_color)
	
	# ===== DOUBLE STACKS =====
	_create_box("double_stack1_bottom", Vector3(3, 2, 3), Vector3(-5, 1, -30), crate_color)
	_create_box("double_stack1_top", Vector3(2.5, 1.5, 2.5), Vector3(-5, 2.75, -30), crate_color)
	_create_box("double_stack2_bottom", Vector3(3, 2, 3), Vector3(20, 1, -25), crate_color)
	_create_box("double_stack2_top", Vector3(2.5, 1.5, 2.5), Vector3(20, 2.75, -25), crate_color)
	_create_box("double_stack3_bottom", Vector3(3, 2, 3), Vector3(15, 1, 10), crate_color)
	_create_box("double_stack3_top", Vector3(2.5, 1.5, 2.5), Vector3(15, 2.75, 10), crate_color)
	
	# ===== EXTRA PILLARS (scattered for cover) =====
	_create_box("pillar_1", Vector3(1.5, 6, 1.5), Vector3(-25, 3, 5), pillar_color)
	_create_box("pillar_2", Vector3(1.5, 6, 1.5), Vector3(25, 3, -15), pillar_color)
	_create_box("pillar_3", Vector3(1.5, 6, 1.5), Vector3(-15, 3, -15), pillar_color)
	_create_box("pillar_4", Vector3(1.5, 6, 1.5), Vector3(15, 3, 15), pillar_color)
	_create_box("pillar_5", Vector3(1.5, 8, 1.5), Vector3(-35, 4, 10), pillar_color)
	_create_box("pillar_6", Vector3(1.5, 8, 1.5), Vector3(35, 4, -10), pillar_color)
	
	# ===== ARCHWAY (Mid entrance, decorative) =====
	_create_box("arch_left", Vector3(3, 6, 3), Vector3(-6, 3, 20), wall_color)
	_create_box("arch_right", Vector3(3, 6, 3), Vector3(6, 3, 20), wall_color)
	_create_box("arch_top", Vector3(12, 2, 3), Vector3(0, 6, 20), wall_color)
	
	# ===== SNIPER NEST (South-West corner, elevated) =====
	_create_box("sniper_platform", Vector3(12, 1, 8), Vector3(-45, 5, 45), platform_color)
	_create_box("sniper_pillar1", Vector3(2, 5, 2), Vector3(-49, 3, 42), pillar_color)
	_create_box("sniper_pillar2", Vector3(2, 5, 2), Vector3(-41, 3, 42), pillar_color)
	_create_box("sniper_pillar3", Vector3(2, 5, 2), Vector3(-49, 3, 48), pillar_color)
	_create_box("sniper_pillar4", Vector3(2, 5, 2), Vector3(-41, 3, 48), pillar_color)
	_create_box("sniper_wall", Vector3(12, 4, 1), Vector3(-45, 7.5, 49), wall_color)
	# Sniper nest stairs
	for i in range(8):
		_create_box("sniper_stairs_" + str(i), Vector3(2, 0.5, 1), Vector3(-38 + i * 0.3, 0.25 + i * 0.5, 45), ramp_color)

func _create_box(name_str: String, size: Vector3, pos: Vector3, color: Color):
	# Create mesh
	var mesh = CubeMesh.new()
	mesh.size = size
	
	var mat = SpatialMaterial.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	
	var mi = MeshInstance.new()
	mi.name = name_str
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = MeshInstance.SHADOW_CASTING_SETTING_ON
	
	# Create collision
	var shape = BoxShape.new()
	shape.extents = size / 2.0
	
	var col = CollisionShape.new()
	col.name = name_str + "_col"
	col.shape = shape
	
	# Add to map
	add_child(mi)
	add_child(col)
	
	mi.global_transform.origin = pos
	col.global_transform.origin = pos
