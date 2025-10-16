extends Control


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/game_scene.tscn") # TODO: change path to the actual game scene


func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_inventory_pressed() -> void:
	var inv_scene = load("res://scenes/ui/Inventory.tscn")
	var inv_instance = inv_scene.instantiate()
	get_tree().get_root().add_child(inv_instance)  # додаємо в корінь, щоб з'явився поверх
	inv_instance.set_global_position(Vector2(50,50))
