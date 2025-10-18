# res://scripts/shop.gd
extends Control

# UI елементи
@onready var shop_slots_container: HBoxContainer = $Window/VBoxContainer/ShopSection/ShopSlotsContainer
@onready var player_items_container: HBoxContainer = $Window/VBoxContainer/PlayerItemsSection/PlayerItemsContainer
@onready var reroll_button: Button = $Window/VBoxContainer/ShopSection/RerollButton
@onready var start_blind_button: Button = $Window/VBoxContainer/StartBlindButton
@onready var money_label: Label = $Window/VBoxContainer/MoneyLabel

# Сцени
@export var shop_slot_scene: PackedScene
@export var player_item_display_scene: PackedScene

# Дані
var inventory_node: Inventory = null
var shop_items: Array = []  # 3 предмети в магазині
var reroll_cost: int = 3
var reroll_count: int = 0

func _ready():
	# Знаходимо Inventory
	inventory_node = get_node_or_null("/root/Inventory")
	if inventory_node == null:
		inventory_node = Inventory.new()
		get_tree().get_root().add_child(inventory_node)
		inventory_node.name = "Inventory"
	
	# Підключаємо сигнали
	inventory_node.connect("money_changed", Callable(self, "_on_money_changed"))
	reroll_button.connect("pressed", Callable(self, "_on_reroll_pressed"))
	start_blind_button.connect("pressed", Callable(self, "_on_start_blind_pressed"))
	
	# Ініціалізація
	_generate_shop_items()
	_create_shop_slots()
	_update_player_items_display()
	_update_money_display()
	_update_reroll_button()

func _generate_shop_items():
	shop_items.clear()
	for i in range(3):
		var item = ItemDatabase.get_random_item()
		shop_items.append(item)

func _create_shop_slots():
	# Очищаємо старі слоти
	for child in shop_slots_container.get_children():
		child.queue_free()
	
	# Створюємо 3 слоти магазину
	for i in range(3):
		var slot = _create_shop_slot(i)
		shop_slots_container.add_child(slot)

func _create_shop_slot(index: int) -> Control:
	# Створюємо контейнер для слота
	var slot_container = VBoxContainer.new()
	slot_container.custom_minimum_size = Vector2(150, 200)
	
	# Іконка (поки що заглушка)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(100, 100)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if shop_items[index].icon:
		icon.texture = shop_items[index].icon
	slot_container.add_child(icon)
	
	# Назва предмета
	var name_label = Label.new()
	name_label.text = shop_items[index].name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_container.add_child(name_label)
	
	# Рідкість
	var rarity_label = Label.new()
	rarity_label.text = shop_items[index].rarity
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override("font_color", _get_rarity_color(shop_items[index].rarity))
	slot_container.add_child(rarity_label)
	
	# Кнопка купівлі
	var buy_button = Button.new()
	buy_button.text = "Купити (%d¥)" % shop_items[index].price
	buy_button.connect("pressed", Callable(self, "_on_buy_pressed").bind(index))
	slot_container.add_child(buy_button)
	
	return slot_container

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"Історична":
			return Color(0.7, 0.7, 0.7)  # Сірий
		"Міфічна":
			return Color(0.5, 0.5, 1.0)  # Синій
		"Легендарна":
			return Color(1.0, 0.8, 0.0)  # Золотий
		_:
			return Color.WHITE

func _on_buy_pressed(index: int):
	var item = shop_items[index]
	
	# Перевірка чи вистачає грошей
	if inventory_node.money < item.price:
		print("Недостатньо монет!")
		return
	
	# Перевірка чи є місце
	var can_add = false
	if item is Spirit and inventory_node.spirits.size() < inventory_node.max_spirits:
		can_add = true
	elif item is Beer and inventory_node.beers.size() < inventory_node.max_beers:
		can_add = true
	
	if not can_add:
		print("Немає вільного місця в інвентарі!")
		return
	
	# Купуємо предмет
	if inventory_node.spend_money(item.price):
		inventory_node.add_item(item)
		shop_items[index] = ItemDatabase.get_random_item()  # Новий предмет замість купленого
		_refresh_shop_display()
		_update_player_items_display()

func _on_reroll_pressed():
	if inventory_node.spend_money(reroll_cost):
		reroll_count += 1
		reroll_cost += 1
		_generate_shop_items()
		_refresh_shop_display()
		_update_reroll_button()

func _refresh_shop_display():
	_create_shop_slots()

func _update_player_items_display():
	# Очищаємо
	for child in player_items_container.get_children():
		child.queue_free()
	
	# Додаємо духів
	for spirit in inventory_node.spirits:
		var display = _create_item_display(spirit)
		player_items_container.add_child(display)
	
	# Додаємо пиво
	for beer in inventory_node.beers:
		var display = _create_item_display(beer)
		player_items_container.add_child(display)

func _create_item_display(item: Item) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(80, 100)
	
	# Іконка
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(60, 60)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item.icon:
		icon.texture = item.icon
	container.add_child(icon)
	
	# Назва
	var label = Label.new()
	label.text = item.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y = 30
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(label)
	
	return container

func _update_money_display():
	money_label.text = "Монети: %d¥" % inventory_node.money

func _update_reroll_button():
	reroll_button.text = "Reroll (%d¥)" % reroll_cost

func _on_money_changed(_new_money):
	_update_money_display()

func _on_start_blind_pressed():
	# Зберігаємо гру перед початком блайнда
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		save_system.save_game()
	
	# Переходимо до гри
	get_tree().change_scene_to_file("res://scenes/main/game_scene.tscn")
