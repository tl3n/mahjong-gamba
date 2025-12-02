extends Node
class_name ItemDatabase

const RARITY_WEIGHTS = {
	"Історична": 65.0, # 65% chance
	"Historic": 65.0,
	"Міфічна": 25.0, # 25% chance
	"Mythic": 25.0,
	"Легендарна": 10.0, # 10% chance
	"Legendary": 10.0
}

static var spirits_data = [
	
	{
		"id": "spirit_earth",
		"name": "Дух Землі",
		"description": "+50 очок до кожної руки",
		"rarity": "Історична",
		"price": 5,
		"effect_type": "flat_bonus",
		"effect_value": 50.0,
		"condition": ""
	},
	{
		"id": "spirit_fortune",
		"name": "Дух Удачі",
		"description": "+100 очок якщо є пари",
		"rarity": "Міфічна",
		"price": 8,
		"effect_type": "combo_flat_bonus",
		"effect_value": 100.0,
		"condition": "pair"
	},
	
	# === SUIT BONUS ===
	{
		"id": "spirit_bamboo",
		"name": "Дух Бамбука",
		"description": "+8 очок за кожен бамбуковий тайл",
		"rarity": "Історична",
		"price": 6,
		"effect_type": "suit_bonus",
		"effect_value": 8.0,
		"condition": "suit=bamboo"
	},
	{
		"id": "spirit_dots",
		"name": "Дух Кружків",
		"description": "+10 очок за кожен тайл кружків",
		"rarity": "Міфічна",
		"price": 8,
		"effect_type": "suit_bonus",
		"effect_value": 10.0,
		"condition": "suit=dots"
	},
	{
		"id": "spirit_characters",
		"name": "Дух Символів",
		"description": "+12 очок за кожен тайл символів",
		"rarity": "Міфічна",
		"price": 8,
		"effect_type": "suit_bonus",
		"effect_value": 12.0,
		"condition": "suit=characters"
	},
	
	# === TILE BONUS ===
	{
		"id": "spirit_collector",
		"name": "Дух Колекціонера",
		"description": "+5 очок за кожен тайл у руці",
		"rarity": "Історична",
		"price": 6,
		"effect_type": "tile_bonus",
		"effect_value": 5.0,
		"condition": ""
	},
	
	# === RANK BONUS ===
	{
		"id": "spirit_nine",
		"name": "Дух Дев'яток",
		"description": "+20 очок за кожну дев'ятку",
		"rarity": "Міфічна",
		"price": 7,
		"effect_type": "rank_bonus",
		"effect_value": 20.0,
		"condition": "rank=9"
	},
	{
		"id": "spirit_one",
		"name": "Дух Одиниць",
		"description": "+15 очок за кожну одиницю",
		"rarity": "Історична",
		"price": 5,
		"effect_type": "rank_bonus",
		"effect_value": 15.0,
		"condition": "rank=1"
	},
	
	# === GLOBAL MULTIPLIER ===
	{
		"id": "spirit_dragon",
		"name": "Дух Дракона",
		"description": "×1.5 до всіх очок",
		"rarity": "Легендарна",
		"price": 10,
		"effect_type": "global_multiplier",
		"effect_value": 1.5,
		"condition": ""
	},
	{
		"id": "spirit_phoenix",
		"name": "Дух Фенікса",
		"description": "×2.0 до всіх очок",
		"rarity": "Легендарна",
		"price": 12,
		"effect_type": "global_multiplier",
		"effect_value": 2.0,
		"condition": ""
	},
	
	# === COMBO MULTIPLIER ===
	{
		"id": "spirit_moon",
		"name": "Дух Місяця",
		"description": "×2.0 до очок якщо є понг",
		"rarity": "Міфічна",
		"price": 8,
		"effect_type": "combo_multiplier",
		"effect_value": 2.0,
		"condition": "pong"
	},
	{
		"id": "spirit_star",
		"name": "Дух Зірки",
		"description": "×1.8 до очок якщо є пари",
		"rarity": "Міфічна",
		"price": 7,
		"effect_type": "combo_multiplier",
		"effect_value": 1.8,
		"condition": "pair"
	},
	
	# === SUIT MULTIPLIER ===
	{
		"id": "spirit_fire",
		"name": "Дух Вогню",
		"description": "×2.0 якщо є драконові тайли",
		"rarity": "Легендарна",
		"price": 10,
		"effect_type": "suit_multiplier",
		"effect_value": 2.0,
		"condition": "suit=dragons"
	},
	{
		"id": "spirit_wind",
		"name": "Дух Вітру",
		"description": "×1.6 якщо є бамбук",
		"rarity": "Міфічна",
		"price": 8,
		"effect_type": "suit_multiplier",
		"effect_value": 1.6,
		"condition": "suit=bamboo"
	},
	
	# === EXTRA ROUNDS ===
	{
		"id": "spirit_lightning",
		"name": "Дух Блискавки",
		"description": "+1 додатковий раунд кожного блайнду",
		"rarity": "Легендарна",
		"price": 12,
		"effect_type": "extra_round",
		"effect_value": 1.0,
		"condition": ""
	},
	{
		"id": "spirit_time",
		"name": "Дух Часу",
		"description": "+2 додаткових раунди кожного блайнду",
		"rarity": "Легендарна",
		"price": 15,
		"effect_type": "extra_round",
		"effect_value": 2.0,
		"condition": ""
	},
	
	# === EXTRA DISCARDS ===
	{
		"id": "spirit_patience",
		"name": "Дух Терпіння",
		"description": "+2 дискарди кожного раунду",
		"rarity": "Міфічна",
		"price": 8,
		"effect_type": "extra_discard",
		"effect_value": 2.0,
		"condition": ""
	},
	{
		"id": "spirit_eternity",
		"name": "Дух Вічності",
		"description": "+3 дискарди кожного раунду",
		"rarity": "Легендарна",
		"price": 10,
		"effect_type": "extra_discard",
		"effect_value": 3.0,
		"condition": ""
	},
	{
		"id": "spirit_mercy",
		"name": "Дух Милосердя",
		"description": "+1 дискард кожного раунду",
		"rarity": "Історична",
		"price": 5,
		"effect_type": "extra_discard",
		"effect_value": 1.0,
		"condition": ""
	},
	{
		"id": "spirit_greed",
		"name": "Дух Жадоби",
		"description": "+1 гроша за зіграний раунд, але -1 раунд від блайнду",
		"rarity": "Історична", 
		"price": 6, 
		"effect_type": "minus_round",
		"effect_value": -1.0,  # Штраф до раундів (-1 раунд)
		"bonus_value": 2.0,   # Бонус до грошей (+1 валюта)
		"condition": ""
	},
	{
		"id": "spirit_weight",
		"name": "Дух Ваги",
		"description": "×2.0 до базової ваги тайлів без масті",
		"rarity": "Міфічна", 
		"price": 8, 
		"effect_type": "unsuited_weight_multiplier",
		"effect_value": 2.0,   # Множник
		"condition": ""
	}
]

