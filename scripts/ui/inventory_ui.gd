# res://scripts/inventory_ui.gd
extends Control

# Секція духів
@onready var spirits_grid: GridContainer = $Window/HBoxContainer/VBoxContainer/SpiritsSection/SpiritsGrid
@onready var spirits_label: Label = $Window/HBoxContainer/VBoxContainer/SpiritsSection/Label

# Секція пива
@onready var beers_grid: GridContainer = $Window/HBoxContainer/VBoxContainer/BeersSection/BeersGrid
@onready var beers_label: Label = $Window/HBoxContainer/VBoxContainer/BeersSection/Label

# Деталі предмета
@onready var icon_rect: TextureRect = $Window/HBoxContainer/VBoxContainer2/ItemDetails/Icon
@onready var item_name_label: Label = $Window/HBoxContainer/VBoxContainer2/ItemDetails/ItemName
@onready var item_desc_label: Label = $Window/HBoxContainer/VBoxContainer2/ItemDetails/ItemDesc
@onready var money_label: Label = $Window/HBoxContainer/VBoxContainer2/MoneyLabel

# Кнопки
@onready var close_button: Button = $Window/HBoxContainer/VBoxContainer/Buttons/CloseButton
@onready var sell_button: Button = $Window/HBoxContainer/VBoxContainer/Buttons/Sell

# Слот-сцена
@export var slot_scene: PackedScene
var inventory_node: Node = null
var selected_item = null
var selected_type: String = ""  # "spirit" або "beer"

func _ready():
	# Знаходимо Inventory
	var inv_node = get_node_or_null("/root/Inventory")
	if inv_node and inv_node is Inventory:
		inventory_node = inv_node
	else:
		# Для тесту створимо тимчасовий Inventory
		inventory_node = Inventory.new()
		get_tree().get_root().add_child(inventory_node)
		inventory_node.name = "Inventory"

	inventory_node.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
	inventory_node.connect("money_changed", Callable(self, "_on_money_changed"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))
	sell_button.connect("pressed", Callable(self, "_on_sell_button_pressed"))

	_create_slots()
	_refresh_ui()
	_update_sell_button_state()

func _on_close_pressed():
	queue_free()

func _create_slots():
	if inventory_node == null:
		return

	# Створюємо слоти для духів
	_create_spirit_slots()
	
	# Створюємо слоти для пива
	_create_beer_slots()

func _create_spirit_slots():
	# Очищаємо старі слоти
	for child in spirits_grid.get_children():
		child.queue_free()

	# Встановлюємо горизонтальне розміщення
	spirits_grid.columns = inventory_node.max_spirits
	
	# Створюємо нові слоти для духів
	for i in inventory_node.max_spirits:
		var s = slot_scene.instantiate() as Button
		s.custom_minimum_size = Vector2(80, 80)
		s.index = i
		s.connect("pressed_slot", Callable(self, "_on_spirit_slot_pressed"))
		spirits_grid.add_child(s)

	spirits_label.text = "Духи (%d/%d)" % [inventory_node.spirits.size(), inventory_node.max_spirits]

func _create_beer_slots():
	# Очищаємо старі слоти
	for child in beers_grid.get_children():
		child.queue_free()

	# Встановлюємо горизонтальне розміщення
	beers_grid.columns = inventory_node.max_beers
	
	# Створюємо нові слоти для пива
	for i in inventory_node.max_beers:
		var s = slot_scene.instantiate() as Button
		s.custom_minimum_size = Vector2(80, 80)
		s.index = i
		s.connect("pressed_slot", Callable(self, "_on_beer_slot_pressed"))
		beers_grid.add_child(s)

	beers_label.text = "Пиво (%d/%d)" % [inventory_node.beers.size(), inventory_node.max_beers]

func _on_spirit_slot_pressed(slot_index):
	var it = inventory_node.get_spirit_at(slot_index)
	selected_item = it
	selected_type = "spirit"
	_update_item_details()
	_update_sell_button_state()

func _on_beer_slot_pressed(slot_index):
	var it = inventory_node.get_beer_at(slot_index)
	selected_item = it
	selected_type = "beer"
	_update_item_details()
	_update_sell_button_state()

func _update_item_details():
	if selected_item == null:
		icon_rect.texture = null
		item_name_label.text = "Порожній слот"
		item_desc_label.text = ""
		return
		
	if selected_item.icon:
		icon_rect.texture = selected_item.icon
	item_name_label.text = selected_item.name
	
	var details = selected_item.description + "\n\n"
	details += "Рідкість: " + selected_item.rarity + "\n"
	details += "Ціна покупки: " + str(selected_item.price) + " монет\n"
	details += "Ціна продажу: " + str(int(selected_item.price * 0.5)) + " монет\n\n"
	
	if selected_item is Spirit:
		details += "Тип: Дух (постійний ефект)\n"
		details += "Ефект: " + selected_item.effect_type + " +" + str(selected_item.effect_value)
	elif selected_item is Beer:
		details += "Тип: Пиво (одноразове)\n"
		details += "Ефект: " + selected_item.round_effect + "\n"
		details += "Тривалість: " + str(selected_item.duration) + " раунд"
	
	item_desc_label.text = details

func _on_inventory_changed():
	_refresh_ui()

func _on_money_changed(new_money):
	money_label.text = "Монети: %d¥" % new_money

func _on_sell_button_pressed():
	if selected_item == null:
		print("Немає вибраного предмета для продажу")
		return
	
	# Зберігаємо дані перед видаленням
	var item_name = selected_item.name
	var price_back = int(selected_item.price * 0.5)
	
	# Видаляємо предмет та додаємо гроші
	inventory_node.remove_item(selected_item)
	inventory_node.add_money(price_back)
	
	print("Продано %s за %d монет" % [item_name, price_back])
	
	# Скидаємо вибір
	selected_item = null
	selected_type = ""
	_refresh_ui()
	_update_sell_button_state()

func _update_sell_button_state():
	sell_button.disabled = (selected_item == null)
	if selected_item != null:
		var sell_price = int(selected_item.price * 0.5)
		sell_button.text = "Продати (%d¥)" % sell_price
	else:
		sell_button.text = "Продати"

func _refresh_ui():
	# Оновлюємо слоти духів
	var i = 0
	for child in spirits_grid.get_children():
		var item_ref = inventory_node.get_spirit_at(i)
		child.call("set_item", item_ref)
		i += 1
	
	# Оновлюємо слоти пива
	i = 0
	for child in beers_grid.get_children():
		var item_ref = inventory_node.get_beer_at(i)
		child.call("set_item", item_ref)
		i += 1
	
	# Оновлюємо підписи
	spirits_label.text = "Духи (%d/%d)" % [inventory_node.spirits.size(), inventory_node.max_spirits]
	beers_label.text = "Пиво (%d/%d)" % [inventory_node.beers.size(), inventory_node.max_beers]
	
	# Перевіряємо чи вибраний предмет ще існує
	if selected_type == "spirit" and not inventory_node.spirits.has(selected_item):
		selected_item = null
	elif selected_type == "beer" and not inventory_node.beers.has(selected_item):
		selected_item = null
		
	_update_item_details()
	_on_money_changed(inventory_node.money)
