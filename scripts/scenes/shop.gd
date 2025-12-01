extends Control

@onready var shop_slots_container: HBoxContainer = $UI/MainContent/LeftSection/ShopPanel/MarginContainer/VBoxContainer/ShopSection/ShopSlotsContainer
@onready var reroll_button: Button = $UI/TopBar/RerollButton
@onready var start_blind_button: Button = $UI/StartBlindButton
@onready var inventory_panel: Control = $UI/MainContent/RightSection/InventoryPanel
@onready var money_label: Label = $UI/TopBar/MoneyPanel/MoneyLabel

@onready var item_details_panel: PanelContainer = $UI/MainContent/LeftSection/ItemDetailsPanel
@onready var detail_name: Label = $UI/MainContent/LeftSection/ItemDetailsPanel/MarginContainer/VBoxContainer/Name
@onready var detail_rarity: Label = $UI/MainContent/LeftSection/ItemDetailsPanel/MarginContainer/VBoxContainer/Rarity
@onready var detail_desc: Label = $UI/MainContent/LeftSection/ItemDetailsPanel/MarginContainer/VBoxContainer/Description
@onready var detail_effect: Label = $UI/MainContent/LeftSection/ItemDetailsPanel/MarginContainer/VBoxContainer/EffectLabel

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
	
	var inv_scene = load("res://scenes/ui/inventory.tscn")
	var inv_instance = inv_scene.instantiate()
	inventory_panel.add_child(inv_instance)
	
	var close_button = inv_instance.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/Buttons/CloseButton")
	if close_button:
		close_button.visible = false
	
	if item_details_panel:
		item_details_panel.visible = false
	
	_load_or_generate_shop()
	
	if shop_items.size() == 0:
		push_warning("shop_items is empty after loading! Generating new items...")
		_generate_shop_items()
	
	_create_shop_slots()
	_update_reroll_button()
	_update_money_display()

func _load_or_generate_shop():
	var save_system = get_node_or_null("/root/SaveSystem")
	
	if save_system and save_system.has_save():
		var shop_data = save_system.load_shop_state()
		
		if shop_data.has("items") and shop_data["items"].size() > 0:
			shop_items = shop_data["items"]
			reroll_cost = shop_data.get("reroll_cost", 3)
			print("Shop loaded from save: %d items" % shop_items.size())
			return
	
	print("Generating new shop items")
	_generate_shop_items()

func _generate_shop_items():
	shop_items.clear()
	
	if inventory_node == null:
		inventory_node = Inventory 
		if inventory_node == null:
			push_error("Cannot generate items: Inventory node not found!")
			return

	var id_blacklist = {}
	for item in inventory_node.spirits:
		if item: id_blacklist[item.id] = true
	for item in inventory_node.beers:
		if item: id_blacklist[item.id] = true

	print("Generating 3 unique shop items...")
	
	while shop_items.size() < 3:
		var new_item = ItemDatabase.get_random_item()
		if new_item == null:
			continue
		
		if id_blacklist.has(new_item.id):
			print("Generated duplicate item, re-rolling... (%s)" % new_item.name)
			continue
		
		shop_items.append(new_item)
		id_blacklist[new_item.id] = true
		
	print("Generated %d unique shop items" % shop_items.size())

func _create_shop_slots():
	for child in shop_slots_container.get_children():
		child.queue_free()
	
	if shop_items.size() == 0:
		push_error("Cannot create shop slots: shop_items is empty!")
		return
	
	for i in range(shop_items.size()):
		var slot = _create_shop_slot(i)
		shop_slots_container.add_child(slot)

