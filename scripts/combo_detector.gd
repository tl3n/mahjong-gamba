extends Node
class_name ComboDetector

const COMBOS = {
	"pair": {"name": "Пара", "multiplier": 2.0, "tiles_needed": 2},
	"pong": {"name": "Понг", "multiplier": 3.0, "tiles_needed": 3},
	"two_pairs": {"name": "Дві пари", "multiplier": 4.5, "tiles_needed": 4},
	"two_pongs": {"name": "Два понга", "multiplier": 6.5, "tiles_needed": 6},
	"three_pairs": {"name": "Три пари", "multiplier": 7.0, "tiles_needed": 6},
	"four_pairs": {"name": "Чотири пари", "multiplier": 9.5, "tiles_needed": 8},
	"three_pongs": {"name": "Три понга", "multiplier": 10.0, "tiles_needed": 9},
	"five_pairs": {"name": "П'ять пар", "multiplier": 12.0, "tiles_needed": 10},
	"four_pongs": {"name": "Чотири понга", "multiplier": 13.5, "tiles_needed": 12},
	"six_pairs": {"name": "Шість пар", "multiplier": 14.5, "tiles_needed": 12},
	"seven_pairs": {"name": "Сім пар", "multiplier": 17.0, "tiles_needed": 14},
	"winning_hand": {"name": "Виграшна рука", "multiplier": 20.0, "tiles_needed": 14}
}

static func detect_combos(hand: Array[Tile]) -> Dictionary:
	if hand.is_empty():
		return {}
	
	var groups = _group_tiles(hand)
	
	var pairs_count = 0
	var pongs_count = 0
	
	for group in groups.values():
		var count = group.size()
		if count >= 3:
			pongs_count += 1
		elif count >= 2:
			pairs_count += 1
	
	print("\n Detecting combos:")
	print("   Pairs: %d" % pairs_count)
	print("   Pongs: %d" % pongs_count)
	
	var best_combo = _determine_best_combo(pairs_count, pongs_count)
	
	if best_combo:
		print("    Best combo: %s (×%.1f)" % [best_combo["name"], best_combo["multiplier"]])
	else:
		print("    No combos found")
	
	return best_combo if best_combo else {}

static func _group_tiles(hand: Array[Tile]) -> Dictionary:
	var groups = {}
	
	for tile in hand:
		if tile == null:
			continue
		
		var key = "%d_%d" % [tile.suit, tile.rank]
		
		if not groups.has(key):
			groups[key] = []
		
		groups[key].append(tile)
	
	return groups

static func _determine_best_combo(pairs: int, pongs: int) -> Dictionary:
	if pongs >= 4 and pairs >= 1:
		return COMBOS["winning_hand"]
	
	if pairs >= 7:
		return COMBOS["seven_pairs"]
	
	if pongs >= 4:
		return COMBOS["four_pongs"]
	
	if pairs >= 6:
		return COMBOS["six_pairs"]
	
	if pairs >= 5:
		return COMBOS["five_pairs"]
	
	if pongs >= 3:
		return COMBOS["three_pongs"]
	
	if pairs >= 4:
		return COMBOS["four_pairs"]
	
	if pairs >= 3:
		return COMBOS["three_pairs"]
	
	if pongs >= 2:
		return COMBOS["two_pongs"]
	
	if pairs >= 2:
		return COMBOS["two_pairs"]
	
	if pongs >= 1:
		return COMBOS["pong"]
	
	if pairs >= 1:
		return COMBOS["pair"]
	
	return {}

static func calculate_score(hand: Array[Tile], combo: Dictionary) -> int:
	if hand.is_empty() or combo.is_empty():
		return 0
	
	var base_score = 0
	for tile in hand:
		if tile:
			base_score += tile.weight
	
	var multiplier = combo.get("multiplier", 1.0)
	
	var final_score = int(base_score * multiplier)
	
	print("\n Score calculation:")
	print("   Base score: %d" % base_score)
	print("   Multiplier: ×%.1f" % multiplier)
	print("   Final score: %d" % final_score)
	
	return final_score

static func apply_spirit_bonuses(base_score: int, combo: Dictionary, hand: Array[Tile]) -> int:
	var final_score = base_score
	var multipliers: Array[float] = []
	
	var inventory = Inventory
	if not inventory:
		return final_score
	
	print("\n Applying spirit bonuses:")
	
	for spirit in inventory.spirits:
		match spirit.effect_type:
			
			"suit_bonus":
				var bonus = _calculate_suit_bonus(hand, spirit)
				if bonus > 0:
					final_score += bonus
					print("   + %s: +%d" % [spirit.name, bonus])
			
			"combo_bonus":
				if _check_combo_condition(combo, spirit.condition):
					final_score += int(spirit.effect_value)
					print("   + %s: +%d" % [spirit.name, int(spirit.effect_value)])
			
			"global_multiplier":
				multipliers.append(spirit.effect_value)
				print("   × %s: ×%.1f" % [spirit.name, spirit.effect_value])
	
	for mult in multipliers:
		final_score = int(final_score * mult)
	
	print("   Final score with bonuses: %d" % final_score)
	return final_score

static func _calculate_suit_bonus(hand: Array[Tile], spirit: Spirit) -> int:
	var suit_tiles = 0
	var target_suit = _parse_suit_from_condition(spirit.condition)
	
	for tile in hand:
		if tile and tile.suit == target_suit:
			suit_tiles += 1
	
	return suit_tiles * int(spirit.effect_value)

static func _parse_suit_from_condition(condition: String) -> Tile.Suit:
	if condition.contains("bamboo"):
		return Tile.Suit.BAMBOO
	elif condition.contains("dots"):
		return Tile.Suit.DOTS
	elif condition.contains("characters"):
		return Tile.Suit.CHARACTERS
	elif condition.contains("dragons"):
		return Tile.Suit.DRAGONS
	return Tile.Suit.NONE

static func _check_combo_condition(combo: Dictionary, condition: String) -> bool:
	if condition == "":
		return true
	
	var combo_name = combo.get("name", "").to_lower()
	return combo_name.contains(condition.to_lower())
