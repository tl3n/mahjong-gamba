extends Control

@onready var shop_slots_container: HBoxContainer = $VBoxContainer/ShopSection/ShopSlotsContainer
@onready var reroll_button: Button = $RerollButton
@onready var start_blind_button: Button = $StartBlindButton
@onready var inventory_panel: Control = $VBoxContainer/InventoryPanel

@onready var item_details_panel: Panel = $ItemDetailsPanel
@onready var detail_name: Label = $ItemDetailsPanel/VBoxContainer/Name
@onready var detail_rarity: Label = $ItemDetailsPanel/VBoxContainer/Rarity
@onready var detail_desc: Label = $ItemDetailsPanel/VBoxContainer/Description
@onready var detail_effect: Label = $ItemDetailsPanel/VBoxContainer/EffectLabel

var inventory_node = null
var shop_items: Array = []
var reroll_cost: int = 3
var selected_shop_item = null
var selected_shop_index: int = -1

func _ready():
	inventory_node = Inventory
	if inventory_node == null:
		push_error("Inventory singleton not found!")
		return

	inventory_node.connect("money_changed", Callable(self, "_on_money_changed"))
	reroll_button.connect("pressed", Callable(self, "_on_reroll_pressed"))
	start_blind_button.connect("pressed", Callable(self, "_on_start_blind_pressed"))
	
	# Завантажуємо інвентар UI
	var inv_scene = load("res://scenes/ui/Inventory.tscn")
	var inv_instance = inv_scene.instantiate()
	inventory_panel.add_child(inv_instance)
	
	var close_button = inv_instance.get_node_or_null("HBoxContainer/VBoxContainer/Buttons/CloseButton")
	if close_button:
		close_button.visible = false
	
	# Ховаємо панель деталей спочатку
	if item_details_panel:
		item_details_panel.visible = false
	
	# Завантажуємо стан магазину або генеруємо новий
	_load_or_generate_shop()
	_create_shop_slots()
	_update_reroll_button()

func _load_or_generate_shop():
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system and save_system.has_save():
		var shop_data = save_system.load_shop_state()
		if shop_data.size() > 0:
			shop_items = shop_data.get("items", [])
			reroll_cost = shop_data.get("reroll_cost", 3)
			print("Shop loaded from save")
			return
	
	_generate_shop_items()

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
	slot_container.custom_minimum_size = Vector2(180, 250)
	
	var select_button = Button.new()
	select_button.custom_minimum_size = Vector2(180, 200)
	select_button.connect("pressed", Callable(self, "_on_shop_item_selected").bind(index))
	
	var button_content = VBoxContainer.new()
	select_button.add_child(button_content)
	
	# Іконка
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(120, 120)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if shop_items[index] and shop_items[index].icon:
		icon.texture = shop_items[index].icon
	button_content.add_child(icon)
	
	# Назва
	var name_label = Label.new()
	name_label.text = shop_items[index].name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	button_content.add_child(name_label)
	
	# Рідкість
	var rarity_label = Label.new()
	rarity_label.text = shop_items[index].rarity
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override("font_color", _get_rarity_color(shop_items[index].rarity))
	button_content.add_child(rarity_label)
	
	slot_container.add_child(select_button)
	
	# Кнопка купівлі
	var buy_button = Button.new()
	buy_button.text = "Buy (%d¥)" % shop_items[index].price
	buy_button.connect("pressed", Callable(self, "_on_buy_pressed").bind(index))
	slot_container.add_child(buy_button)
	
	return slot_container

func _on_shop_item_selected(index: int):
	selected_shop_index = index
	selected_shop_item = shop_items[index]
	_show_item_details(selected_shop_item)

func _show_item_details(item):
	if item == null or item_details_panel == null:
		return
	
	item_details_panel.visible = true
	
	if detail_name:
		detail_name.text = item.name
	
	if detail_rarity:
		detail_rarity.text = item.rarity
		detail_rarity.add_theme_color_override("font_color", _get_rarity_color(item.rarity))
	
	if detail_desc:
		detail_desc.text = item.description
	
	if detail_effect:
		var effect_text = "\n"
		if item is Spirit:
			effect_text += "Type: Spirit (Permanent)\n"
			effect_text += "Effect: %s" % item.effect_type
			if item.effect_value > 0:
				effect_text += " +%.1f" % item.effect_value
			if item.condition != "":
				effect_text += "\nCondition: %s" % item.condition
		elif item is Beer:
			effect_text += "Type: Beer (One-time)\n"
			effect_text += "Effect: %s\n" % item.round_effect
			effect_text += "Duration: %d round(s)" % item.duration
		
		effect_text += "\n\nPrice: %d¥" % item.price
		detail_effect.text = effect_text

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"Historic":
			return Color(0.7, 0.7, 0.7)
		"Mythic":
			return Color(0.5, 0.5, 1.0)
		"Legendary":
			return Color(1.0, 0.8, 0.0)
		_:
			return Color.WHITE

func _on_buy_pressed(index: int):
	var item = shop_items[index]
	if item == null:
		return
	
	if inventory_node.money < item.price:
		print("Not enough cash")
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
		print("Purchased: %s" % item.name)
		
		shop_items[index] = ItemDatabase.get_random_item()
		_refresh_shop_display()
		_save_shop_state()
		
		if selected_shop_index == index:
			selected_shop_item = shop_items[index]
			_show_item_details(selected_shop_item)

func _on_reroll_pressed():
	if inventory_node.spend_money(reroll_cost):
		print("🔄 Reroll shop")
		reroll_cost += 1
		_generate_shop_items()
		_refresh_shop_display()
		_update_reroll_button()
		_save_shop_state()
		
		if item_details_panel:
			item_details_panel.visible = false
		selected_shop_item = null
		selected_shop_index = -1
	else:
		print("❌ Not enough money for reroll")

func _refresh_shop_display():
	_create_shop_slots()

func _update_reroll_button():
	reroll_button.text = "Reroll (%d¥)" % reroll_cost

func _save_shop_state():
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		save_system.save_shop_state(shop_items, reroll_cost)

func _on_start_blind_pressed():
	_save_shop_state()
	
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		save_system.save_game()
	
	get_tree().change_scene_to_file("res://scenes/main/game_scene.tscn")

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if item_details_panel and item_details_panel.visible:
			var panel_rect = item_details_panel.get_global_rect()
			if not panel_rect.has_point(event.position):
				item_details_panel.visible = false
				selected_shop_item = null
				selected_shop_index = -1
