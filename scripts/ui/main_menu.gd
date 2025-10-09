extends Control


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/game_scene.tscn") # TODO: change path to the actual game scene


func _on_quit_button_pressed() -> void:
	get_tree().quit()
