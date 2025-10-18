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
	# Тестові предмети більше не створюються автоматично
	# Вони будуть завантажені через SaveSystem або створені при новій грі
	pass

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
