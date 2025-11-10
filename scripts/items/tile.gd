extends Resource
class_name Tile

# Масть тайла 
enum Suit {
	BAMBOO = 1,   
	DOTS = 2,    
	CHARACTERS = 3, 
	DRAGONS = 4,  
	NONE = 0     
}

@export var suit: Suit = Suit.NONE
@export var rank: int = 1  # 1-9
@export var id: String = ""
@export var icon: Texture2D

var weight: int:
	get:
		if suit == Suit.NONE:
			return 10  
		else:
			return rank  

func _init(p_suit: Suit = Suit.NONE, p_rank: int = 1):
	suit = p_suit
	rank = p_rank
	id = _generate_id()

func _generate_id() -> String:
	var suit_name = Suit.keys()[suit]
	return "%s_%d" % [suit_name, rank]

func matches(other: Tile) -> bool:
	if other == null:
		return false
	return suit == other.suit and rank == other.rank

func get_display_text() -> String:
	var suit_symbol = _get_suit_symbol()
	if suit == Suit.NONE:
		return "🀫"  
	return "%s%d" % [suit_symbol, rank]

func _get_suit_symbol() -> String:
	match suit:
		Suit.BAMBOO:
			return "🎋"
		Suit.DOTS:
			return "⚫"
		Suit.CHARACTERS:
			return "🀄"
		Suit.DRAGONS:
			return "🐉"
		_:
			return "?"

func get_suit_color() -> Color:
	match suit:
		Suit.BAMBOO:
			return Color(0.2, 0.8, 0.3) 
		Suit.DOTS:
			return Color(0.2, 0.5, 0.9) 
		Suit.CHARACTERS:
			return Color(0.9, 0.2, 0.2)  
		Suit.DRAGONS:
			return Color(0.8, 0.6, 0.2) 
		_:
			return Color(0.5, 0.5, 0.5) 
