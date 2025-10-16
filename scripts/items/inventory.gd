extends Node
class_name Inventory  # робить цей клас глобально доступним як Inventory

signal inventory_changed
signal money_changed(new_money)

var items: Array = []         # масив предметів
var max_size: int = 8       # кількість слотів
var money: int = 10           # стартова кількість монет

func _ready():
	# Тільки для тестування при порожньому інвентарі
	if items.is_empty():  # <-- заміна empty() на is_empty()
		var s1 = Spirit.new()
		s1.id = "spirit_fire"
		s1.name = "Дух Вогню"
		s1.description = "Додає +4 до масті Вогню"
		s1.price = 8
		s1.rarity = "Міфічна"
		s1.effect_type = "mansion_multiplier"
		s1.effect_value = 4.0
		items.append(s1)

		var b1 = Beer.new()
		b1.id = "beer_x1"
		b1.name = "Пиво: Додатковий добір"
		b1.description = "Дозволяє тягнути додатковий тайл цього раунду."
		b1.price = 3
		b1.rarity = "Історична"
		b1.round_effect = "extra_draw"
		b1.duration = 1
		items.append(b1)

	emit_signal("inventory_changed")



func add_item(item):
	if items.size() < max_size:
		items.append(item)
		emit_signal("inventory_changed")
	else:
		print("Інвентар переповнений!")

func remove_item(item):
	if item in items:
		items.erase(item)
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
