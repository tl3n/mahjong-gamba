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

func _ready():
	print("GameManager initialized")

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

func add_score(points: int):
	current_score += points
	print("  Score: +%d → %d / %d" % [points, current_score, target_score])
	emit_signal("score_changed", current_score)
	
	if current_score >= target_score:
		_on_blind_completed()

func end_round():
	print("\n=== ROUND %d ENDED ===" % current_round)
	
	_apply_round_end_bonuses()
	
	current_round += 1
	
	if current_round > rounds_per_blind:
		_on_rounds_depleted()
	else:
		start_round()

func _apply_round_end_bonuses():
	var inventory = get_node_or_null("/root/Inventory")
	if not inventory:
		return
	
	var total_bonus_money = 0
	
	for spirit in inventory.spirits:
		if spirit.effect_type == "money_bonus":
			total_bonus_money += int(spirit.effect_value)
	
	if total_bonus_money > 0:
		inventory.add_money(total_bonus_money)
		print("  Round bonus: +%d money" % total_bonus_money)

func _on_blind_completed():
	print("\n=== BLIND %d COMPLETED ===" % current_blind)
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
	
	current_blind += 1
	
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		save_system.save_game()
	
	get_tree().change_scene_to_file("res://scenes/main/shop_scene.tscn")
	

func get_progress_percentage() -> float:
	if target_score <= 0:
		return 0.0
	return (float(current_score) / float(target_score)) * 100.0
