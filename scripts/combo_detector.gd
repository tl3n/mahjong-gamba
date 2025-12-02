extends Node
class_name ComboDetector

# Individual combo multipliers for stacking
const PAIR_MULTIPLIERS = {
	1: 2.0,   # 1 pair = ×2.0
	2: 4.5,   # 2 pairs = ×4.5
	3: 7.0,   # 3 pairs = ×7.0
	4: 9.5,   # 4 pairs = ×9.5
	5: 12.0,  # 5 pairs = ×12.0
	6: 14.5,  # 6 pairs = ×14.5
	7: 17.0   # 7 pairs = ×17.0
}

const PONG_MULTIPLIERS = {
	1: 3.0,   # 1 pong = ×3.0
	2: 6.5,   # 2 pongs = ×6.5
	3: 10.0,  # 3 pongs = ×10.0
	4: 13.5   # 4 pongs = ×13.5
}

const PAIR_NAMES = {
	1: "Пара",
	2: "Дві пари",
	3: "Три пари",
	4: "Чотири пари",
	5: "П'ять пар",
	6: "Шість пар",
	7: "Сім пар"
}

const PONG_NAMES = {
	1: "Понг",
	2: "Два понга",
	3: "Три понга",
	4: "Чотири понга"
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
	
	if pairs_count == 0 and pongs_count == 0:
		print("    No combos found")
		return {}
	
	# Build combined combo result
	var combined_combo = _build_combined_combo(pairs_count, pongs_count)
	
	if combined_combo:
		print("    Combined combo: %s (×%.1f)" % [combined_combo["name"], combined_combo["multiplier"]])
	
	return combined_combo if combined_combo else {}

# Combines pairs and pongs into a single combo with stacked multipliers
static func _build_combined_combo(pairs: int, pongs: int) -> Dictionary:
	if pairs == 0 and pongs == 0:
		return {}
	
	# Special case: Winning hand (4 pongs + 1 pair)
	if pongs >= 4 and pairs >= 1:
		return {"name": "Виграшна рука", "multiplier": 20.0, "pairs": pairs, "pongs": pongs}
	
	# Calculate combined multiplier: base 1.0 + (pair_mult - 1.0) + (pong_mult - 1.0)
	var total_multiplier = 1.0
	var combo_parts = []
	
	# Add pong contribution
	if pongs > 0:
		var pong_mult = PONG_MULTIPLIERS.get(pongs, PONG_MULTIPLIERS[4])
		total_multiplier += (pong_mult - 1.0)
		combo_parts.append(PONG_NAMES.get(pongs, "%d понгів" % pongs))
	
	# Add pair contribution
	if pairs > 0:
		var pair_mult = PAIR_MULTIPLIERS.get(pairs, PAIR_MULTIPLIERS[7])
		total_multiplier += (pair_mult - 1.0)
		combo_parts.append(PAIR_NAMES.get(pairs, "%d пар" % pairs))
	
	# Build combo name
	var combo_name = " + ".join(combo_parts)
	
	return {
		"name": combo_name,
		"multiplier": total_multiplier,
		"pairs": pairs,
		"pongs": pongs
	}

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

# Returns combo type for each tile index: "pong", "pair", or "" (no combo)
static func get_combo_highlight_info(hand: Array[Tile]) -> Array[String]:
	var result: Array[String] = []
	result.resize(hand.size())
	for i in range(hand.size()):
		result[i] = ""
	
	# Count tiles by key
	var tile_counts = {}
	var tile_indices = {}
	
	for i in range(hand.size()):
		var tile = hand[i]
		if tile == null:
			continue
		
		var key = "%d_%d" % [tile.suit, tile.rank]
		
		if not tile_counts.has(key):
			tile_counts[key] = 0
			tile_indices[key] = []
		
		tile_counts[key] += 1
		tile_indices[key].append(i)
	
	# Mark combo tiles
	for key in tile_counts:
		var count = tile_counts[key]
		var indices = tile_indices[key]
		
		if count >= 3:
			# Pong - mark first 3 tiles
			for j in range(min(3, indices.size())):
				result[indices[j]] = "pong"
		elif count >= 2:
			# Pair - mark first 2 tiles
			for j in range(min(2, indices.size())):
				result[indices[j]] = "pair"
	
	return result


static func calculate_score(hand: Array[Tile], combo: Dictionary) -> int:
	if hand.is_empty() or combo.is_empty():
		return 0
	
	var base_score = 0
	var inventory = Inventory
	var weight_multiplier = 1.0 # Базовий множник
	
	if inventory:
		for spirit in inventory.spirits:
			if spirit.effect_type == "unsuited_weight_multiplier":
				weight_multiplier *= spirit.effect_value
				print("   Spirit of Weight multiplier active: x%.1f" % weight_multiplier)
				break # Припускаємо, що множник не стакається

	for tile in hand:
		if tile:
			var tile_weight = tile.weight
			
			# Якщо тайл без масті (вага 10) застосовуємо множник
			if tile_weight == 10 and weight_multiplier > 1.0: # Тайли без масті важать 10 
				tile_weight = int(tile_weight * weight_multiplier)
				print("   Applying x%.1f to unsuited tile (Weight: %d)" % [weight_multiplier, tile_weight])

			base_score += tile_weight
	
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
	
	var condition_lower = condition.to_lower()
	
	# Check using the pairs/pongs counts in the combo dict
	if condition_lower.contains("pair") or condition_lower.contains("пар"):
		return combo.get("pairs", 0) > 0
	elif condition_lower.contains("pong") or condition_lower.contains("понг"):
		return combo.get("pongs", 0) > 0
	
	# Fallback to name check
	var combo_name = combo.get("name", "").to_lower()
	return combo_name.contains(condition_lower)
