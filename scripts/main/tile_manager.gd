extends Node

class MahjongTileData:
	var id: String
	var suit: String
	var rank: int
	var asset_path: String
	
	func _init(p_id: String, p_suit: String, p_rank: int, p_asset_path: String):
		self.id = p_id
		self.suit = p_suit
		self.rank = p_rank
		self.asset_path = p_asset_path

var full_tile_set: Array[MahjongTileData] = []
var wall: Array[MahjongTileData] = []
var open_discard: Array[MahjongTileData] = []
var closed_discard: Array[MahjongTileData] = []

func _ready():
	load_full_tile_set()
	create_new_wall()

func draw_wall_tiles(amount: int):
	if amount > wall.size():
		printerr("There are less than " + str(amount) + " tiles in the wall")
		return
	
	var drawn_tiles: Array[MahjongTileData] = []
	for i in range(amount):
		var tile = wall.pop_front()
		drawn_tiles.append(tile)
	
	return drawn_tiles

func add_to_open_discard(tile: MahjongTileData):
	open_discard.append(tile)

func add_to_closed_discard(tile: MahjongTileData):
	closed_discard.append(tile)

func create_new_wall():
	wall.clear()
	
	if (full_tile_set.is_empty()):
		printerr("Full tile set is not created")
		return
	
	wall = full_tile_set.duplicate(true)
	wall.shuffle()

func load_full_tile_set():
	full_tile_set.clear()
	
	var file_path = "res://data/tile_definitions.json"
	if not FileAccess.file_exists(file_path):
		printerr("Tile definitions file not found")
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	var json_data = JSON.parse_string(file.get_as_text())
	if not json_data:
		printerr("Failed to parse JSON tile definitions")
		return
	
	for tile_def in json_data["tiles"]:
		for i in range(4):
			var id = "%s_%d_%d" % [tile_def["suit"], tile_def["rank"], i]
			var tile = MahjongTileData.new(id, tile_def["suit"], tile_def["rank"], tile_def["asset_path"])
			full_tile_set.append(tile)
