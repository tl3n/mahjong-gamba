extends Resource
class_name Tile

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

static func _sort_criterion(a: Tile, b: Tile) -> bool:
	
	# 1. Сортування за Мастю (Suit)
	
	# Створюємо спеціальний порядок, щоб NONE (0) йшов в кінець.
	var suit_order_a = a.suit
	if a.suit == Suit.NONE:
		suit_order_a = 99 

	var suit_order_b = b.suit
	if b.suit == Suit.NONE:
		suit_order_b = 99 
		
	# Якщо масті різні, повертаємо результат порівняння мастей
	if suit_order_a != suit_order_b:
		return suit_order_a < suit_order_b

	# 2. Сортування за Рангом (Rank)
	
	# === ВИПРАВЛЕННЯ ТУТ ===
	# Якщо ми дійшли до цього місця, це означає, що масті (suit_order_a == suit_order_b) однакові.
	# Тепер сортуємо за рангом. Ранг (rank) від 1 до 9.
	return a.rank < b.rank

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
