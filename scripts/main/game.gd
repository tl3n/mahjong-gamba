extends Node2D

const TileScene = preload("res://scenes/main/tile.tscn")

@onready var hand_container = $HandContainer

var player_hand = [
	{ "id": "dots_1", "suit": "dots", "rank": 1, "asset_path": "res://assets/art/tiles/dots_1.png" },
	{ "id": "dots_2", "suit": "dots", "rank": 2, "asset_path": "res://assets/art/tiles/dots_2.png" },
	{ "id": "dots_3", "suit": "dots", "rank": 3, "asset_path": "res://assets/art/tiles/dots_3.png" },
	{ "id": "dots_4", "suit": "dots", "rank": 4, "asset_path": "res://assets/art/tiles/dots_4.png" },
	{ "id": "dots_5", "suit": "dots", "rank": 5, "asset_path": "res://assets/art/tiles/dots_5.png" },
	{ "id": "dots_6", "suit": "dots", "rank": 6, "asset_path": "res://assets/art/tiles/dots_6.png" },
	{ "id": "dots_7", "suit": "dots", "rank": 7, "asset_path": "res://assets/art/tiles/dots_7.png" },
	{ "id": "dots_8", "suit": "dots", "rank": 8, "asset_path": "res://assets/art/tiles/dots_8.png" },
	{ "id": "dots_9", "suit": "dots", "rank": 9, "asset_path": "res://assets/art/tiles/dots_9.png" },
	{ "id": "bamboo_1", "suit": "bamboo", "rank": 1, "asset_path": "res://assets/art/tiles/bamboo_1.png" },
	{ "id": "bamboo_2", "suit": "bamboo", "rank": 2, "asset_path": "res://assets/art/tiles/bamboo_2.png" },
	{ "id": "bamboo_3", "suit": "bamboo", "rank": 3, "asset_path": "res://assets/art/tiles/bamboo_3.png" },
	{ "id": "bamboo_4", "suit": "bamboo", "rank": 4, "asset_path": "res://assets/art/tiles/bamboo_4.png" }
	]

func _ready():
	print("Scene loaded")
	#display_hand()
	

func display_hand():
	print("Displaying hand...")
	for child in hand_container.get_children():
		child.queue_free()
		
	for tile_data in player_hand:
		var tile_instance = TileScene.instantiate()
		tile_instance.set_tile_data(tile_data)
		hand_container.add_child(tile_instance)
