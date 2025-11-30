extends Control

@onready var profile_list_container: VBoxContainer = $VBoxContainer/ScrollContainer/ProfileList
@onready var name_input: LineEdit = $VBoxContainer/HBoxContainer/NameInput
@onready var create_button: Button = $VBoxContainer/HBoxContainer/CreateButton

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
	
	# Кнопка вибору профіля
	var select_btn = Button.new()
	select_btn.custom_minimum_size = Vector2(200, 40)
	select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Завантажуємо статистику
	var stats = save_system.load_profile_stats(p_name)
	var max_blinds = stats.get("max_blinds", 0)
	
	# Текст з профілем та статистикою
	select_btn.text = "%s | Best: Blind %d" % [p_name, max_blinds]
	select_btn.connect("pressed", Callable(self, "_on_profile_selected").bind(p_name))
	
	row.add_child(select_btn)
	
	# Кнопка видалення
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(80, 40)
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
