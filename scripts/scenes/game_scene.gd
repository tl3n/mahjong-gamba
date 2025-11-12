extends Control

@onready var hand_container: HBoxContainer = get_node_or_null("UI/HandContainer")
@onready var open_discard_container: HBoxContainer = get_node_or_null("UI/OpenDiscardContainer")
@onready var score_label: Label = get_node_or_null("UI/ScorePanel/VBoxContainer/ScoreLabel")
@onready var target_label: Label = get_node_or_null("UI/ScorePanel/VBoxContainer/TargetLabel")
@onready var discards_label: Label = get_node_or_null("UI/ControlPanel/DiscardsLabel")
@onready var draw_button: Button = get_node_or_null("UI/ControlPanel/DrawButton")
@onready var play_hand_button: Button = get_node_or_null("UI/ControlPanel/PlayHandButton")

var tile_deck: TileDeck
var game_manager: Node

var hand: Array[Tile] = []
var selected_tile_index: int = -1

var plays_left: int = 3
var discards_left: int = 5
var current_score: int = 0
var is_drawing_phase: bool = true
var just_drawn_index: int = -1

func _ready():
	_check_ui_elements()
	
	tile_deck = TileDeck.new()
	game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		discards_left = game_manager.discards_left
		plays_left = game_manager.rounds_per_blind
	
	if draw_button:
		draw_button.connect("pressed", Callable(self, "_on_draw_button_pressed"))
	if play_hand_button:
		play_hand_button.connect("pressed", Callable(self, "_on_play_hand_pressed"))
	
	_deal_initial_hand()
	_update_ui()
	
	print("\n=== GAME SCENE READY ===")
	print("   Hand size: %d" % hand.size())
	print("   Discards left: %d" % discards_left)
	print("   Plays left: %d" % plays_left)

func _check_ui_elements():
	print("\nChecking UI elements:")
	print("   HandContainer: %s" % ("✅" if hand_container else "MISSING"))
	print("   OpenDiscardContainer: %s" % ("✅" if open_discard_container else "Optional"))
	print("   ScoreLabel: %s" % ("✅" if score_label else "Optional"))
	print("   TargetLabel: %s" % ("✅" if target_label else "Optional"))
	print("   DiscardsLabel: %s" % ("✅" if discards_label else "Optional"))
	print("   DrawButton: %s" % ("✅" if draw_button else "MISSING"))
	print("   PlayHandButton: %s" % ("✅" if play_hand_button else "MISSING"))
	
	if not hand_container:
		print("Creating fallback HandContainer...")
		hand_container = HBoxContainer.new()
		hand_container.name = "HandContainer"
		add_child(hand_container)
		hand_container.position = Vector2(100, get_viewport_rect().size.y - 200)


func _deal_initial_hand():
	hand.clear()
	just_drawn_index = -1
	hand = tile_deck.draw_multiple(13)
	
	print("Dealt initial hand of %d tiles" % hand.size())
	_create_hand_slots()


func _create_hand_slots():
	if not hand_container:
		print(" Cannot create hand slots: HandContainer missing!")
		return
	
	for child in hand_container.get_children():
		child.queue_free()
	
	for i in range(hand.size()):
		var slot = _create_tile_slot(i, hand[i])
		hand_container.add_child(slot)

func _create_tile_slot(index: int, tile: Tile) -> Control:
	var slot = VBoxContainer.new()
	slot.custom_minimum_size = Vector2(70, 110)
	
	var button = Button.new()
	button.custom_minimum_size = Vector2(70, 90)
	button.connect("pressed", Callable(self, "_on_tile_selected").bind(index))
	
	var tile_visual = VBoxContainer.new()
	button.add_child(tile_visual)
	
	if tile:
		var suit_label = Label.new()
		suit_label.text = tile._get_suit_symbol()
		suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		suit_label.add_theme_font_size_override("font_size", 28)
		tile_visual.add_child(suit_label)
		
		var rank_label = Label.new()
		rank_label.text = str(tile.rank)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_font_size_override("font_size", 20)
		tile_visual.add_child(rank_label)
		
		var style = StyleBoxFlat.new()
		style.bg_color = tile.get_suit_color()
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		
		if index == just_drawn_index:
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_color = Color.CHARTREUSE
		
		button.add_theme_stylebox_override("normal", style)
	else:
		var empty_label = Label.new()
		empty_label.text = "?"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile_visual.add_child(empty_label)
	
	slot.add_child(button)
	
	if tile:
		var weight_label = Label.new()
		weight_label.text = "(%d)" % tile.weight
		weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		weight_label.add_theme_font_size_override("font_size", 10)
		slot.add_child(weight_label)
	
	return slot

