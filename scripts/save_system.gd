extends Node

const SAVE_FILE = "user://mahjong_save.dat"

var cached_shop_items: Array = []
var cached_reroll_cost: int = 3

func save_game():
	print("\n=== SAVING GAME ===")
	
	var save_data = {
		"inventory": _serialize_inventory(),
		"game_state": _serialize_game_state(),
		"shop_state": _serialize_shop_state()
	}
	
	print("Inventory data: %d spirits, %d beers, %d money" % [
		save_data["inventory"]["spirits"].size(),
		save_data["inventory"]["beers"].size(),
		save_data["inventory"]["money"]
	])
	print("Shop data: %d items, reroll cost: %d" % [
		save_data["shop_state"]["items"].size(),
		save_data["shop_state"]["reroll_cost"]
	])
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Game saved successfully")
		print("Save path:", ProjectSettings.globalize_path(SAVE_FILE))
		return true
	else:
		print("Saving error!")
		return false

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE):
		print("Savefile not found")
		return false
	
	print("\n === LOADING GAME ===")
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		if save_data.has("inventory"):
			var inv_data = save_data["inventory"]
			print("Loading inventory: %d spirits, %d beers, %d money" % [
				inv_data.get("spirits", []).size(),
				inv_data.get("beers", []).size(),
				inv_data.get("money", 0)
			])
		
		_deserialize_inventory(save_data.get("inventory", {}))
		_deserialize_game_state(save_data.get("game_state", {}))
		_deserialize_shop_state(save_data.get("shop_state", {}))
		
		print("Save loaded successfully")
		return true
	else:
		print("Loading error!")
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
		print(" Inventory node not found during serialization!")
		return {}
	
	var spirits_data = []
	for spirit in inv.spirits:
		var serialized = _serialize_item(spirit)
		spirits_data.append(serialized)
		print("Serializing spirit: %s (type: %s)" % [spirit.name, serialized.get("type", "MISSING")])
	
	var beers_data = []
	for beer in inv.beers:
		var serialized = _serialize_item(beer)
		beers_data.append(serialized)
		print("Serializing beer: %s (type: %s)" % [beer.name, serialized.get("type", "MISSING")])
	
	return {
		"spirits": spirits_data,
		"beers": beers_data,
		"money": inv.money
	}

func _serialize_item(item: Item) -> Dictionary:
	if item == null:
		return {}
	
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
		
		if data["type"] == "" or data["type"] == "дух":
			data["type"] = "spirit"
	
	elif item is Beer:
		data["blind_effect"] = item.blind_effect
		data["duration"] = item.duration
		data["bonus_value"] = item.bonus_value
		
		if data["type"] == "" or data["type"] == "пиво":
			data["type"] = "beer"
	
	return data

func _deserialize_inventory(data: Dictionary):
	var inv = get_node_or_null("/root/Inventory")
	if not inv:
		print("Inventory node not found during deserialization!")
		return
	
	print("Clearing inventory...")
	inv.spirits.clear()
	inv.beers.clear()
	
	print("Restoring spirits...")
	for spirit_data in data.get("spirits", []):
		var spirit = _deserialize_item(spirit_data)
		if spirit:
			inv.spirits.append(spirit)
			print("Restored spirit: %s" % spirit.name)
		else:
			print("Failed to restore spirit from data: %s" % spirit_data)
	
	print("Restoring beers...")
	for beer_data in data.get("beers", []):
		var beer = _deserialize_item(beer_data)
		if beer:
			inv.beers.append(beer)
			print("Restored beer: %s" % beer.name)
		else:
			print("Failed to restore beer from data: %s" % beer_data)
	
	inv.money = data.get("money", 10)
	print("Money restored: %d" % inv.money)
	
	inv.emit_signal("inventory_changed")
	inv.emit_signal("money_changed", inv.money)

func _deserialize_item(data: Dictionary):
	if data.is_empty():
		return null
	
	var item_type = data.get("type", "")
	
	# Spirit
	if item_type == "spirit" or item_type == "дух":
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
	
	# Beer
	elif item_type == "beer" or item_type == "пиво":
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
	
	print(" Unknown item type: '%s' for item: %s" % [item_type, data.get("name", "UNNAMED")])
	return null

func save_shop_state(items: Array, reroll_cost: int):
	print("\n Saving shop state...")
	cached_shop_items = items.duplicate()
	cached_reroll_cost = reroll_cost
	print("  Items cached: %d" % cached_shop_items.size())
	print("  Reroll cost: %d" % cached_reroll_cost)
	save_game()

func _serialize_shop_state() -> Dictionary:
	var items_data = []
	for item in cached_shop_items:
		if item:
			items_data.append(_serialize_item(item))
	
	return {
		"items": items_data,
		"reroll_cost": cached_reroll_cost
	}

func _deserialize_shop_state(data: Dictionary):
	print("  Restoring shop state...")
	cached_shop_items.clear()
	
	for item_data in data.get("items", []):
		var item = _deserialize_item(item_data)
		if item:
			cached_shop_items.append(item)
	
	cached_reroll_cost = data.get("reroll_cost", 3)
	print("    Shop items: %d" % cached_shop_items.size())
	print("    Reroll cost: %d" % cached_reroll_cost)

func load_shop_state() -> Dictionary:
	return {
		"items": cached_shop_items.duplicate(),
		"reroll_cost": cached_reroll_cost
	}
# TODO: After making the main gameplay, insert the data gained from there here in order to save progress
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
