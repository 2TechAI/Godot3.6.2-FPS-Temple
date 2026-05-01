extends CanvasLayer

var menu_open = false

onready var blur_bg = $blur_background
onready var quality_option = $center/panel/vbox/quality_option
onready var sensitivity_slider = $center/panel/vbox/sensitivity_slider
onready var volume_slider = $center/panel/vbox/volume_slider
onready var motion_blur_check = $center/panel/vbox/motion_blur_check
onready var resume_btn = $center/panel/vbox/resume_btn
onready var quit_btn = $center/panel/vbox/quit_btn

func _ready():
	layer = 2
	visible = false
	menu_open = false
	
	# Setup blur background shader
	var shader = load("res://data/shaders/blur.shader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_param("blur_amount", 2.0)
		blur_bg.material = mat
	
	# Populate quality options
	quality_option.add_item("低")
	quality_option.add_item("中")
	quality_option.add_item("高")
	quality_option.add_item("极高")
	
	# Connect signals
	quality_option.connect("item_selected", self, "_on_quality_changed")
	sensitivity_slider.connect("value_changed", self, "_on_sensitivity_changed")
	volume_slider.connect("value_changed", self, "_on_volume_changed")
	motion_blur_check.connect("toggled", self, "_on_motion_blur_toggled")
	resume_btn.connect("pressed", self, "_on_resume")
	quit_btn.connect("pressed", self, "_on_quit")
	
	_load_settings()
	_setup_fonts()
	_apply_initial_settings()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_menu()

func _toggle_menu():
	menu_open = !menu_open
	visible = menu_open
	
	var head = _get_head_node()
	var weapons = _get_weapons_node()
	if menu_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if head:
			head.captured = false
		if weapons:
			weapons.menu_open = true
	else:
		if head:
			head.captured = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if weapons:
			weapons.menu_open = false

func _get_head_node():
	var main = get_tree().get_root().get_child(0)
	if not main:
		return null
	
	# Single player path
	if main.has_node("character/head"):
		return main.get_node("character/head")
	
	# Multiplayer path via NetworkManager
	var nm = get_node_or_null("/root/NetworkManager")
	if nm and nm.local_player_id != 0:
		var player_name = "player_" + str(nm.local_player_id)
		if main.has_node(player_name + "/head"):
			return main.get_node(player_name + "/head")
	
	# Fallback: search player group
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_node("head"):
			return p.get_node("head")
	
	return null

func _get_weapons_node():
	var main = get_tree().get_root().get_child(0)
	if not main:
		return null
	
	if main.has_node("character/weapons"):
		return main.get_node("character/weapons")
	
	var nm = get_node_or_null("/root/NetworkManager")
	if nm and nm.local_player_id != 0:
		var player_name = "player_" + str(nm.local_player_id)
		if main.has_node(player_name + "/weapons"):
			return main.get_node(player_name + "/weapons")
	
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_node("weapons"):
			return p.get_node("weapons")
	
	return null

func _load_settings():
	var cfg = get_node_or_null("/root/GameConfig")
	if not cfg:
		return
	
	quality_option.selected = cfg.quality_index
	volume_slider.value = cfg.master_volume * 100.0
	motion_blur_check.pressed = cfg.motion_blur
	_on_motion_blur_toggled(cfg.motion_blur)
	
	var head = _get_head_node()
	if head:
		sensitivity_slider.value = head.sensibility * 100.0
	else:
		sensitivity_slider.value = cfg.mouse_sensitivity * 100.0

func _apply_initial_settings():
	var cfg = get_node_or_null("/root/GameConfig")
	if not cfg:
		return
	
	# Apply saved sensitivity to head node
	var head = _get_head_node()
	if head:
		head.sensibility = cfg.mouse_sensitivity
	
	# Apply saved volume
	var db = linear2db(cfg.master_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	
	# Apply saved quality (without saving again)
	var presets = {
		0: {"shadows": 0, "msaa": 0, "fxaa": false},
		1: {"shadows": 1, "msaa": 1, "fxaa": true},
		2: {"shadows": 2, "msaa": 2, "fxaa": true},
		3: {"shadows": 3, "msaa": 4, "fxaa": true}
	}
	var s = presets.get(cfg.quality_index, presets[1])
	ProjectSettings.set_setting("rendering/quality/shadows/filter_mode", s.shadows)
	ProjectSettings.set_setting("rendering/quality/filters/msaa", s.msaa)
	ProjectSettings.set_setting("rendering/quality/filters/use_fxaa", s.fxaa)
	get_viewport().msaa = s.msaa

func _setup_fonts():
	var font = _load_chinese_font()
	if not font:
		return
	
	var title_font = font.duplicate()
	title_font.size = 24
	
	var item_font = font.duplicate()
	item_font.size = 16
	
	# Apply theme to panel so all children inherit the font
	var panel = $center/panel
	var theme = Theme.new()
	theme.default_font = item_font
	panel.set_theme(theme)
	
	# Title specific override
	$center/panel/vbox/title_label.add_font_override("font", title_font)
	
	# OptionButton popup font
	var popup = quality_option.get_popup()
	if popup:
		popup.add_font_override("font", item_font)

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

func _on_resume():
	_toggle_menu()

func _on_quit():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://data/scenes/menu.tscn")

func _on_quality_changed(index):
	var presets = {
		0: {"shadows": 0, "msaa": 0, "fxaa": false},
		1: {"shadows": 1, "msaa": 1, "fxaa": true},
		2: {"shadows": 2, "msaa": 2, "fxaa": true},
		3: {"shadows": 3, "msaa": 4, "fxaa": true}
	}
	var s = presets.get(index, presets[1])
	ProjectSettings.set_setting("rendering/quality/shadows/filter_mode", s.shadows)
	ProjectSettings.set_setting("rendering/quality/filters/msaa", s.msaa)
	ProjectSettings.set_setting("rendering/quality/filters/use_fxaa", s.fxaa)
	ProjectSettings.save_custom("override.cfg")
	get_viewport().msaa = s.msaa
	
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		cfg.quality_index = index

func _on_sensitivity_changed(value):
	var sens = value / 100.0
	var head = _get_head_node()
	if head:
		head.sensibility = sens
	
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		cfg.mouse_sensitivity = sens

func _on_volume_changed(value):
	var db = linear2db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		cfg.master_volume = value / 100.0

func _on_motion_blur_toggled(pressed):
	motion_blur_check.text = "开启" if pressed else "关闭"
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		cfg.motion_blur = pressed
