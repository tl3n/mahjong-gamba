# res://scripts/spirit.gd
extends Item
class_name Spirit

@export var effect_type: String = ""   # наприклад "mansion_multiplier", "combo_bonus", "extra_turn"
@export var effect_value: float = 0.0
@export var condition: String = ""     # опис умови, наприклад "масть=вогонь" або "type=pair"
@export var permanent: bool = true     # постійний ефект чи умовний