func _on_tile_selected(index: int):
	if index < 0 or index >= hand.size():
		return
	
	if not hand_container:
		return
	
	for i in range(hand_container.get_child_count()):
		var child = hand_container.get_child(i)
		if child.get_child_count() > 0:
			var button = child.get_child(0)
			button.remove_theme_color_override("font_color")
	
	selected_tile_index = index
	var selected_slot = hand_container.get_child(index)
	if selected_slot.get_child_count() > 0:
		var button = selected_slot.get_child(0)
		button.add_theme_color_override("font_color", Color.YELLOW)
	
	print("Selected tile %d: %s" % [index, hand[index].get_display_text() if hand[index] else "None"])
	
	if not is_drawing_phase:
		_discard_selected_tile()

func _on_draw_button_pressed():
	if not is_drawing_phase:
		print("Not in drawing phase!")
		return
	
	if hand.size() >= 14:
		print("Hand is full!")
		return
	
	var new_tile = tile_deck.draw_tile()
	if new_tile:
		hand.append(new_tile)
		just_drawn_index = hand.size() - 1
		print("Drew tile: %s" % new_tile.get_display_text())
		
		is_drawing_phase = false
		_create_hand_slots()
		_update_ui()

func _discard_selected_tile():
	if selected_tile_index < 0 or selected_tile_index >= hand.size():
		print("No tile selected!")
		return
	
	var tile_to_discard = hand[selected_tile_index]
	if tile_to_discard == null:
		return
	
	tile_deck.discard_to_closed(tile_to_discard)
	hand.remove_at(selected_tile_index)
	selected_tile_index = -1
	
	discards_left -= 1
	
	is_drawing_phase = true
	just_drawn_index = -1
	
	_create_hand_slots()
	_update_ui()
	
	if discards_left <= 0:
		print("   No more discards left for this hand.")

func _on_play_hand_pressed():
	if plays_left <= 0:
		print("No plays left!")
		return
	
	plays_left -= 1 
	print("\n=== PLAYING HAND (%d left) ===" % plays_left)
	
	var combo = ComboDetector.detect_combos(hand)
	
	if combo.is_empty():
		print("No combos found")
	else:
		var base_score = ComboDetector.calculate_score(hand, combo)
		var final_score = ComboDetector.apply_spirit_bonuses(base_score, combo, hand)
		
		current_score += final_score
		
		print("Hand played, Score: +%d (Total: %d)" % [final_score, current_score])
		
		if game_manager:
			game_manager.add_score(final_score)
			
	if current_score >= game_manager.target_score || plays_left <= 0:
		print(" ENDING BLIND ")
		_check_final_score()
		return
		
	discards_left = game_manager.base_discards
	print("   Resetting discards to %d" % discards_left)
	_deal_initial_hand()
	_update_ui()

func _check_final_score():
	print("   Final score: %d" % current_score)
	
	if game_manager:
		if current_score >= game_manager.target_score:
			_end_blind_success()
		else:
			_end_blind_failure() 

func _end_blind_success():
	print("=== BLIND %d COMPLETED ===" % game_manager.current_blind)
	if game_manager:
		game_manager.set_final_stats(discards_left, plays_left)
		game_manager._on_blind_completed()

func _end_blind_failure():
	print("=== GAME OVER ===")
	
	if game_manager:
		game_manager._on_blind_failed()

func _update_ui():
	if discards_label:
		discards_label.text = "Discards left: %d" % discards_left
	
	if score_label:
		score_label.text = "Score: %d" % current_score
	
	if target_label:
		if game_manager:
			target_label.text = "Target: %d" % game_manager.target_score
		else:
			target_label.text = "Target: 600"
	
	if draw_button:
		if not is_drawing_phase:
			draw_button.disabled = true
			draw_button.text = "Discard first"
		elif discards_left <= 0:
			draw_button.disabled = true
			draw_button.text = "No Discards"
		else:
			draw_button.disabled = false
			draw_button.text = "Draw Tile"
	
	if play_hand_button:
		play_hand_button.disabled = (not is_drawing_phase) or (plays_left <= 0)
	
	if open_discard_container:
		_update_open_discard_display()

func _update_open_discard_display():
	if not open_discard_container:
		return
	
	for child in open_discard_container.get_children():
		child.queue_free()
	
	for i in range(tile_deck.open_discard.size()):
		var tile = tile_deck.open_discard[i]
		var slot = _create_discard_tile_slot(i, tile)
		open_discard_container.add_child(slot)

func _create_discard_tile_slot(index: int, tile: Tile) -> Control:
	var button = Button.new()
	button.custom_minimum_size = Vector2(50, 70)
	button.text = tile.get_display_text() if tile else "?"
	
	var style = StyleBoxFlat.new()
	style.bg_color = tile.get_suit_color() if tile else Color.GRAY
	button.add_theme_stylebox_override("normal", style)
	
	button.connect("pressed", Callable(self, "_on_discard_tile_clicked").bind(index))
	return button

func _on_discard_tile_clicked(index: int):
	if not is_drawing_phase:
		print("Can only draw from discard during drawing phase!")
		return
	
	var tile = tile_deck.draw_from_open_discard(index)
	if tile:
		hand.append(tile)
		is_drawing_phase = false
		_create_hand_slots()
		_update_ui()
