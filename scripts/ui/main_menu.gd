extends Control


func _on_start_button_pressed() -> void:
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		if save_system.has_save():
			print("saved game exists, loading")
			save_system.load_game()
		else:
			_initialize_new_game()
	else:
		_initialize_new_game()
	get_tree().change_scene_to_file("res://scenes/main/shop_scene.tscn")
	
func _initialize_new_game():
	var inventory = get_node_or_null("/root/Inventory")
	
	inventory.spirits.clear()
	inventory.beers.clear()
	inventory.money = 10
	
	print("   Money: ", inventory.money)
	
	inventory.emit_signal("inventory_changed")
	inventory.emit_signal("money_changed", inventory.money)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.reset_game()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_shop_pressed() -> void:
	var shop_scene = load("res://scenes/main/shop_scene.tscn")
	var shop_instance = shop_scene.instantiate()
	get_tree().get_root().add_child(shop_instance)
	shop_instance.set_global_position(Vector2(50, 50))
