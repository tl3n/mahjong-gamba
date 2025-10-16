# res://scripts/inventory_ui.gd
extends Control
@onready var slots_grid: GridContainer = $Window/HBoxContainer/VBoxContainer/SlotsGrid
@onready var icon_rect: TextureRect = $Window/HBoxContainer/VBoxContainer2/ItemDetails/Icon
@onready var item_name_label: Label = $Window/HBoxContainer/VBoxContainer2/ItemDetails/ItemName
@onready var item_desc_label: Label = $Window/HBoxContainer/VBoxContainer2/ItemDetails/ItemDesc
@onready var money_label: Label = $Window/HBoxContainer/VBoxContainer2/MoneyLabel
@onready var close_button: Button = $Window/HBoxContainer/VBoxContainer/Buttons/CloseButton 

# Слот-сцена (потрібно створити окремий сцена-файл ItemSlot.tscn)
@export var slot_scene: PackedScene
var inventory_node: Node = null
var selected_item = null

func _ready():
	# Спробуємо знайти Inventory у дереві
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

	_create_slots()
	_refresh_ui()

func _on_close_pressed():
	queue_free()  

func _create_slots():
	if inventory_node == null:
		return

	# Видаляємо старі слоти
	for child in slots_grid.get_children():
		child.queue_free()

	# Створюємо нові слоти
	for i in inventory_node.max_size:
		var s = slot_scene.instantiate() as Button
		s.index = i
		s.connect("pressed_slot", Callable(self, "_on_slot_pressed"))
		slots_grid.add_child(s)


func _on_slot_pressed(slot_index):
	# коли слот натиснули, відобразити предмет (якщо є)
	var it = null
	if slot_index < inventory_node.items.size():
		it = inventory_node.items[slot_index]
	selected_item = it
	_update_item_details()

func _update_item_details():
	if selected_item == null:
		icon_rect.texture = null
		item_name_label.text = "Порожній слот"
		item_desc_label.text = ""
		return
	if selected_item.icon:
		icon_rect.texture = selected_item.icon
	item_name_label.text = selected_item.name
	item_desc_label.text = selected_item.description

func _on_inventory_changed():
	_refresh_ui()

func _on_money_changed(new_money):
	money_label.text = "Монети: %d" % new_money
	
func _on_use_button_pressed():
	if selected_item == null:
		return
	# Викликаємо використання предмета в інвентарі
	inventory_node.use_item(selected_item)
	# Можеш додати перевірку на гроші, прокрутку інтерфейсу тощо

func _on_sell_button_pressed():
	if selected_item == null:
		return
	var price_back = int(selected_item.price * 0.5)
	inventory_node.remove_item(selected_item)
	inventory_node.earn(price_back)
	selected_item = null
	_refresh_ui()



func _refresh_ui():
	# оновимо слоти і підписку
	var i = 0
	for child in slots_grid.get_children():
		var slot_scene_ref = child
		var item_ref = null
		if i < inventory_node.items.size():
			item_ref = inventory_node.items[i]
		slot_scene_ref.call("set_item", item_ref)
		i += 1
	# оновимо деталі якщо вибраний предмет видалили
	if selected_item != null and not inventory_node.items.has(selected_item):
		selected_item = null
	_update_item_details()
	_on_money_changed(inventory_node.money)