static var beers_data = [
	{
		"id": "beer_extra_draw",
		"name": "Пиво: Додатковий дискард",
		"description": "Додає +1 дискард на цей блайнд",
		"rarity": "Історична",
		"price": 3,
		"blind_effect": "extra_draw",
		"duration": 1,
		"bonus_value": 1.0
	},
	{
		"id": "beer_double_points",
		"name": "Пиво: Подвійні очки",
		"description": "×2.0 до всіх очок цього блайнду",
		"rarity": "Міфічна",
		"price": 5,
		"blind_effect": "score_multiplier",
		"duration": 1,
		"bonus_value": 2.0
	},
	{
		"id": "beer_triple_points",
		"name": "Пиво: Потрійні очки",
		"description": "×3.0 до всіх очок цього блайнду",
		"rarity": "Легендарна",
		"price": 7,
		"blind_effect": "score_multiplier",
		"duration": 1,
		"bonus_value": 3.0
	},
	{
		"id": "beer_fortune",
		"name": "Пиво: Удача",
		"description": "+5 монет після завершення блайнду",
		"rarity": "Історична",
		"price": 3,
		"blind_effect": "bonus_money",
		"duration": 1,
		"bonus_value": 5.0
	},
	{
		"id": "beer_combo",
		"name": "Пиво: Комбо",
		"description": "+150 очок до першої комбінації цього блайнду",
		"rarity": "Міфічна",
		"price": 4,
		"blind_effect": "first_combo_boost",
		"duration": 1,
		"bonus_value": 150.0
	},
	{
		"id": "beer_wild",
		"name": "Пиво: Джокер",
		"description": "Один випадковий тайл стає універсальним на цей блайнд",
		"rarity": "Легендарна",
		"price": 6,
		"blind_effect": "wild_tile",
		"duration": 1,
		"bonus_value": 1.0
	},
	{
		"id": "beer_discount",
		"name": "Пиво: Скидка",
		"description": "-2 до ціни перероллу в магазині (діє 2 блайнди)",
		"rarity": "Історична",
		"price": 2,
		"blind_effect": "reroll_discount",
		"duration": 2,
		"bonus_value": 2.0
	}
]


static func get_random_spirit() -> Spirit:
	var selected_data = _get_weighted_random_item(spirits_data)
	return create_spirit_from_data(selected_data)

static func get_random_beer() -> Beer:
	var selected_data = _get_weighted_random_item(beers_data)
	return create_beer_from_data(selected_data)

static func _get_weighted_random_item(items_array: Array) -> Dictionary:
	var total_weight = 0.0
	var weights = []
	
	for item_data in items_array:
		var rarity = item_data.get("rarity", "Historic")
		var weight = RARITY_WEIGHTS.get(rarity, 50.0)
		weights.append(weight)
		total_weight += weight
	
	var random_value = randf() * total_weight
	
	var cumulative_weight = 0.0
	for i in range(items_array.size()):
		cumulative_weight += weights[i]
		if random_value <= cumulative_weight:
			return items_array[i]
	
	return items_array[0]

static func create_spirit_from_data(data: Dictionary) -> Spirit:
	var s = Spirit.new()
	s.id = data.get("id", "")
	s.name = data.get("name", "")
	s.description = data.get("description", "")
	s.rarity = data.get("rarity", "Historic")
	s.price = data.get("price", 0)
	s.type = "spirit"
	s.effect_type = data.get("effect_type", "")
	s.effect_value = data.get("effect_value", 0.0)
	s.condition = data.get("condition", "")
	s.permanent = true
	s.bonus_value = data.get("bonus_value", 0.0)
	return s

static func create_beer_from_data(data: Dictionary) -> Beer:
	var b = Beer.new()
	b.id = data.get("id", "")
	b.name = data.get("name", "")
	b.description = data.get("description", "")
	b.rarity = data.get("rarity", "Historic")
	b.price = data.get("price", 0)
	b.type = "beer"
	b.blind_effect = data.get("blind_effect", "")
	b.duration = data.get("duration", 1)
	b.bonus_value = data.get("bonus_value", 0.0)
	return b

static func get_random_item() -> Item:
	if randf() < 0.6:  # 60% chance for spirit
		return get_random_spirit()
	else:  # 40% chance for beer
		return get_random_beer()
