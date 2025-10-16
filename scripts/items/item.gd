@icon("res://assets/icons/item_icon.png")
extends Resource
class_name Item

@export var id: String = ""         # унікальний ідентифікатор
@export var name: String = "Item"
@export var description: String = ""
@export var rarity: String = "Історична" # "Історична", "Міфічна", "Легендарна"
@export var price: int = 0
@export var type: String = "дух"    # "дух" або "пиво"
@export var icon: Texture2D
