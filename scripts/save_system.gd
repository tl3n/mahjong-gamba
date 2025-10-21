extends Node

const SAVE_FILE = "user://mahjong_save.dat"

func save_game():
	var save_data = {
		"inventory": _serialize_inventory(),
		"game_state": _serialize_game_state()
	}
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Game saved")
		print("Save path:", ProjectSettings.globalize_path(SAVE_FILE))
		return true
	else:
		print("Saving error")
		return false

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE):
		print("Savefile not found")
		return false
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		_deserialize_inventory(save_data.get("inventory", {}))
		_deserialize_game_state(save_data.get("game_state", {}))
		
		print("Save loaded")
		return true
	else:
		print("Loading error")
		return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func delete_save():
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
		print("Saves deleted")

func _serialize_inventory() -> Dictionary:
	var inv = get_node_or_null("/root/Inventory")
	if not inv:
		return {}
	
	var spirits_data = []
	for spirit in inv.spirits:
		spirits_data.append(_serialize_item(spirit))
	
	var beers_data = []
	for beer in inv.beers:
		beers_data.append(_serialize_item(beer))
	
	return {
		"spirits": spirits_data,
		"beers": beers_data,
		"money": inv.money
	}

func _serialize_item(item: Item) -> Dictionary:
	var data = {
		"id": item.id,
		"name": item.name,
		"description": item.description,
		"rarity": item.rarity,
		"price": item.price,
		"type": item.type
	}
	
	if item is Spirit:
		data["effect_type"] = item.effect_type
		data["effect_value"] = item.effect_value
		data["condition"] = item.condition
		data["permanent"] = item.permanent
	elif item is Beer:
		data["round_effect"] = item.round_effect
		data["duration"] = item.duration
		data["bonus_value"] = item.bonus_value
	
	return data

func _serialize_game_state() -> Dictionary:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return {}
	
	return {
		"current_blind": gm.current_blind,
		"current_round": gm.current_round,
		"current_score": gm.current_score,
		"target_score": gm.target_score,
		"discards_left": gm.discards_left,
		"is_game_active": gm.is_game_active
	}

func _deserialize_inventory(data: Dictionary):
	var inv = get_node_or_null("/root/Inventory")
	if not inv:
		return
	
	inv.spirits.clear()
	inv.beers.clear()
	
	for spirit_data in data.get("spirits", []):
		var spirit = _deserialize_item(spirit_data)
		if spirit:
			inv.spirits.append(spirit)
	
	for beer_data in data.get("beers", []):
		var beer = _deserialize_item(beer_data)
		if beer:
			inv.beers.append(beer)
	
	inv.money = data.get("money", 10)
	inv.emit_signal("inventory_changed")
	inv.emit_signal("money_changed", inv.money)

func _deserialize_item(data: Dictionary):
	if data.get("type") == "spirit":
		var spirit = Spirit.new()
		spirit.id = data.get("id", "")
		spirit.name = data.get("name", "")
		spirit.description = data.get("description", "")
		spirit.rarity = data.get("rarity", "Historic")
		spirit.price = data.get("price", 0)
		spirit.type = "spirit"
		spirit.effect_type = data.get("effect_type", "")
		spirit.effect_value = data.get("effect_value", 0.0)
		spirit.condition = data.get("condition", "")
		spirit.permanent = data.get("permanent", true)
		return spirit
	elif data.get("type") == "beer":
		var beer = Beer.new()
		beer.id = data.get("id", "")
		beer.name = data.get("name", "")
		beer.description = data.get("description", "")
		beer.rarity = data.get("rarity", "Historic")
		beer.price = data.get("price", 0)
		beer.type = "beer"
		beer.round_effect = data.get("round_effect", "")
		beer.duration = data.get("duration", 1)
		beer.bonus_value = data.get("bonus_value", 0.0)
		return beer
	return null

func _deserialize_game_state(data: Dictionary):
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	
	gm.current_blind = data.get("current_blind", 0)
	gm.current_round = data.get("current_round", 0)
	gm.current_score = data.get("current_score", 0)
	gm.target_score = data.get("target_score", 1000)
	gm.discards_left = data.get("discards_left", 5)
	gm.is_game_active = data.get("is_game_active", false)
