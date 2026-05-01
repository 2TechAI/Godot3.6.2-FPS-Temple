extends Control

export(PackedScene) var game_scene

var settings_visible = false
var multiplayer_visible = false

func _ready():
	# Connect main menu buttons
	$center_container/main_panel/main/start.connect("pressed", self, "_on_start_pressed")
	$center_container/main_panel/main/settings.connect("pressed", self, "_on_settings_pressed")
	$center_container/main_panel/main/quit.connect("pressed", self, "_on_quit_pressed")
	$center_container/main_panel/main/multiplayer.connect("pressed", self, "_on_multiplayer_pressed")
	
	# Connect settings buttons
	$settings/settings_vbox/back.connect("pressed", self, "_on_settings_back_pressed")
	$settings/settings_vbox/sensitivity_slider.connect("value_changed", self, "_on_sensitivity_changed")
	$settings/settings_vbox/volume_slider.connect("value_changed", self, "_on_volume_changed")
	
	# Connect multiplayer buttons
	$multiplayer_panel/mp_vbox/host_btn.connect("pressed", self, "_on_host_pressed")
	$multiplayer_panel/mp_vbox/join_btn.connect("pressed", self, "_on_join_pressed")
	$multiplayer_panel/mp_vbox/back_btn.connect("pressed", self, "_on_mp_back_pressed")
	
	$settings.visible = false
	$multiplayer_panel.visible = false
	$center_container/main_panel.visible = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_setup_extra_settings()
	_setup_fonts()
	_load_saved_settings()

func _setup_extra_settings():
	var quality_label = Label.new()
	quality_label.text = "画质设置"
	quality_label.align = Label.ALIGN_CENTER
	$settings/settings_vbox.add_child(quality_label)
	
	var quality_option = OptionButton.new()
	quality_option.name = "quality"
	quality_option.add_item("低")
	quality_option.add_item("中")
	quality_option.add_item("高")
	quality_option.add_item("极高")
	quality_option.selected = 1
	quality_option.connect("item_selected", self, "_on_quality_changed")
	$settings/settings_vbox.add_child(quality_option)
	
	var motion_label = Label.new()
	motion_label.text = "动态模糊"
	motion_label.align = Label.ALIGN_CENTER
	$settings/settings_vbox.add_child(motion_label)
	
	var motion_check = CheckButton.new()
	motion_check.name = "motion_blur"
	motion_check.text = "关闭"
	motion_check.connect("toggled", self, "_on_motion_blur_toggled")
	$settings/settings_vbox.add_child(motion_check)

func _setup_fonts():
	var font = _load_chinese_font()
	if not font:
		return
	
	# Title font (main game title)
	var title_font = font.duplicate()
	title_font.size = 32
	if $center_container/main_panel/main.has_node("game_title"):
		$center_container/main_panel/main/game_title.add_font_override("font", title_font)
	
	# Button fonts
	for btn in $center_container/main_panel/main.get_children():
		if btn is Button:
			var btn_font = font.duplicate()
			btn_font.size = 20
			btn.add_font_override("font", btn_font)
	
	# Settings fonts
	for child in $settings/settings_vbox.get_children():
		if child is Label:
			var lbl_font = font.duplicate()
			lbl_font.size = 18
			child.add_font_override("font", lbl_font)
		elif child is Button:
			var btn_font = font.duplicate()
			btn_font.size = 18
			child.add_font_override("font", btn_font)
			if child is OptionButton:
				var popup = child.get_popup()
				if popup:
					var popup_font = font.duplicate()
					popup_font.size = 18
					popup.add_font_override("font", popup_font)
	
	# Multiplayer fonts
	for child in $multiplayer_panel/mp_vbox.get_children():
		if child is Label:
			var lbl_font = font.duplicate()
			lbl_font.size = 18
			child.add_font_override("font", lbl_font)
		elif child is Button or child is LineEdit:
			var btn_font = font.duplicate()
			btn_font.size = 16
			child.add_font_override("font", btn_font)

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

func _load_saved_settings():
	if not has_node("/root/GameConfig"):
		return
	var cfg = get_node("/root/GameConfig")
	
	$settings/settings_vbox/sensitivity_slider.value = cfg.mouse_sensitivity * 50.0
	$settings/settings_vbox/volume_slider.value = cfg.master_volume * 100.0
	
	if $settings/settings_vbox.has_node("quality"):
		$settings/settings_vbox/quality.selected = cfg.quality_index
		_on_quality_changed(cfg.quality_index)
	if $settings/settings_vbox.has_node("motion_blur"):
		$settings/settings_vbox/motion_blur.pressed = cfg.motion_blur
		_on_motion_blur_toggled(cfg.motion_blur)

func _on_start_pressed():
	if game_scene:
		get_tree().change_scene_to(game_scene)

func _on_settings_pressed():
	$center_container/main_panel.visible = false
	$settings.visible = true
	multiplayer_visible = false
	$multiplayer_panel.visible = false

func _on_quit_pressed():
	get_tree().quit()

func _on_multiplayer_pressed():
	$center_container/main_panel.visible = false
	multiplayer_visible = true
	$multiplayer_panel.visible = true

func _on_settings_back_pressed():
	$settings.visible = false
	$center_container/main_panel.visible = true

func _on_sensitivity_changed(value):
	if has_node("/root/GameConfig"):
		get_node("/root/GameConfig").mouse_sensitivity = value / 50.0

func _on_volume_changed(value):
	var db = linear2db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	if has_node("/root/GameConfig"):
		get_node("/root/GameConfig").master_volume = value / 100.0

func _on_host_pressed():
	if not has_node("/root/NetworkManager"):
		push_error("NetworkManager not found")
		return
	
	var nm = get_node("/root/NetworkManager")
	var success = nm.create_server(int($multiplayer_panel/mp_vbox/port_edit.text))
	if success:
		# Wait a frame then change scene
		var t = Timer.new()
		t.wait_time = 0.1
		t.one_shot = true
		t.connect("timeout", self, "_enter_game")
		add_child(t)
		t.start()
	else:
		print("创建服务器失败")

func _on_join_pressed():
	if not has_node("/root/NetworkManager"):
		push_error("NetworkManager not found")
		return
	
	var nm = get_node("/root/NetworkManager")
	var ip = $multiplayer_panel/mp_vbox/ip_edit.text
	var port = int($multiplayer_panel/mp_vbox/port_edit.text)
	
	var success = nm.join_server(ip, port)
	if success:
		# Wait for connection
		nm.connect("connection_succeeded", self, "_enter_game", [], CONNECT_ONESHOT)
		nm.connect("connection_failed", self, "_on_connection_failed", [], CONNECT_ONESHOT)
	else:
		print("连接失败")

func _enter_game():
	if game_scene:
		get_tree().change_scene_to(game_scene)

func _on_connection_failed():
	print("无法连接到服务器")
	if has_node("/root/NetworkManager"):
		get_node("/root/NetworkManager").close_connection()

func _on_mp_back_pressed():
	multiplayer_visible = false
	$multiplayer_panel.visible = false
	$center_container/main_panel.visible = true

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
	if has_node("/root/GameConfig"):
		get_node("/root/GameConfig").quality_index = index

func _on_motion_blur_toggled(pressed):
	var check = $settings/settings_vbox.get_node("motion_blur")
	if check:
		check.text = "开启" if pressed else "关闭"
	if has_node("/root/GameConfig"):
		get_node("/root/GameConfig").motion_blur = pressed
