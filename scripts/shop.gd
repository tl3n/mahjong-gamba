extends Control

@onready var shop_slots_container: HBoxContainer = $VBoxContainer/ShopSection/ShopSlotsContainer
@onready var reroll_button: Button = $VBoxContainer/ShopSection/RerollButton
@onready var start_blind_button: Button = $StartBlindButton
@onready var money_label: Label = $VBoxContainer/MoneyLabel
@onready var inventory_panel: Control = $VBoxContainer/InventoryPanel

var inventory_node = null
var shop_items: Array = []
var reroll_cost: int = 3
var reroll_count: int = 0

func _ready():
	inventory_node = Inventory
	if inventory_node == null:
		push_error("Inventory singleton not found in Autoload!")
		return

	inventory_node.connect("money_changed", Callable(self, "_on_money_changed"))
	reroll_button.connect("pressed", Callable(self, "_on_reroll_pressed"))
	start_blind_button.connect("pressed", Callable(self, "_on_start_blind_pressed"))
		
	var inv_scene = load("res://scenes/ui/Inventory.tscn")
	var inv_instance = inv_scene.instantiate()
	inventory_panel.add_child(inv_instance)

	var close_button = inv_instance.get_node_or_null("HBoxContainer/VBoxContainer/Buttons/CloseButton")
	if close_button:
		close_button.visible = false
		
	_generate_shop_items()
	_create_shop_slots()
	_update_reroll_button()

func _noop_setget(_v): 
	pass

func _generate_shop_items():
	shop_items.clear()
	for i in range(3):
		shop_items.append(ItemDatabase.get_random_item())

func _create_shop_slots():
	for child in shop_slots_container.get_children():
		child.queue_free()
	for i in range(3):
		var slot = _create_shop_slot(i)
		shop_slots_container.add_child(slot)

func _create_shop_slot(index: int) -> Control:
	var slot_container = VBoxContainer.new()
	slot_container.custom_minimum_size = Vector2(150, 200)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(100, 100)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if shop_items[index] and shop_items[index].icon:
		icon.texture = shop_items[index].icon
	slot_container.add_child(icon)

	var name_label = Label.new()
	name_label.text = shop_items[index].name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_container.add_child(name_label)

	var rarity_label = Label.new()
	rarity_label.text = shop_items[index].rarity
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override("font_color", _get_rarity_color(shop_items[index].rarity))
	slot_container.add_child(rarity_label)

	var buy_button = Button.new()
	buy_button.text = "Buy (%d¥)" % shop_items[index].price
	buy_button.connect("pressed", Callable(self, "_on_buy_pressed").bind(index))
	slot_container.add_child(buy_button)

	return slot_container

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"Historic": return Color(0.7, 0.7, 0.7)
		"Mythic": return Color(0.5, 0.5, 1.0)
		"Legendary": return Color(1.0, 0.8, 0.0)
		_: return Color.WHITE

func _on_buy_pressed(index: int):
	var item = shop_items[index]
	if item == null:
		return
	if inventory_node.money < item.price:
		print("Not enongh cash")
		return
	var can_add = false
	if item is Spirit and inventory_node.spirits.size() < inventory_node.max_spirits:
		can_add = true
	elif item is Beer and inventory_node.beers.size() < inventory_node.max_beers:
		can_add = true
	if not can_add:
		print("No slots available")
		return
	if inventory_node.spend_money(item.price):
		inventory_node.add_item(item)
		shop_items[index] = ItemDatabase.get_random_item()
		_refresh_shop_display()


func _on_reroll_pressed():
	if inventory_node.spend_money(reroll_cost):
		reroll_count += 1
		reroll_cost += 1
		_generate_shop_items()
		_refresh_shop_display()
		_update_reroll_button()

func _refresh_shop_display():
	_create_shop_slots()

func _create_item_display(item: Item) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(80, 100)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(60, 60)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item and item.icon:
		icon.texture = item.icon
	container.add_child(icon)
	var label = Label.new()
	label.text = item.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y = 30
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(label)
	return container

func _update_reroll_button():
	reroll_button.text = "Reroll (%d¥)" % reroll_cost

func _on_start_blind_pressed():
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		save_system.save_game()
	get_tree().change_scene_to_file("res://scenes/main/game_scene.tscn")
