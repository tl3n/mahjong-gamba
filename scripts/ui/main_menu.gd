extends Control

@onready var continue_button: TextureButton = $ContinueButton
@onready var new_game_button: TextureButton = $NewGameButton
@onready var quit_button: TextureButton = $QuitButton
@onready var background_image: Sprite2D = $BackgroundImage
@onready var inventory_button: TextureButton = $InventoryButton if has_node("VBoxContainer/InventoryButton") else null

func _ready():
	background_image.modulate = Color(0.3, 0.3, 0.3)
	continue_button.connect("pressed", Callable(self, "_on_continue_button_pressed"))
	new_game_button.connect("pressed", Callable(self, "_on_new_game_button_pressed"))
	quit_button.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	
	if inventory_button:
		inventory_button.connect("pressed", Callable(self, "_on_inventory_pressed"))
	
	_check_save_file()

func _check_save_file():
	var save_system = get_node_or_null("/root/SaveSystem")
	
	if save_system and save_system.has_save():
		continue_button.disabled = false
		_set_button_visual_state(continue_button, false)
		print("Save file found - Continue available")
	else:
		continue_button.disabled = true
		_set_button_visual_state(continue_button, true)
		print("No save file - New Game only")

func _set_button_visual_state(button: TextureButton, is_disabled: bool):
	if is_disabled:
		button.modulate = Color(0.5, 0.5, 0.5, 0.7)  
	else:
		button.modulate = Color(1.0, 1.0, 1.0, 1.0)  

func _on_continue_button_pressed():
	var save_system = get_node_or_null("/root/SaveSystem")
	if not save_system:
		print("SaveSystem not found!")
		return
	
	if not save_system.has_save():
		print("No save file to continue!")
		return
	
	print("\n=== CONTINUING GAME ===")
	
	if save_system.load_game():
		print("Save loaded successfully")
		print("Going directly to game scene...")
		
		await get_tree().create_timer(0.2).timeout
		
		get_tree().change_scene_to_file("res://scenes/main/game_scene.tscn")
	else:
		print("Failed to load save!")

func _on_new_game_button_pressed():
	print("\n=== STARTING NEW GAME ===")
	
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system and save_system.has_save():
		print("Deleting old save...")
		save_system.delete_save()
	
	_initialize_new_game()
	
	await get_tree().create_timer(0.2).timeout
	
	print("Going to shop scene...")
	get_tree().change_scene_to_file("res://scenes/main/shop_scene.tscn")

func _initialize_new_game():
	var inventory = get_node_or_null("/root/Inventory")
	if not inventory:
		print("ERROR: Inventory not found!")
		return
	
	print("Resetting inventory...")
	
	inventory.spirits.clear()
	inventory.beers.clear()
	inventory.money = 10
	
	print("New game initialized:")
	print("   Money: %d" % inventory.money)
	print("   Spirits: %d" % inventory.spirits.size())
	print("   Beers: %d" % inventory.beers.size())
	
	inventory.emit_signal("inventory_changed")
	inventory.emit_signal("money_changed", inventory.money)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("reset_game"):
		gm.reset_game()
		print("GameManager reset")

func _on_quit_button_pressed():
	print("Quitting game...")
	
	await get_tree().create_timer(0.2).timeout
	
	get_tree().quit()

func _on_inventory_pressed():
	
	var inv_scene = load("res://scenes/ui/Inventory.tscn")
	if inv_scene:
		var inv_instance = inv_scene.instantiate()
		get_tree().get_root().add_child(inv_instance)
		
		if inv_instance is Control:
			inv_instance.position = Vector2(
				(get_viewport_rect().size.x - 800) / 2,
				(get_viewport_rect().size.y - 600) / 2
			)

func _setup_hover_effects():
	_connect_hover_effect(continue_button)
	_connect_hover_effect(new_game_button)
	_connect_hover_effect(quit_button)
	if inventory_button:
		_connect_hover_effect(inventory_button)

func _connect_hover_effect(button: TextureButton):
	if button == null:
		return
	
	button.connect("mouse_entered", Callable(self, "_on_button_hover").bind(button, true))
	button.connect("mouse_exited", Callable(self, "_on_button_hover").bind(button, false))

func _on_button_hover(button: TextureButton, is_hovering: bool):
	if button.disabled:
		return
	
	var tween = create_tween()
	
	if is_hovering:
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
	else:
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
