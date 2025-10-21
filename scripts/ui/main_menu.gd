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
	if not inventory:
		print("❌ ПОМИЛКА: Inventory не знайдено!")
		return
	
	inventory.spirits.clear()
	inventory.beers.clear()
	inventory.money = 10
	
	var s1 = Spirit.new()
	s1.id = "spirit_fire"
	s1.name = "Дух Вогню"
	s1.description = "Додає +4 до масті Вогню"
	s1.price = 8
	s1.rarity = "Міфічна"
	s1.type = "дух"
	s1.effect_type = "mansion_multiplier"
	s1.effect_value = 4.0
	inventory.spirits.append(s1)
	
	var b1 = Beer.new()
	b1.id = "beer_extra_draw"
	b1.name = "Пиво: Додатковий добір"
	b1.description = "Дозволяє тягнути додатковий тайл цього раунду."
	b1.price = 3
	b1.rarity = "Історична"
	b1.type = "пиво"
	b1.round_effect = "extra_draw"
	b1.duration = 1
	inventory.beers.append(b1)
	
	print("✅ Створено предмети:")
	print("   Spirits: ", inventory.spirits.size())
	print("   Beers: ", inventory.beers.size())
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
