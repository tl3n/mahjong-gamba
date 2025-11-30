extends Item
class_name Spirit

@export var effect_type: String = ""   
@export var effect_value: float = 0.0
@export var condition: String = ""     # some conditions of usage 
@export var permanent: bool = true     # whether it's permanent or lasts some rounds (dumb, needs to be remade)
@export var bonus_value: float = 0.0