func _create_shop_slot(index: int) -> Control:
	var slot_container = VBoxContainer.new()
	slot_container.custom_minimum_size = Vector2(140, 180)
	slot_container.add_theme_constant_override("separation", 6) 

	if index >= shop_items.size() or shop_items[index] == null:
		slot_container.set_name("EmptySlot")
		var label = Label.new()
		label.text = "[ SOLD ]"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(140, 140)
		label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.55, 0.5))
		slot_container.add_child(label)
		return slot_container
		
	var item = shop_items[index]
	
	var select_button = Button.new()
	select_button.custom_minimum_size = Vector2(140, 140)
	select_button.connect("pressed", Callable(self, "_on_shop_item_selected").bind(index))
	
	# Style the button
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.18, 0.14, 1)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.35, 0.5, 0.4, 0.8)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.shadow_color = Color(0, 0, 0, 0.25)
	btn_style.shadow_size = 3
	select_button.add_theme_stylebox_override("normal", btn_style)
	
	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.18, 0.28, 0.2, 1)
	hover_style.border_color = Color(0.5, 0.7, 0.55, 1)
	select_button.add_theme_stylebox_override("hover", hover_style)
	
	var button_content = VBoxContainer.new()
	button_content.add_theme_constant_override("separation", 3) 
	button_content.alignment = BoxContainer.ALIGNMENT_CENTER
	select_button.add_child(button_content)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 56) 
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item.icon:
		icon.texture = item.icon
	button_content.add_child(icon)
	
	var name_label = Label.new()
	name_label.text = item.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(130, 32) 
	button_content.add_child(name_label)
	
	var rarity_label = Label.new()
	rarity_label.text = item.rarity
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override("font_color", _get_rarity_color(item.rarity))
	rarity_label.add_theme_font_size_override("font_size", 10)
	button_content.add_child(rarity_label)
	
	slot_container.add_child(select_button)
	
	var buy_button = Button.new()
	buy_button.text = "Buy (%d¥)" % item.price
	buy_button.custom_minimum_size = Vector2(0, 30)
	buy_button.connect("pressed", Callable(self, "_on_buy_pressed").bind(index))
	
	var buy_style = StyleBoxFlat.new()
	buy_style.bg_color = Color(0.2, 0.32, 0.22, 1)
	buy_style.border_width_left = 2
	buy_style.border_width_top = 2
	buy_style.border_width_right = 2
	buy_style.border_width_bottom = 2
	buy_style.border_color = Color(0.5, 0.7, 0.5, 0.9)
	buy_style.corner_radius_top_left = 6
	buy_style.corner_radius_top_right = 6
	buy_style.corner_radius_bottom_left = 6
	buy_style.corner_radius_bottom_right = 6
	buy_button.add_theme_stylebox_override("normal", buy_style)
	buy_button.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	buy_button.add_theme_font_size_override("font_size", 12)
	slot_container.add_child(buy_button)
	
	return slot_container

func _on_shop_item_selected(index: int):
	if index >= shop_items.size() or shop_items[index] == null:
		return
	
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
			effect_text += "Effect: %s\n" % item.blind_effect
			effect_text += "Duration: %d round(s)" % item.duration
		
		effect_text += "\n\nPrice: %d¥" % item.price
		detail_effect.text = effect_text

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"Historic", "Історична":
			return Color(0.7, 0.7, 0.7)
		"Mythic", "Міфічна":
			return Color(0.5, 0.5, 1.0)
		"Legendary", "Легендарна":
			return Color(1.0, 0.8, 0.0)
		_:
			return Color.WHITE

func _on_buy_pressed(index: int):
	if index >= shop_items.size() or shop_items[index] == null:
		return
		
	var item = shop_items[index]
	
	if inventory_node.money < item.price:
		print("Not enough cash")
		return
	
	# Check if we can add the item to inventory
	var can_add = false
	if item is Spirit and inventory_node.spirits.size() < inventory_node.max_spirits:
		can_add = true
	elif item is Beer and inventory_node.beers.size() < inventory_node.max_beers:
		can_add = true
	
	if not can_add:
		print("No slots available for this item type")
		return
	
	if inventory_node.spend_money(item.price):
		var added = inventory_node.add_item(item)
		if added:
			print("Purchased: %s" % item.name)
		else:
			print("Failed to add item to inventory: %s" % item.name)
			# Refund the money if item couldn't be added
			inventory_node.add_money(item.price)
			return
		
		shop_items[index] = null
		_refresh_shop_display()
		_save_shop_state()
		
		if selected_shop_index == index:
			if item_details_panel:
				item_details_panel.visible = false
			selected_shop_item = null
			selected_shop_index = -1

func _on_reroll_pressed():
	if inventory_node.spend_money(reroll_cost):
		print("Reroll shop")
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
		print("Not enough money for reroll")

func _refresh_shop_display():
	_create_shop_slots()

func _update_reroll_button():
	reroll_button.text = "Reroll (%d¥)" % reroll_cost

func _on_money_changed(_new_money):
	_update_money_display()

func _update_money_display():
	if money_label and inventory_node:
		money_label.text = "💰 %d¥" % inventory_node.money

func _save_shop_state():
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		save_system.save_shop_state(shop_items, reroll_cost)
		print("Shop state saved")

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
