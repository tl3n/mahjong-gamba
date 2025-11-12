extends Node

signal score_changed(new_score: int)
signal blind_failed()
signal blind_completed()

var current_blind: int = 1
var current_round: int = 1
var current_score: int = 0
var target_score: int = 600
var discards_left: int = 5
var is_game_active: bool = false

var base_discards: int = 5
var rounds_per_blind: int = 3

var last_round_discards: int = 0
var last_round_plays_left: int = 0


func _ready():
	print("GameManager initialized")

func set_final_stats(final_discards: int, final_plays_left: int):
	print("   Saving final stats: %d discards, %d plays left" % [final_discards, final_plays_left])
	last_round_discards = final_discards
	last_round_plays_left = final_plays_left

func _calculate_total_discards() -> int:
	var total = base_discards
	
	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		for spirit in inventory.spirits:
			if spirit.effect_type == "extra_turn":
				total += int(spirit.effect_value)
				print("  %s: +%d discards" % [spirit.name, int(spirit.effect_value)])
	
	return total

# Bonus system for cash
func _calculate_round_bonus():
	var inventory = get_node_or_null("/root/Inventory")
	if inventory == null:
		print("Cannot calculate bonus: Inventory not found")
		return
		
	var total_bonus_money = 0
	
	# Bonus for unused rounds
	var unused_rounds = last_round_plays_left 
	if unused_rounds > 0:
		var round_bonus = unused_rounds * 1 # TODO: balance this out
		total_bonus_money += round_bonus
		print("  Unused plays bonus: +%d money" % round_bonus)

	# Bonus for unused discards
	var unused_discards = last_round_discards
	if unused_discards > 0:
		var discard_bonus = unused_discards * 1 # TODO: balance this out
		total_bonus_money += discard_bonus
		print("  Unused discards bonus: +%d money" % discard_bonus)
		
	# Pay for completing a blind
	var base_blind_income = min(current_blind, 5)
	total_bonus_money += base_blind_income # TODO: balance this out
	print("  Base blind income: +%d money" % base_blind_income)
	
	inventory.add_money(total_bonus_money)
	print("  Total round bonus: +%d money" % total_bonus_money)

func add_score(points: int):
	current_score += points
	print("  Score: +%d → %d / %d" % [points, current_score, target_score])
	emit_signal("score_changed", current_score)

func _on_blind_completed():
	print("   Final score: %d / %d" % [current_score, target_score])
	
	is_game_active = false
	emit_signal("blind_completed")
	
	_go_to_shop()

func _on_blind_failed():
	print("Blind failed - deleting save")
	emit_signal("blind_failed")
	_go_to_main_menu()

func _go_to_shop():
	print("Going to shop")
	
	_calculate_round_bonus()
	
	current_blind += 1
	
	target_score += 200 #TODO: balance this thing
	print("   New target score: %d" % target_score)
	
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		save_system.save_game()
	
	get_tree().change_scene_to_file("res://scenes/main/shop_scene.tscn")
	
func _go_to_main_menu():
	print("Going to main menu after an embarassing failure")
	
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		save_system.delete_save()
	
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
	
