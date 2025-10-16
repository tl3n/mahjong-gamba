# res://scripts/beer.gd
extends Item
class_name Beer

@export var round_effect: String = ""  # короткий опис ефекту
@export var duration: int = 1         # тривалість в раундах
@export var bonus_value: float = 0.0
