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

# Returns tiles that are part of combos (pairs/pongs) - these "dealt damage"
static func get_combo_tiles(hand: Array[Tile]) -> Array[Tile]:
	var combo_tiles: Array[Tile] = []
	var groups = _group_tiles(hand)
	
	for group in groups.values():
		var count = group.size()
		if count >= 3:
			# Pong - all 3 tiles are part of combo
			for i in range(3):
				combo_tiles.append(group[i])
		elif count >= 2:
			# Pair - 2 tiles are part of combo
			for i in range(2):
				combo_tiles.append(group[i])
	
	return combo_tiles

# Returns tiles NOT part of any combo
static func get_non_combo_tiles(hand: Array[Tile]) -> Array[Tile]:
	var non_combo_tiles: Array[Tile] = []
	var groups = _group_tiles(hand)
	
	for group in groups.values():
		var count = group.size()
		if count >= 3:
			# Extra tiles beyond the pong (4th copy)
			for i in range(3, count):
				non_combo_tiles.append(group[i])
		elif count >= 2:
			# Extra tiles beyond the pair (3rd, 4th copies)
			for i in range(2, count):
				non_combo_tiles.append(group[i])
		else:
			# Single tiles - not part of any combo
			for tile in group:
				non_combo_tiles.append(tile)
	
	return non_combo_tiles

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
	var flat_bonuses: int = 0
	
	var inventory = Inventory
	if not inventory:
		return final_score
	
	print("\n Applying spirit bonuses:")
	
	for spirit in inventory.spirits:
		match spirit.effect_type:
			
			"flat_bonus":
				var bonus = int(spirit.effect_value)
				flat_bonuses += bonus
				print("   + %s: +%d очок" % [spirit.name, bonus])
			
			"suit_bonus":
				var bonus = _calculate_suit_bonus(hand, spirit)
				if bonus > 0:
					flat_bonuses += bonus
					print("   + %s: +%d очок (масть)" % [spirit.name, bonus])
			
			"tile_bonus":
				var bonus = hand.size() * int(spirit.effect_value)
				flat_bonuses += bonus
				print("   + %s: +%d очок (%d×%d)" % [spirit.name, bonus, hand.size(), int(spirit.effect_value)])
			
			"combo_flat_bonus":
				if _check_combo_condition(combo, spirit.condition):
					var bonus = int(spirit.effect_value)
					flat_bonuses += bonus
					print("   + %s: +%d очок (комбо)" % [spirit.name, bonus])
			
			"rank_bonus":
				var bonus = _calculate_rank_bonus(hand, spirit)
				if bonus > 0:
					flat_bonuses += bonus
					print("   + %s: +%d очок (ранг)" % [spirit.name, bonus])
			
			"global_multiplier":
				multipliers.append(spirit.effect_value)
				print("   × %s: ×%.1f" % [spirit.name, spirit.effect_value])
			
			"combo_multiplier":
				if _check_combo_condition(combo, spirit.condition):
					multipliers.append(spirit.effect_value)
					print("   × %s: ×%.2f (комбо)" % [spirit.name, spirit.effect_value])
			
			"suit_multiplier":
				if _has_suit_tiles(hand, spirit.condition):
					multipliers.append(spirit.effect_value)
					print("   × %s: ×%.2f (масть)" % [spirit.name, spirit.effect_value])
	
	final_score += flat_bonuses
	if flat_bonuses > 0:
		print("   After flat bonuses: %d" % final_score)
	
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

static func _calculate_rank_bonus(hand: Array[Tile], spirit: Spirit) -> int:
	var target_rank = _parse_rank_from_condition(spirit.condition)
	if target_rank == -1:
		return 0
	
	var rank_tiles = 0
	for tile in hand:
		if tile and tile.rank == target_rank:
			rank_tiles += 1
	
	return rank_tiles * int(spirit.effect_value)

static func _parse_rank_from_condition(condition: String) -> int:
	if condition.contains("rank="):
		var parts = condition.split("=")
		if parts.size() >= 2:
			return int(parts[1])
	return -1

static func _has_suit_tiles(hand: Array[Tile], condition: String) -> bool:
	var target_suit = _parse_suit_from_condition(condition)
	if target_suit == Tile.Suit.NONE:
		return false
	
	for tile in hand:
		if tile and tile.suit == target_suit:
			return true
	
	return false

static func _parse_suit_from_condition(condition: String) -> Tile.Suit:
	var lower_cond = condition.to_lower()
	
	if lower_cond.contains("bamboo") or lower_cond.contains("бамбук"):
		return Tile.Suit.BAMBOO
	elif lower_cond.contains("dots") or lower_cond.contains("кружки") or lower_cond.contains("коло"):
		return Tile.Suit.DOTS
	elif lower_cond.contains("characters") or lower_cond.contains("символи") or lower_cond.contains("ієрогліфи"):
		return Tile.Suit.CHARACTERS
	elif lower_cond.contains("dragons") or lower_cond.contains("дракони"):
		return Tile.Suit.DRAGONS
	
	return Tile.Suit.NONE

static func _check_combo_condition(combo: Dictionary, condition: String) -> bool:
	if condition == "":
		return true
	
	var combo_name = combo.get("name", "").to_lower()
	var condition_lower = condition.to_lower()
	
	if condition_lower.contains("pair") or condition_lower.contains("пар"):
		return combo_name.contains("пар")
	elif condition_lower.contains("pong") or condition_lower.contains("понг"):
		return combo_name.contains("понг")
	
	return combo_name.contains(condition_lower)
