extends Control

@onready var hand_container: HBoxContainer = get_node_or_null("UI/HandContainer")
@onready var open_discard_container: HBoxContainer = get_node_or_null("UI/OpenDiscardContainer")
@onready var score_label: Label = get_node_or_null("UI/ScorePanel/VBoxContainer/ScoreLabel")
@onready var target_label: Label = get_node_or_null("UI/ScorePanel/VBoxContainer/TargetLabel")
@onready var blind_label: Label = get_node_or_null("UI/ScorePanel/VBoxContainer/BlindLabel")
@onready var round_label: Label = get_node_or_null("UI/ScorePanel/VBoxContainer/RoundLabel")
@onready var combo_score_label: Label = get_node_or_null("UI/ScorePanel/VBoxContainer/ComboScoreLabel")
@onready var discards_label: Label = get_node_or_null("UI/ControlPanel/DiscardsLabel")
@onready var draw_button: Button = get_node_or_null("UI/ControlPanel/DrawButton")
@onready var play_hand_button: Button = get_node_or_null("UI/ControlPanel/PlayHandButton")
@onready var inventory_button: Button = get_node_or_null("UI/ControlPanel/InventoryButton")

var tile_deck: TileDeck
var game_manager: Node

var hand: Array[Tile] = []
var selected_tile_index: int = -1
var selected_discard_index: int = -1  # For swapping with open discard

var plays_left: int = 3
var discards_left: int = 5
var is_discard_phase: bool = true 


func _ready():
	_check_ui_elements()
	
	tile_deck = TileDeck.new()
	game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		discards_left = game_manager._recalculate_discards()
		plays_left = game_manager._recalculate_rounds()
		
		print("Starting game with:")
		print("   Discards: %d" % discards_left)
		print("   Plays: %d" % plays_left)
	
	if draw_button:
		draw_button.connect("pressed", Callable(self, "_on_discard_confirm_pressed"))
	if play_hand_button:
		play_hand_button.connect("pressed", Callable(self, "_on_play_hand_pressed"))
	if inventory_button:
		inventory_button.connect("pressed", Callable(self, "_on_inventory_pressed"))
	
	_deal_initial_hand()
	_update_ui()
	
	print("\n=== GAME SCENE READY ===")
	print("   Hand size: %d" % hand.size())
	print("   Discards left: %d" % discards_left)
	print("   Plays left: %d" % plays_left)

func _on_inventory_pressed():
	print("Opening inventory...")
	
	if has_node("InventoryPopup"):
		get_node("InventoryPopup").queue_free()
		return
	
	var inv_scene = load("res://scenes/ui/inventory.tscn")
	if inv_scene:
		var inv_instance = inv_scene.instantiate()
		inv_instance.name = "InventoryPopup" 
		add_child(inv_instance)
		
		if inv_instance is Control:
			var viewport_size = get_viewport_rect().size
			inv_instance.position = Vector2(viewport_size.x - 820, 200)
			inv_instance.custom_minimum_size = Vector2(400, 550)
			
			var sell_btn = inv_instance.get_node_or_null("HBoxContainer/VBoxContainer/Buttons/Sell")
			if sell_btn:
				sell_btn.visible = false
				

func _check_ui_elements():
	print("\nChecking UI elements:")
	print("   HandContainer: %s" % ("✅" if hand_container else "MISSING"))
	print("   OpenDiscardContainer: %s" % ("✅" if open_discard_container else "Optional"))
	print("   ScoreLabel: %s" % ("✅" if score_label else "Optional"))
	print("   TargetLabel: %s" % ("✅" if target_label else "Optional"))
	print("   DiscardsLabel: %s" % ("✅" if discards_label else "Optional"))
	print("   BlindLabel: %s" % ("✅" if blind_label else "Optional"))
	print("   RoundLabel: %s" % ("✅" if round_label else "Optional"))
	print("   DrawButton: %s" % ("✅" if draw_button else "MISSING"))
	print("   PlayHandButton: %s" % ("✅" if play_hand_button else "MISSING"))
	
	if not hand_container:
		print("Creating fallback HandContainer...")
		hand_container = HBoxContainer.new()
		hand_container.name = "HandContainer"
		hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(hand_container)
		var viewport_size = get_viewport_rect().size
		hand_container.position = Vector2(viewport_size.x / 2 - 500, viewport_size.y - 130)

func _deal_initial_hand():
	hand.clear()
	selected_tile_index = -1
	selected_discard_index = -1
	hand = tile_deck.draw_multiple(13) 
	is_discard_phase = true  
	hand.sort_custom(Callable(Tile, "_sort_criterion"))
	
	print("Dealt initial hand of %d tiles" % hand.size())
	_create_hand_slots()

func _create_hand_slots():
	if not hand_container:
		print("Cannot create hand slots: HandContainer missing!")
		return
	
	for child in hand_container.get_children():
		child.queue_free()
	
	# Get combo highlighting info
	var combo_info = ComboDetector.get_combo_highlight_info(hand)
	
	for i in range(hand.size()):
		var combo_type = combo_info[i] if i < combo_info.size() else ""
		var slot = _create_tile_slot(i, hand[i], combo_type)
		hand_container.add_child(slot)

