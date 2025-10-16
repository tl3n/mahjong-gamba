extends Button
signal pressed_slot(index)

var index: int = -1
var item: Resource = null

@onready var icon_node: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/NameLabel

func _ready():
	# Під’єднати свій сигнал pressed кнопки до методу _on_pressed
	connect("pressed", Callable(self, "_on_pressed"))

func set_item(item_ref):
	item = item_ref
	if icon_node == null or name_label == null:
		push_warning("Icon або NameLabel не знайдено!")
		return

	if item == null:
		icon_node.texture = null
		name_label.text = ""
	else:
		icon_node.texture = item.icon if item.icon else null
		name_label.text = item.name

func _on_pressed():
	emit_signal("pressed_slot", index)
