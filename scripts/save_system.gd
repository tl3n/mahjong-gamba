extends Node

var current_profile_name: String = ""

var cached_shop_items: Array = []
var cached_reroll_cost: int = 3

func get_save_path() -> String:
	if current_profile_name == "":
		return ""
	return "user://save_%s.dat" % current_profile_name


func set_current_profile(profile_name: String):
	current_profile_name = profile_name
	print("Profile selected: %s" % current_profile_name)

func create_profile(new_name: String) -> bool:
	# Перевірка на заборонені символи
	if new_name.is_empty() or new_name.contains("/") or new_name.contains("\\") or new_name.contains(":"):
		print("❌ Invalid profile name: %s" % new_name)
		return false
		
	current_profile_name = new_name
	
	# Скидаємо гру перед створенням нового профілю, 
	# щоб не зберегти стан з попередньої сесії
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.reset_game()
		
	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		# Очищаємо інвентар для нового профілю
		inventory.money = inventory.starting_money
		inventory.spirits.clear()
		inventory.beers.clear()
	
	# Пробуємо зберегти
	if save_game():
		print("✅ Profile created: %s" % new_name)
		return true
	else:
		print("❌ Failed to create profile file!")
		current_profile_name = "" # Скидаємо, якщо не вийшло
		return false

