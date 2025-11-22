extends Button

signal pressed_slot(index: int)

var index: int = -1
var item: Resource = null

@onready var icon_node: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/NameLabel

func _ready():
	connect("pressed", Callable(self, "_on_pressed"))

func set_item(item_ref):
	item = item_ref
	if icon_node == null or name_label == null:
		return

	if item == null:
		icon_node.texture = null
		name_label.text = ""
		modulate = Color(1, 1, 1, 0.5)
	else:
		icon_node.texture = item.icon if item.icon else null
		name_label.text = item.name
		modulate = Color.WHITE
		
		var color = _get_rarity_color(item.rarity)
		add_theme_color_override("font_outline_color", color)
		
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

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

func _on_pressed():
	emit_signal("pressed_slot", index)