func _create_tile_slot(index: int, tile: Tile, combo_type: String = "") -> Control:
	var slot = VBoxContainer.new()
	slot.custom_minimum_size = Vector2(70, 110)
	
	var button = Button.new()
	button.custom_minimum_size = Vector2(70, 90)
	
	if is_discard_phase:
		button.connect("pressed", Callable(self, "_on_tile_selected").bind(index))
	else:
		button.disabled = true
	
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
		
		# Combo highlighting
		if combo_type == "pong":
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_color = Color(1.0, 0.84, 0.0)  # Gold for pong
		elif combo_type == "pair":
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_color = Color(0.6, 0.8, 1.0)  # Light blue for pair
		
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

	if not is_discard_phase:
		print("Cannot select, not in discard phase")
		return

	if not hand_container:
		return

	# If a discard tile is selected, perform swap
	if selected_discard_index >= 0:
		_swap_with_discard(index)
		return

	# Clear previous selection highlighting
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

	_update_ui()

func _discard_selected_tile():
	if selected_tile_index < 0 or selected_tile_index >= hand.size():
		print("No tile selected!")
		return
	
	var tile_to_discard = hand[selected_tile_index]
	if tile_to_discard == null:
		return
	
	print("Discarding tile: %s" % tile_to_discard.get_display_text())
	# Discarded tiles during turn go to OPEN discard (visible to player)
	tile_deck.discard_to_open(tile_to_discard)
	hand.remove_at(selected_tile_index)
	
	selected_tile_index = -1
	discards_left -= 1
	
	is_discard_phase = false  
	
	_create_hand_slots()
	_update_ui()
	
	if discards_left <= 0:
		print("   No more discards left for this hand.")

func _on_play_hand_pressed():
	if plays_left <= 0:
		print("No plays left")
		return
	
	if hand.size() != 13:
		print("Must have exactly 13 tiles to play! Current: %d" % hand.size())
		return
	
	game_manager.current_round+=1
	
	plays_left -= 1 
	print("\n=== PLAYING HAND (%d left) ===" % plays_left)
	
	var combo = ComboDetector.detect_combos(hand)
	
	if combo.is_empty():
		print("No combos found")
	else:
		var base_score = ComboDetector.calculate_score(hand, combo)
		var final_score = ComboDetector.apply_spirit_bonuses(base_score, combo, hand)
		
		if game_manager:
			game_manager.add_score(final_score)
		
		print("Hand played, Score: +%d (Global total: %d)" % [
			final_score, 
			game_manager.current_score if game_manager else 0
		])
	
	# After playing hand, ALL tiles go to closed discard
	_discard_hand_to_closed()
	
	var should_end = false
	if game_manager:
		should_end = (game_manager.current_score >= game_manager.target_score) or (plays_left <= 0)
	else:
		should_end = (plays_left <= 0)
	
	if should_end:
		print("ENDING BLIND")
		_check_final_score()
		return
	
	if game_manager:
		discards_left = game_manager._recalculate_discards()
	else:
		discards_left = 5
	
	print("   Resetting discards to %d" % discards_left)
	_deal_initial_hand()
	_update_ui()

# Discard entire hand to closed discard (after playing)
func _discard_hand_to_closed():
	print("   Discarding entire hand to closed discard...")
	var count = hand.size()
	for tile in hand:
		if tile:
			tile_deck.discard_to_closed(tile)
	hand.clear()
	print("   %d tiles discarded to closed" % count)

func _check_final_score():
	if not game_manager:
		print("GameManager not found")
		return
	
	var actual_score = game_manager.current_score
	var target = game_manager.target_score
	
	print("   Final score check: %d / %d" % [actual_score, target])
	
	if actual_score >= target:
		print("   Target reached!")
		_end_round_success()
	else:
		print("   Target not reached")
		_end_round_failure() 

func _end_round_success():
	print("=== BLIND %d COMPLETED ===" % game_manager.current_blind)
	
	if game_manager:
		game_manager.set_final_stats(discards_left, plays_left)
		game_manager._on_blind_completed()

func _end_round_failure():
	print("=== GAME OVER ===")
	
	var save_system = get_node_or_null("/root/SaveSystem")
	
	if save_system and game_manager:
		var reached_blind = game_manager.current_blind
		print("Updating stats: reached blind %d" % reached_blind)
		save_system.update_profile_stats(reached_blind)
	else:
		print("ERROR: Cannot update stats - SaveSystem or GameManager not found!")
		if not save_system:
			print("  SaveSystem is null")
		if not game_manager:
			print("  GameManager is null")
	
	print("Deleting save file")
	if save_system:
		save_system.delete_save()
		print("Save deleted (profile stats kept)")
	
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_game_over_signal():
	_end_round_failure()
	
