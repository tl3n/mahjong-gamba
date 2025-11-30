extends Node
class_name Inventory1

signal inventory_changed
signal money_changed(new_money: int)

@export var max_spirits: int = 5
@export var max_beers: int = 2
@export var starting_money: int = 10

var spirits: Array[Resource] = []
var beers: Array[Resource] = []
var money: int = 0

func _ready() -> void:
	if money == 0:
		money = starting_money

func add_item(item: Resource) -> bool:
	if item is Spirit:
		return add_spirit(item)
	elif item is Beer:
		return add_beer(item)
	return false

func add_spirit(spirit: Spirit) -> bool:
	if spirit == null:
		return false
	if spirits.size() >= max_spirits:
		return false
	spirits.append(spirit)
	emit_signal("inventory_changed")
	return true

func add_beer(beer: Beer) -> bool:
	if beer == null:
		return false
	if beers.size() >= max_beers:
		return false
	beers.append(beer)
	emit_signal("inventory_changed")
	return true

func remove_item(item: Resource) -> void:
	if item == null:
		return
	if item in spirits:
		spirits.erase(item)
		emit_signal("inventory_changed")
		return
	if item in beers:
		beers.erase(item)
		emit_signal("inventory_changed")
		return

func sell_item(item: Resource) -> int:
	if item == null:
		return 0
	var sell_price := int(item.price * 0.5)
	remove_item(item)
	add_money(sell_price)
	return sell_price

func add_money(amount: int) -> void:
	money += amount
	emit_signal("money_changed", money)

func spend_money(amount: int) -> bool:
	if amount <= 0:
		return true
	if money >= amount:
		money -= amount
		emit_signal("money_changed", money)
		return true
	return false

func get_spirit_at(index: int) -> Spirit:
	if index < 0 or index >= spirits.size():
		return null
	return spirits[index]

func get_beer_at(index: int) -> Beer:
	if index < 0 or index >= beers.size():
		return null
	return beers[index]

func to_dict() -> Dictionary:
	var sarr := []
	for s in spirits:
		sarr.append(_item_to_dict(s))
	var barr := []
	for b in beers:
		barr.append(_item_to_dict(b))
	return {
		"spirits": sarr,
		"beers": barr,
		"money": money
	}

func from_dict(data: Dictionary) -> void:
	spirits.clear()
	beers.clear()
	for sdata in data.get("spirits", []):
		var s = ItemDatabase.create_spirit_from_data(sdata)
		if s:
			spirits.append(s)
	for bdata in data.get("beers", []):
		var b = ItemDatabase.create_beer_from_data(bdata)
		if b:
			beers.append(b)
	money = data.get("money", money)
	emit_signal("inventory_changed")
	emit_signal("money_changed", money)

func _item_to_dict(item: Resource) -> Dictionary:
	if item == null:
		return {}
	var d := {
		"id": item.id,
		"name": item.name,
		"description": item.description,
		"rarity": item.rarity,
		"price": item.price,
		"type": item.type
	}
	if item is Spirit:
		d["effect_type"] = item.effect_type
		d["effect_value"] = item.effect_value
		d["condition"] = item.condition
		d["permanent"] = item.permanent
	elif item is Beer:
		d["round_effect"] = item.round_effect
		d["duration"] = item.duration
		d["bonus_value"] = item.bonus_value
	return d
