extends Node
class_name Inventory

signal inventory_changed
signal money_changed(new_money)

var spirits: Array = []       # масив духів
var beers: Array = []         # масив пива
var max_spirits: int = 5      # максимум духів
var max_beers: int = 2        # максимум пива
var money: int = 10           # стартова кількість монет

func _ready():
	if spirits.is_empty() and beers.is_empty():
		var s1 = Spirit.new()
		s1.id = "spirit_fire"
		s1.name = "Дух Вогню"
		s1.description = "Додає +4 до масті Вогню"
		s1.price = 8
		s1.rarity = "Міфічна"
		s1.type = "дух"
		s1.effect_type = "mansion_multiplier"
		s1.effect_value = 4.0
		spirits.append(s1)

		var b1 = Beer.new()
		b1.id = "beer_x1"
		b1.name = "Пиво: Додатковий добір"
		b1.description = "Дозволяє тягнути додатковий тайл цього раунду."
		b1.price = 3
		b1.rarity = "Історична"
		b1.type = "пиво"
		b1.round_effect = "extra_draw"
		b1.duration = 1
		beers.append(b1)

		var s2 = Spirit.new()
		s2.id = "spirit_wind"
		s2.name = "Дух Вітру"
		s2.description = "Додає +2 до всіх мастей"
		s2.price = 10
		s2.rarity = "Легендарна"
		s2.type = "дух"
		s2.effect_type = "all_mansion_bonus"
		s2.effect_value = 2.0
		spirits.append(s2)

	emit_signal("inventory_changed")

func add_item(item):
	if item is Spirit:
		if spirits.size() < max_spirits:
			spirits.append(item)
			emit_signal("inventory_changed")
			return true
		else:
			print("Слоти для духів переповнені!")
			return false
	elif item is Beer:
		if beers.size() < max_beers:
			beers.append(item)
			emit_signal("inventory_changed")
			return true
		else:
			print("Слоти для пива переповнені!")
			return false
	return false

func remove_item(item):
	if item in spirits:
		spirits.erase(item)
		emit_signal("inventory_changed")
	elif item in beers:
		beers.erase(item)
		emit_signal("inventory_changed")

func add_money(amount: int):
	money += amount
	emit_signal("money_changed", money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		emit_signal("money_changed", money)
		return true
	else:
		print("Недостатньо монет!")
		return false

func get_spirit_at(index: int):
	if index < spirits.size():
		return spirits[index]
	return null

func get_beer_at(index: int):
	if index < beers.size():
		return beers[index]
	return null
