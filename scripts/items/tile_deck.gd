extends Node
class_name TileDeck

var deck: Array[Tile] = []
var original_deck: Array[Tile] = []

var open_discard: Array[Tile] = []    
var closed_discard: Array[Tile] = []  

func _init():
	_create_full_deck()
	original_deck = deck.duplicate()

func _create_full_deck():
	deck.clear()
	
	for suit in [Tile.Suit.BAMBOO, Tile.Suit.DOTS, Tile.Suit.CHARACTERS]:
		for rank in range(1, 10): 
			for copy in range(4):  
				var tile = Tile.new(suit, rank)
				deck.append(tile)
	
	for dragon_type in range(3):  
		for copy in range(4): 
			var tile = Tile.new(Tile.Suit.DRAGONS, dragon_type + 1)
			deck.append(tile)
	
	print("Deck created: %d tiles" % deck.size())
	shuffle_deck()


func shuffle_deck():
	deck.shuffle()
	print("Deck shuffled")

func draw_tile() -> Tile:
	if deck.is_empty():
		print(" Deck is empty! Reshuffling closed discard...")
		_reshuffle_from_closed_discard()
	
	if deck.is_empty():
		print("No tiles left!")
		return null
	
	var tile = deck.pop_back()
	print("Drew tile: %s" % tile.get_display_text())
	return tile

func draw_multiple(count: int) -> Array[Tile]:
	var tiles: Array[Tile] = []
	for i in range(count):
		var tile = draw_tile()
		if tile:
			tiles.append(tile)
	return tiles

func draw_from_open_discard(index: int) -> Tile:
	if index < 0 or index >= open_discard.size():
		print("Invalid open discard index: %d" % index)
		return null
	
	var tile = open_discard[index]
	open_discard.remove_at(index)
	print("Drew from open discard: %s" % tile.get_display_text())
	return tile

func discard_to_open(tile: Tile):
	if tile == null:
		return
	open_discard.append(tile)
	print("Discarded to open: %s (total: %d)" % [tile.get_display_text(), open_discard.size()])

func discard_to_closed(tile: Tile):
	if tile == null:
		return
	closed_discard.append(tile)
	print("Discarded to closed: %s (total: %d)" % [tile.get_display_text(), closed_discard.size()])


func _reshuffle_from_closed_discard():
	if closed_discard.is_empty():
		print("Closed discard is also empty!")
		return
	
	deck = closed_discard.duplicate()
	closed_discard.clear()
	shuffle_deck()
	
	print("Reshuffled %d tiles from closed discard" % deck.size())


func reset_for_new_round():
	deck.clear()
	deck = original_deck.duplicate()
	open_discard.clear()
	closed_discard.clear()
	shuffle_deck()
	
	print("Deck reset for new round")


func get_deck_size() -> int:
	return deck.size()

func get_open_discard_size() -> int:
	return open_discard.size()

func get_closed_discard_size() -> int:
	return closed_discard.size()

func get_total_tiles() -> int:
	return deck.size() + open_discard.size() + closed_discard.size()
