extends PanelContainer

@onready var spirits_grid: GridContainer = $MarginContainer/HBoxContainer/VBoxContainer/SpiritsSection/SpiritsGrid
@onready var spirits_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/SpiritsSection/Label
@onready var beers_grid: GridContainer = $MarginContainer/HBoxContainer/VBoxContainer/BeersSection/BeersGrid
@onready var beers_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/BeersSection/Label
@onready var icon_rect: TextureRect = $MarginContainer/HBoxContainer/VBoxContainer2/DetailsPanel/ItemDetails/Icon
@onready var item_name_label: Label = $MarginContainer/HBoxContainer/VBoxContainer2/DetailsPanel/ItemDetails/ItemName
@onready var item_desc_label: Label = $MarginContainer/HBoxContainer/VBoxContainer2/DetailsPanel/ItemDetails/ItemDesc
@onready var money_label: Label = $MarginContainer/HBoxContainer/VBoxContainer2/MoneyLabel
@onready var close_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/Buttons/CloseButton
@onready var sell_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/Buttons/Sell

@export var slot_scene: PackedScene
var inventory_node = null
var selected_item = null
var selected_type: String = ""

func _ready():
	inventory_node = Inventory
	if inventory_node == null:
		push_error("Inventory singleton not found!")
		return

	inventory_node.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
	inventory_node.connect("money_changed", Callable(self, "_on_money_changed"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))
	sell_button.connect("pressed", Callable(self, "_on_sell_button_pressed"))

	_create_slots()
	_refresh_ui()
	_update_money_display()
	_update_sell_button_state()

func _on_close_pressed():
	queue_free()

func _create_slots():
	if inventory_node == null:
		return
	_create_spirit_slots()
	_create_beer_slots()

func _create_spirit_slots():
	for child in spirits_grid.get_children():
		child.queue_free()
	spirits_grid.columns = inventory_node.max_spirits
	for i in range(inventory_node.max_spirits):
		var s = slot_scene.instantiate()
		s.custom_minimum_size = Vector2(80, 80)
		if s.has_method("set_index"):
			s.set_index(i)
		else:
			s.index = i
		s.connect("pressed_slot", Callable(self, "_on_spirit_slot_pressed"))
		spirits_grid.add_child(s)
	spirits_label.text = "Spirits (%d/%d)" % [inventory_node.spirits.size(), inventory_node.max_spirits]

func _create_beer_slots():
	for child in beers_grid.get_children():
		child.queue_free()
	beers_grid.columns = inventory_node.max_beers
	for i in range(inventory_node.max_beers):
		var s = slot_scene.instantiate()
		s.custom_minimum_size = Vector2(80, 80)
		if s.has_method("set_index"):
			s.set_index(i)
		else:
			s.index = i
		s.connect("pressed_slot", Callable(self, "_on_beer_slot_pressed"))
		beers_grid.add_child(s)
	beers_label.text = "Beers (%d/%d)" % [inventory_node.beers.size(), inventory_node.max_beers]

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
		item_name_label.text = "Empty Slot"
		item_desc_label.text = ""
		return
	if selected_item.icon:
		icon_rect.texture = selected_item.icon
	item_name_label.text = selected_item.name
	var details = "%s\n\nRarity: %s\nPurchase Price: %d coins\nSell Price: %d coins\n\n" % [
		selected_item.description,
		selected_item.rarity,
		selected_item.price,
		int(selected_item.price * 0.5)
	]
	if selected_item is Spirit:
		details += "Type: Spirit (Permanent Effect)\nEffect: %s +%s" % [selected_item.effect_type, str(selected_item.effect_value)]
	elif selected_item is Beer:
		details += "Type: Beer (One-time)\nEffect: %s\nDuration: %d round(s)" % [selected_item.blind_effect, selected_item.duration]
	item_desc_label.text = details

func _on_inventory_changed():
	_refresh_ui()

func _on_money_changed(_new_money):
	_update_money_display()

func _on_sell_button_pressed():
	if selected_item == null:
		print("No item selected for selling")
		return
	var item_name = selected_item.name
	var price_back = int(selected_item.price * 0.5)
	inventory_node.remove_item(selected_item)
	inventory_node.add_money(price_back)
	print("Sold %s for %d coins" % [item_name, price_back])
	selected_item = null
	selected_type = ""
	_refresh_ui()
	_update_sell_button_state()

func _update_sell_button_state():
	sell_button.disabled = (selected_item == null)
	if selected_item != null:
		sell_button.text = "Sell (%d¥)" % int(selected_item.price * 0.5)
	else:
		sell_button.text = "Sell"

func _refresh_ui():
	var i = 0
	for child in spirits_grid.get_children():
		var item_ref = inventory_node.get_spirit_at(i)
		if child.has_method("set_item"):
			child.call("set_item", item_ref)
		i += 1
	i = 0
	for child in beers_grid.get_children():
		var item_ref = inventory_node.get_beer_at(i)
		if child.has_method("set_item"):
			child.call("set_item", item_ref)
		i += 1
	spirits_label.text = "Spirits (%d/%d)" % [inventory_node.spirits.size(), inventory_node.max_spirits]
	beers_label.text = "Beers (%d/%d)" % [inventory_node.beers.size(), inventory_node.max_beers]
	if selected_type == "spirit" and not inventory_node.spirits.has(selected_item):
		selected_item = null
	elif selected_type == "beer" and not inventory_node.beers.has(selected_item):
		selected_item = null
	_update_item_details()
	_update_money_display()

func _update_money_display():
	money_label.text = "Coins: %d¥" % inventory_node.money
