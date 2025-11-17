extends Node

signal score_changed(new_score: int)
signal blind_failed()
signal blind_completed()

var current_blind: int = 1
var current_round: int = 1
var current_score: int = 0
var target_score: int = 800
var discards_left: int = 5
var is_game_active: bool = false

var base_discards: int = 5
var base_rounds_per_blind: int = 3 
var rounds_per_blind: int = 3  

var last_round_discards: int = 0
var last_round_plays_left: int = 0

var active_score_multiplier: float = 1.0
var active_first_combo_boost: float = 0.0
var active_bonus_money: int = 0
var active_extra_discards: int = 0

func _ready():
	print("GameManager initialized")
	_recalculate_rounds()
	
func _update_beer_durations():
	var inventory = get_node_or_null("/root/Inventory")
	if not inventory or inventory.beers.is_empty():
		return
	
	print("Updating beer durations...")
	var beers_to_remove = []
	for beer in inventory.beers:
		if beer == null: continue
		
		if beer.blind_effect != "reroll_discount":
			beer.duration -= 1
			print("   %s duration now: %d" % [beer.name, beer.duration])
		
		if beer.duration <= 0:
			beers_to_remove.append(beer)
	
	if beers_to_remove.is_empty():
		return

	for beer in beers_to_remove:
		print("   %s has expired and is being removed." % beer.name)
		inventory.remove_item(beer)
	
	inventory.emit_signal("inventory_changed")

func _apply_beer_effects():
	print("Applying beer effects for this round...")
	
	active_score_multiplier = 1.0
	active_first_combo_boost = 0.0
	active_bonus_money = 0
	active_extra_discards = 0

	var inventory = get_node_or_null("/root/Inventory")
	if not inventory or inventory.beers.is_empty():
		print("   No beers to apply.")
		return

	for beer in inventory.beers:
		if beer == null: continue
		
		print("   Applying: %s (Duration: %d)" % [beer.name, beer.duration])
		match beer.blind_effect:
			"extra_draw":
				active_extra_discards += int(beer.bonus_value)
			"score_multiplier":
				active_score_multiplier *= beer.bonus_value
			"bonus_money":
				active_bonus_money += int(beer.bonus_value)
			"first_combo_boost":
				active_first_combo_boost += beer.bonus_value

func _recalculate_rounds():
	rounds_per_blind = base_rounds_per_blind
	
	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		for spirit in inventory.spirits:
			if spirit.effect_type == "extra_round":
				rounds_per_blind += int(spirit.effect_value)
				print("  %s: +%d round(s)" % [spirit.name, int(spirit.effect_value)])
	
	print("  Total rounds: %d" % rounds_per_blind)

func _recalculate_discards():
	var total = base_discards
	
	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		for spirit in inventory.spirits:
			if spirit.effect_type == "extra_discard":
				total += int(spirit.effect_value)
				print("  %s: +%d discards" % [spirit.name, int(spirit.effect_value)])
	
	print("  General amount of discards: %d" % total)
	return total

# Bonus system for cash
func set_final_stats(final_discards: int, final_plays_left: int):
	print("   Saving final stats: %d discards, %d plays left" % [final_discards, final_plays_left])
	last_round_discards = final_discards
	last_round_plays_left = final_plays_left

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
	
	var base_blind_income = min(current_blind, 5)
	total_bonus_money += base_blind_income
	print("  Base blind income: +%d money" % base_blind_income)
	
	var beer_bonus = _calculate_beer_money_bonus()
	if beer_bonus > 0:
		total_bonus_money += beer_bonus
		print("  Beer bonus: +%d money" % beer_bonus)
	
	if total_bonus_money > 0:
		inventory.add_money(total_bonus_money)
		print("  Total round bonus: +%d money" % total_bonus_money)

func _calculate_beer_money_bonus() -> int:
	var inventory = get_node_or_null("/root/Inventory")
	if not inventory:
		return 0
	
	var total_beer_bonus = 0
	
	return total_beer_bonus

func add_score(points: int):
	current_score += points
	print("  Score: +%d → %d / %d" % [points, current_score, target_score])
	emit_signal("score_changed", current_score)
	
func reset_game():
	print("Resetting game state...")
	
	current_blind = 1
	current_round = 1
	current_score = 0
	target_score = 800
	discards_left = base_discards
	is_game_active = false
	
	last_round_discards = 0
	last_round_plays_left = 0
	
	active_score_multiplier = 1.0
	active_first_combo_boost = 0.0
	active_bonus_money = 0
	active_extra_discards = 0
	
	_recalculate_rounds() 
	
	print("Game state reset to default.")
	
func _on_blind_completed():
	print("   Final score: %d / %d" % [current_score, target_score])
	
	is_game_active = false
	emit_signal("blind_completed")
	reset_game()
	_go_to_shop()

func _on_blind_failed():
	print("Blind failed - deleting save")
	emit_signal("blind_failed")
	_go_to_main_menu()

func _go_to_shop():
	print("Going to shop")
	
	_calculate_round_bonus()
	
	_update_beer_durations()
	
	current_blind += 1
	current_score = 0  
	
	target_score += 200 #TODO: balance this thing
	print("   New target score: %d" % target_score)
	
	_recalculate_rounds()
	
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
