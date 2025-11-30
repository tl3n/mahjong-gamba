extends Node
class_name ItemDatabase

const RARITY_WEIGHTS = {
	"Історична": 50.0,    # 50% chance
	"Historic": 50.0,
	"Міфічна": 30.0,      # 30% chance
	"Mythic": 30.0,
	"Легендарна": 20.0,   # 20% chance
	"Legendary": 20.0
}

# All spirits
static var spirits_data = [
	{
		"id": "spirit_fire",
		"name": "Дух Вогню",
		"description": "Додає +4 до масті Вогню",
		"rarity": "Міфічна",
		"price": 8,
		"effect_type": "mansion_multiplier",
		"effect_value": 4.0,
		"condition": "suit=fire"
	},
	{
		"id": "spirit_wind",
		"name": "Дух Вітру",
		"description": "Додає +2 до всіх мастей",
		"rarity": "Легендарна",
		"price": 10,
		"effect_type": "all_mansion_bonus",
		"effect_value": 2.0,
		"condition": ""
	},
	{
		"id": "spirit_water",
		"name": "Дух Води",
		"description": "Додає +3 до масті Води",
		"rarity": "Міфічна",
		"price": 8,
		"effect_type": "mansion_multiplier",
		"effect_value": 3.0,
		"condition": "suit=water"
	},
	{
		"id": "spirit_earth",
		"name": "Дух Землі",
		"description": "Додає +5 до пар",
		"rarity": "Історична",
		"price": 6,
		"effect_type": "combo_bonus",
		"effect_value": 5.0,
		"condition": "type=pair"
	},
	{
		"id": "spirit_lightning",
		"name": "Дух Блискавки",
		"description": "+1 додатковий хід кожного раунду",
		"rarity": "Легендарна",
		"price": 10,
		"effect_type": "extra_turn",
		"effect_value": 1.0,
		"condition": ""
	},
	{
		"id": "spirit_moon",
		"name": "Дух Місяця",
		"description": "Подвоює очки за понги",
		"rarity": "Міфічна",
		"price": 8,
		"effect_type": "combo_bonus",
		"effect_value": 2.0,
		"condition": "type=pong"
	},
	{
		"id": "spirit_sun",
		"name": "Дух Сонця",
		"description": "+3 монети після кожного раунду",
		"rarity": "Історична",
		"price": 6,
		"effect_type": "money_bonus",
		"effect_value": 3.0,
		"condition": ""
	},
	{
		"id": "spirit_dragon",
		"name": "Дух Дракона",
		"description": "×1.5 до всіх комбінацій",
		"rarity": "Легендарна",
		"price": 10,
		"effect_type": "global_multiplier",
		"effect_value": 1.5,
		"condition": ""
	}
]

static var beers_data = [
	{
		"id": "beer_extra_draw",
		"name": "Пиво: Додатковий добір",
		"description": "Дозволяє тягнути додатковий тайл цього раунду",
		"rarity": "Історична",
		"price": 3,
		"round_effect": "extra_draw",
		"duration": 1,
		"bonus_value": 1.0
	},
	{
		"id": "beer_double_points",
		"name": "Пиво: Подвійні очки",
		"description": "Подвоює всі очки цього раунду",
		"rarity": "Міфічна",
		"price": 4,
		"round_effect": "double_points",
		"duration": 1,
		"bonus_value": 2.0
	},
	{
		"id": "beer_vision",
		"name": "Пиво: Бачення",
		"description": "Показує наступні 3 тайли в колоді",
		"rarity": "Історична",
		"price": 3,
		"round_effect": "reveal_tiles",
		"duration": 1,
		"bonus_value": 3.0
	},
	{
		"id": "beer_fortune",
		"name": "Пиво: Удача",
		"description": "+5 монет після завершення раунду",
		"rarity": "Історична",
		"price": 3,
		"round_effect": "bonus_money",
		"duration": 1,
		"bonus_value": 5.0
	},
	{
		"id": "beer_combo",
		"name": "Пиво: Комбо",
		"description": "Перша комбінація дає ×3 очки",
		"rarity": "Міфічна",
		"price": 4,
		"round_effect": "first_combo_boost",
		"duration": 1,
		"bonus_value": 3.0
	},
	{
		"id": "beer_wild",
		"name": "Пиво: Джокер",
		"description": "Один випадковий тайл стає універсальним",
		"rarity": "Легендарна",
		"price": 5,
		"round_effect": "wild_tile",
		"duration": 1,
		"bonus_value": 1.0
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
	return s

static func create_beer_from_data(data: Dictionary) -> Beer:
	var b = Beer.new()
	b.id = data.get("id", "")
	b.name = data.get("name", "")
	b.description = data.get("description", "")
	b.rarity = data.get("rarity", "Historic")
	b.price = data.get("price", 0)
	b.type = "beer"
	b.round_effect = data.get("round_effect", "")
	b.duration = data.get("duration", 1)
	b.bonus_value = data.get("bonus_value", 0.0)
	return b

static func get_random_item() -> Item:
	if randf() < 0.6:  # 60% chance for spirit
		return get_random_spirit()
	else:  # 40% chance for beer
		return get_random_beer()
