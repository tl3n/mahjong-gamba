extends Control

@onready var profile_list_container: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/ProfileList
@onready var name_input: LineEdit = $CenterContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/NameInput
@onready var create_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/CreateButton

var save_system = null

func _ready():
	save_system = get_node_or_null("/root/SaveSystem")
	
	create_button.connect("pressed", Callable(self, "_on_create_pressed"))
	
	_refresh_list()

func _refresh_list():
	if not save_system: 
		return
	
	# Очищаємо старі кнопки
	for child in profile_list_container.get_children():
		child.queue_free()
	
	# Отримуємо список профілів
	var profiles = save_system.get_all_profiles()
	
	if profiles.is_empty():
		var label = Label.new()
		label.text = "No profiles found. Create one!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		profile_list_container.add_child(label)
	else:
		for p_name in profiles:
			var profile_row = _create_profile_row(p_name)
			profile_list_container.add_child(profile_row)

func _create_profile_row(p_name: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 50)
	row.add_theme_constant_override("separation", 10)
	
	# Кнопка вибору профіля
	var select_btn = Button.new()
	select_btn.custom_minimum_size = Vector2(200, 44)
	select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Styling
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.25, 0.18, 1)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.45, 0.65, 0.5, 0.9)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	select_btn.add_theme_stylebox_override("normal", btn_style)
	select_btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	select_btn.add_theme_font_size_override("font_size", 14)
	
	# Завантажуємо статистику
	var stats = save_system.load_profile_stats(p_name)
	var max_blinds = stats.get("max_blinds", 0)
	
	# Текст з профілем та статистикою
	select_btn.text = "%s | Best: Blind %d" % [p_name, max_blinds]
	select_btn.connect("pressed", Callable(self, "_on_profile_selected").bind(p_name))
	
	row.add_child(select_btn)
	
	# Кнопка видалення
	var delete_btn = Button.new()
	delete_btn.text = "🗑"
	delete_btn.custom_minimum_size = Vector2(44, 44)
	
	var del_style = StyleBoxFlat.new()
	del_style.bg_color = Color(0.3, 0.15, 0.15, 1)
	del_style.border_width_left = 2
	del_style.border_width_top = 2
	del_style.border_width_right = 2
	del_style.border_width_bottom = 2
	del_style.border_color = Color(0.6, 0.35, 0.35, 0.9)
	del_style.corner_radius_top_left = 8
	del_style.corner_radius_top_right = 8
	del_style.corner_radius_bottom_left = 8
	del_style.corner_radius_bottom_right = 8
	delete_btn.add_theme_stylebox_override("normal", del_style)
	delete_btn.add_theme_font_size_override("font_size", 16)
	delete_btn.connect("pressed", Callable(self, "_on_delete_pressed").bind(p_name))
	
	row.add_child(delete_btn)
	
	return row

func _on_profile_selected(p_name: String):
	print("Selected profile: ", p_name)
	
	if save_system:
		save_system.set_current_profile(p_name)
		
		# Завантажуємо дані якщо є
		if save_system.has_save():
			save_system.load_game()
		else:
			# Якщо профіль є, але сейва немає - скидаємо гру
			var gm = get_node_or_null("/root/GameManager")
			if gm: 
				gm.reset_game()
			
	# Перехід у Головне Меню
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_delete_pressed(p_name: String):
	print("Deleting profile: ", p_name)
	
	if save_system:
		save_system.delete_profile(p_name)
		_refresh_list()

func _on_create_pressed():
	print("Attempting to create profile...")
	
	if not save_system:
		push_error("SaveSystem NOT FOUND!")
		return

	var new_name = name_input.text.strip_edges()
	
	if new_name.is_empty():
		print("Empty name!")
		return
		
	if save_system.create_profile(new_name):
		print("Profile created successfully!")
		name_input.text = ""
		_refresh_list()
	else:
		print("Failed to create profile")
