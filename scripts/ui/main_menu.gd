extends Control

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

@onready var inventory_button: Button = $VBoxContainer/InventoryButton if has_node("VBoxContainer/InventoryButton") else null

func _ready():
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
		continue_button.text = "Continue Game"
		new_game_button.text = "New Game"
		print("Save file found - Continue available")
	else:
		continue_button.disabled = true
		continue_button.text = "Continue (No Save)"
		new_game_button.text = "Start Game"
		print("No save file - New Game only")

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
	print("Money: %d" % inventory.money)
	print("Spirits: %d" % inventory.spirits.size())
	print("Beers: %d" % inventory.beers.size())
	
	inventory.emit_signal("inventory_changed")
	inventory.emit_signal("money_changed", inventory.money)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("reset_game"):
		gm.reset_game()
		print("GameManager reset")

func _on_quit_button_pressed():
	print("Quitting game...")
	get_tree().quit()