func _draw_tile():
	if hand.size() >= 13:
		print("Hand is full, cannot draw new tile.")
		return

	var new_tile = tile_deck.draw_tile()
	if new_tile:
		hand.append(new_tile)
		print("   Drew tile: %s" % new_tile.get_display_text())
	else:
		print("   Deck is empty!")
		
func _on_discard_confirm_pressed():
	if selected_tile_index < 0 or selected_tile_index >= hand.size():
		print("No tile selected to discard!")
		return

	if discards_left <= 0:
		print("No discards left!")
		return

	print("Confirming discard...")

	var tile_to_discard = hand.pop_at(selected_tile_index)
	# Discarded tiles during turn go to OPEN discard (visible to player)
	tile_deck.discard_to_open(tile_to_discard)
	discards_left -= 1

	selected_tile_index = -1

	_draw_tile() 
	hand.sort_custom(Callable(Tile, "_sort_criterion"))
	_create_hand_slots()
	_update_ui()

	if discards_left <= 0:
		print("   No more discards left for this hand.")
		
func _update_ui():
	if discards_label:
		discards_label.text = "Discards left: %d" % discards_left
	
	if score_label:
		var display_score = game_manager.current_score if game_manager else 0
		score_label.text = "Score: %d" % display_score
	
	if target_label:
		if game_manager:
			target_label.text = "Target: %d" % game_manager.target_score
		else:
			target_label.text = "Target: 600"
	
	if blind_label:
		if game_manager:
			blind_label.text = "Current Blind: %d" % game_manager.current_blind
		else:
			blind_label.text = "Current Blind: 1"
			
	if round_label:
		round_label.text = "Rounds left: %d" % plays_left
	
	# Update current combo score preview
	if combo_score_label:
		var combo = ComboDetector.detect_combos(hand)
		if combo.is_empty():
			combo_score_label.text = "Combo: None (+0)"
		else:
			var base_score = ComboDetector.calculate_score(hand, combo)
			var final_score = ComboDetector.apply_spirit_bonuses(base_score, combo, hand)
			var combo_name = combo.get("name", "?")
			combo_score_label.text = "Combo: %s (+%d)" % [combo_name, final_score]
	
	if draw_button:
		if is_discard_phase and selected_discard_index != -1:
			# Discard tile selected, waiting for hand tile to swap
			draw_button.text = "Select Hand Tile"
			draw_button.disabled = true
		elif is_discard_phase and selected_tile_index != -1 and discards_left > 0:
			draw_button.text = "Discard Tile"
			draw_button.disabled = false
		elif discards_left <= 0:
			draw_button.text = "No Discards"
			draw_button.disabled = true
		else:
			draw_button.disabled = true 
			draw_button.text = "Select Tile"
	
	if play_hand_button:
		play_hand_button.disabled = (not is_discard_phase) or (plays_left <= 0) or (hand.size() != 13)
	
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
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	# Highlight selected discard tile
	if index == selected_discard_index:
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_color = Color.YELLOW
	
	button.add_theme_stylebox_override("normal", style)
	
	button.connect("pressed", Callable(self, "_on_discard_tile_clicked").bind(index))
	return button

func _on_discard_tile_clicked(index: int):
	if not is_discard_phase:
		print("Can only interact with discard during discard phase!")
		return
	
	if discards_left <= 0:
		print("No discards left to swap!")
		return
	
	if index < 0 or index >= tile_deck.open_discard.size():
		print("Invalid discard index!")
		return
	
	# If clicking the same discard tile, deselect it
	if selected_discard_index == index:
		selected_discard_index = -1
		print("Deselected discard tile")
		_update_ui()
		return
	
	# Clear hand selection when selecting from discard
	selected_tile_index = -1
	selected_discard_index = index
	
	var tile = tile_deck.open_discard[index]
	print("Selected discard tile %d: %s - Now select a hand tile to swap" % [index, tile.get_display_text() if tile else "?"])
	
	_update_ui()

# Swap a hand tile with the selected discard tile
func _swap_with_discard(hand_index: int):
	if selected_discard_index < 0 or selected_discard_index >= tile_deck.open_discard.size():
		print("No valid discard tile selected!")
		return
	
	if hand_index < 0 or hand_index >= hand.size():
		print("Invalid hand index!")
		return
	
	if discards_left <= 0:
		print("No discards left!")
		return
	
	var hand_tile = hand[hand_index]
	var discard_tile = tile_deck.draw_from_open_discard(selected_discard_index)
	
	print("Taking from open discard: [%s], discarding to closed: [%s]" % [
		discard_tile.get_display_text() if discard_tile else "?",
		hand_tile.get_display_text() if hand_tile else "?"
	])
	
	# Take tile from open discard into hand
	hand[hand_index] = discard_tile
	
	# Hand tile goes to CLOSED discard
	tile_deck.discard_to_closed(hand_tile)
	
	# This counts as a discard
	discards_left -= 1
	
	# Clear selections
	selected_discard_index = -1
	selected_tile_index = -1
	
	_create_hand_slots()
	_update_ui()
	
	print("Swap complete! Discards left: %d" % discards_left)
	
	if discards_left <= 0:
		print("   No more discards left for this hand.")