func save_game():
	var path = get_save_path()
	if path == "":
		print("Cannot save: No profile selected!")
		return false

	print("\n=== SAVING GAME (%s) ===" % current_profile_name)
	
	var save_data = {
		"inventory": _serialize_inventory(),
		"game_state": _serialize_game_state(),
		"shop_state": _serialize_shop_state()
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Game saved successfully to: %s" % path)
		return true
	else:
		print("Saving error!")
		return false

func load_game() -> bool:
	var path = get_save_path()
	if path == "" or not FileAccess.file_exists(path):
		print("Savefile not found for profile: %s" % current_profile_name)
		return false
	
	print("\n === LOADING GAME (%s) ===" % current_profile_name)
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		_deserialize_inventory(save_data.get("inventory", {}))
		_deserialize_game_state(save_data.get("game_state", {}))
		_deserialize_shop_state(save_data.get("shop_state", {}))
		
		print("Save loaded successfully")
		return true
	else:
		print("Loading error!")
		return false

func has_save() -> bool:
	var path = get_save_path()
	return path != "" and FileAccess.file_exists(path)

func delete_save():
	var path = get_save_path()
	if path != "" and FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Save deleted for profile: %s" % current_profile_name)


func clear_cached_shop_state():
	print("Clearing cached shop state for new blind...")
	cached_shop_items.clear()

func save_shop_state(items: Array, reroll_cost: int):
	cached_shop_items = items.duplicate()
	cached_reroll_cost = reroll_cost
	save_game()

func load_shop_state() -> Dictionary:
	return {
		"items": cached_shop_items.duplicate(),
		"reroll_cost": cached_reroll_cost
	}

func _serialize_inventory() -> Dictionary:
	var inv = get_node_or_null("/root/Inventory")
	if not inv: return {}
	var spirits_data = []
	for s in inv.spirits: spirits_data.append(_serialize_item(s))
	var beers_data = []
	for b in inv.beers: beers_data.append(_serialize_item(b))
	return {"spirits": spirits_data, "beers": beers_data, "money": inv.money}

func _serialize_item(item: Item) -> Dictionary:
	if item == null: return {}
	var data = {"id": item.id, "name": item.name, "description": item.description, "rarity": item.rarity, "price": item.price, "type": item.type}
	if item is Spirit:
		data["effect_type"] = item.effect_type; data["effect_value"] = item.effect_value; data["condition"] = item.condition; data["permanent"] = item.permanent
		if data["type"] == "": data["type"] = "spirit"
	elif item is Beer:
		data["blind_effect"] = item.blind_effect; data["duration"] = item.duration; data["bonus_value"] = item.bonus_value
		if data["type"] == "": data["type"] = "beer"
	return data

func _deserialize_inventory(data: Dictionary):
	var inv = get_node_or_null("/root/Inventory")
	if not inv: return
	inv.spirits.clear(); inv.beers.clear()
	for s in data.get("spirits", []): 
		var spirit = _deserialize_item(s)
		if spirit: inv.spirits.append(spirit)
	for b in data.get("beers", []):
		var beer = _deserialize_item(b)
		if beer: inv.beers.append(beer)
	inv.money = data.get("money", 10)
	inv.emit_signal("inventory_changed"); inv.emit_signal("money_changed", inv.money)

func _deserialize_item(data: Dictionary):
	if data.is_empty(): return null
	var type = data.get("type", "")
	if type == "spirit": return ItemDatabase.create_spirit_from_data(data)
	elif type == "beer": return ItemDatabase.create_beer_from_data(data)
	return null

func _serialize_shop_state() -> Dictionary:
	var items_data = []
	for item in cached_shop_items: items_data.append(_serialize_item(item))
	return {"items": items_data, "reroll_cost": cached_reroll_cost}

func _deserialize_shop_state(data: Dictionary):
	cached_shop_items.clear()
	for idata in data.get("items", []):
		var item = _deserialize_item(idata)
		# Важливо: додаємо item навіть якщо він null (щоб зберегти порожні слоти)
		cached_shop_items.append(item) 
	cached_reroll_cost = data.get("reroll_cost", 3)

# TODO: After making the main gameplay, insert the data gained from there here in order to save progress
func _serialize_game_state() -> Dictionary:
	var gm = get_node_or_null("/root/GameManager")
	if not gm: return {}
	return {
		"current_blind": gm.current_blind, "current_round": gm.current_round,
		"current_score": gm.current_score, "target_score": gm.target_score,
		"discards_left": gm.discards_left, "is_game_active": gm.is_game_active
	}

func _deserialize_game_state(data: Dictionary):
	var gm = get_node_or_null("/root/GameManager")
	if not gm: return
	gm.current_blind = data.get("current_blind", 1)
	gm.current_round = data.get("current_round", 1)
	gm.current_score = data.get("current_score", 0)
	gm.target_score = data.get("target_score", 800)
	gm.discards_left = data.get("discards_left", 5)
	gm.is_game_active = data.get("is_game_active", false)

func get_all_profiles() -> Array[String]:
	var profiles_set = {}  # Використовуємо як set для унікальності
	var dir = DirAccess.open("user://")
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				var p_name = ""
				
				# Шукаємо сейви
				if file_name.begins_with("save_") and file_name.ends_with(".dat"):
					p_name = file_name.trim_prefix("save_").trim_suffix(".dat")
					profiles_set[p_name] = true
				
				# Шукаємо статистику
				elif file_name.begins_with("stats_") and file_name.ends_with(".dat"):
					p_name = file_name.trim_prefix("stats_").trim_suffix(".dat")
					profiles_set[p_name] = true
			
			file_name = dir.get_next()
	
	# Конвертуємо set в array
	var profiles: Array[String] = []
	for p in profiles_set.keys():
		profiles.append(p)
	
	profiles.sort()  # Сортуємо алфавітно
	return profiles

# Статистика профілів (окремий файл від сейвів)
func get_stats_path(profile_name: String) -> String:
	return "user://stats_%s.dat" % profile_name

func update_profile_stats(blinds_reached: int):
	if current_profile_name == "":
		print("Cannot update stats: no profile selected")
		return
	
	var stats_path = get_stats_path(current_profile_name)
	var stats = load_profile_stats(current_profile_name)
	
	print("Updating stats for %s: reached blind %d" % [current_profile_name, blinds_reached])
	
	# Оновлюємо максимум
	var old_max = stats.get("max_blinds", 0)
	if blinds_reached > old_max:
		stats["max_blinds"] = blinds_reached
		print("New record! Max blinds: %d (was: %d)" % [blinds_reached, old_max])
	else:
		print("Current max blinds remains: %d" % old_max)
	
	# Зберігаємо
	var file = FileAccess.open(stats_path, FileAccess.WRITE)
	if file:
		file.store_var(stats)
		file.close()
		print("Stats saved to: %s" % stats_path)
	else:
		print("ERROR: Could not save stats!")

func load_profile_stats(profile_name: String) -> Dictionary:
	var stats_path = get_stats_path(profile_name)
	
	if not FileAccess.file_exists(stats_path):
		print("No stats file for %s, creating default" % profile_name)
		return {"max_blinds": 0}
	
	var file = FileAccess.open(stats_path, FileAccess.READ)
	if file:
		var stats = file.get_var()
		file.close()
		print("Loaded stats for %s: %s" % [profile_name, stats])
		return stats
	
	return {"max_blinds": 0}

func delete_profile(profile_name: String):
	print("Deleting profile: %s" % profile_name)
	
	# Видаляємо і сейв, і статистику
	var save_path = "user://save_%s.dat" % profile_name
	var stats_path = get_stats_path(profile_name)
	
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		print("  Deleted save: %s" % save_path)
	
	if FileAccess.file_exists(stats_path):
		DirAccess.remove_absolute(stats_path)
		print("  Deleted stats: %s" % stats_path)
	
	print("Profile %s completely deleted" % profile_name)
