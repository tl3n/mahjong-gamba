extends Node

signal score_changed(new_score: int)
signal round_changed(new_round: int)
signal blind_changed(new_blind: int)
signal game_over()
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

func reset_game():
	print("\n=== RESETTING GAME ===")
	
	current_blind = 1
	current_round = 1
	current_score = 0
	target_score = 600
	discards_left = base_discards
	is_game_active = false
	
	print("Game state reset:")
	print("   Blind: %d" % current_blind)
	print("   Round: %d" % current_round)
	print("   Score: %d / %d" % [current_score, target_score])
	print("   Discards: %d" % discards_left)

func start_blind():
	print("\n=== STARTING BLIND %d ===" % current_blind)
	
	current_round = 1
	current_score = 0
	is_game_active = true
	
	target_score = 600 + (current_blind - 1) * 200
	
	print("Target score: %d" % target_score)
	
	emit_signal("blind_changed", current_blind)
	start_round()

func start_round():
	print("\n=== STARTING ROUND %d/%d ===" % [current_round, rounds_per_blind])
	
	discards_left = _calculate_total_discards()
	
	print("Discards available: %d" % discards_left)
	
	emit_signal("round_changed", current_round)

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
	total_bonus_money += base_blind_income
	print("  Base blind income: +%d money" % base_blind_income)
	
	if total_bonus_money > 0:
		inventory.add_money(total_bonus_money)
		print("  Total round bonus: +%d money" % total_bonus_money)

func add_score(points: int):
	current_score += points
	print("  Score: +%d → %d / %d" % [points, current_score, target_score])
	emit_signal("score_changed", current_score)

func end_round():
	print("\n=== ROUND %d ENDED ===" % current_round)
	
	_calculate_round_bonus()
	
	current_round += 1
	
	if current_round > rounds_per_blind:
		_on_rounds_depleted()
	else:
		start_round()

func _on_blind_completed():
	print("   Final score: %d / %d" % [current_score, target_score])
	
	is_game_active = false
	emit_signal("blind_completed")
	
	_go_to_shop()

func _on_rounds_depleted():
	print("\n=== ROUNDS DEPLETED ===")
	print("   Score: %d / %d" % [current_score, target_score])
	
	if current_score >= target_score:
		_on_blind_completed()
	else:
		print("   Failed to reach target")
		is_game_active = false
		emit_signal("game_over")

func _go_to_shop():
	print("Going to shop")
	
	_calculate_round_bonus()
	
	current_blind += 1
	
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		save_system.save_game()
	
	get_tree().change_scene_to_file("res://scenes/main/shop_scene.tscn")
	

func get_progress_percentage() -> float:
	if target_score <= 0:
		return 0.0
	return (float(current_score) / float(target_score)) * 100.0
