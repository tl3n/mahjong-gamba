extends Control

@onready var hand_container: HBoxContainer = get_node_or_null("UI/HandContainer")
@onready var open_discard_container: HBoxContainer = get_node_or_null("UI/OpenDiscardContainer")
@onready var score_label: Label = get_node_or_null("UI/ScorePanel/MarginContainer/VBoxContainer/ScoreLabel")
@onready var target_label: Label = get_node_or_null("UI/ScorePanel/MarginContainer/VBoxContainer/TargetLabel")
@onready var blind_label: Label = get_node_or_null("UI/ScorePanel/MarginContainer/VBoxContainer/BlindLabel")
@onready var round_label: Label = get_node_or_null("UI/ScorePanel/MarginContainer/VBoxContainer/RoundLabel")
@onready var combo_score_label: Label = get_node_or_null("UI/ScorePanel/MarginContainer/VBoxContainer/ComboScoreLabel")
@onready var discards_label: Label = get_node_or_null("UI/ControlPanel/MarginContainer/VBoxContainer/DiscardsLabel")
@onready var draw_button: Button = get_node_or_null("UI/ControlPanel/MarginContainer/VBoxContainer/DrawButton")
@onready var play_hand_button: Button = get_node_or_null("UI/ControlPanel/MarginContainer/VBoxContainer/PlayHandButton")
@onready var inventory_button: Button = get_node_or_null("UI/ControlPanel/MarginContainer/VBoxContainer/InventoryButton")
@onready var hint_label: Label = get_node_or_null("UI/HintLabel")
@onready var score_popup: Label = get_node_or_null("UI/ScorePopup")

# Pause menu
@onready var pause_overlay: Panel = get_node_or_null("PauseOverlay")
@onready var resume_button: Button = get_node_or_null("PauseOverlay/CenterContainer/PausePanel/MarginContainer/VBoxContainer/ButtonsContainer/ResumeButton")
@onready var save_button: Button = get_node_or_null("PauseOverlay/CenterContainer/PausePanel/MarginContainer/VBoxContainer/ButtonsContainer/SaveButton")
@onready var main_menu_button: Button = get_node_or_null("PauseOverlay/CenterContainer/PausePanel/MarginContainer/VBoxContainer/ButtonsContainer/MainMenuButton")
@onready var quit_button: Button = get_node_or_null("PauseOverlay/CenterContainer/PausePanel/MarginContainer/VBoxContainer/ButtonsContainer/QuitButton")

# Win screen
@onready var win_overlay: Panel = get_node_or_null("WinOverlay")
@onready var win_score_label: Label = get_node_or_null("WinOverlay/CenterContainer/WinPanel/MarginContainer/VBoxContainer/ScoreLabel")
@onready var win_bonus_label: Label = get_node_or_null("WinOverlay/CenterContainer/WinPanel/MarginContainer/VBoxContainer/BonusLabel")
@onready var win_continue_button: Button = get_node_or_null("WinOverlay/CenterContainer/WinPanel/MarginContainer/VBoxContainer/ContinueButton")

# Lose screen
@onready var lose_overlay: Panel = get_node_or_null("LoseOverlay")
@onready var lose_score_label: Label = get_node_or_null("LoseOverlay/CenterContainer/LosePanel/MarginContainer/VBoxContainer/ScoreLabel")
@onready var lose_blind_label: Label = get_node_or_null("LoseOverlay/CenterContainer/LosePanel/MarginContainer/VBoxContainer/BlindLabel")
@onready var lose_retry_button: Button = get_node_or_null("LoseOverlay/CenterContainer/LosePanel/MarginContainer/VBoxContainer/RetryButton")
@onready var lose_menu_button: Button = get_node_or_null("LoseOverlay/CenterContainer/LosePanel/MarginContainer/VBoxContainer/MainMenuButton")

var is_paused: bool = false
var is_game_ended: bool = false

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
	
	# Pause menu buttons
	if resume_button:
		resume_button.connect("pressed", Callable(self, "_toggle_pause"))
	if save_button:
		save_button.connect("pressed", Callable(self, "_on_save_pressed"))
	if main_menu_button:
		main_menu_button.connect("pressed", Callable(self, "_on_main_menu_pressed"))
	if quit_button:
		quit_button.connect("pressed", Callable(self, "_on_quit_pressed"))
	
	# Win screen buttons
	if win_continue_button:
		win_continue_button.connect("pressed", Callable(self, "_on_win_continue_pressed"))
	
	# Lose screen buttons
	if lose_retry_button:
		lose_retry_button.connect("pressed", Callable(self, "_on_lose_retry_pressed"))
	if lose_menu_button:
		lose_menu_button.connect("pressed", Callable(self, "_on_lose_menu_pressed"))
	
	_deal_initial_hand()
	_update_ui()
	
	# Hide score popup initially
	if score_popup:
		score_popup.modulate.a = 0
	
	# Ensure overlays are hidden
	if pause_overlay:
		pause_overlay.visible = false
	if win_overlay:
		win_overlay.visible = false
	if lose_overlay:
		lose_overlay.visible = false
	
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
	slot.custom_minimum_size = Vector2(68, 100)
	
	var button = Button.new()
	button.custom_minimum_size = Vector2(62, 82)
	
	if is_discard_phase:
		button.connect("pressed", Callable(self, "_on_tile_selected").bind(index))
	else:
		button.disabled = true
	
	var tile_visual = VBoxContainer.new()
	tile_visual.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(tile_visual)
	
	if tile:
		var suit_label = Label.new()
		suit_label.text = tile._get_suit_symbol()
		suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		suit_label.add_theme_font_size_override("font_size", 26)
		suit_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		tile_visual.add_child(suit_label)
		
		var rank_label = Label.new()
		rank_label.text = str(tile.rank)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_font_size_override("font_size", 18)
		rank_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
		tile_visual.add_child(rank_label)
		
		var base_color = tile.get_suit_color()
		var style = StyleBoxFlat.new()
		style.bg_color = base_color.lightened(0.15)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.shadow_color = Color(0, 0, 0, 0.4)
		style.shadow_size = 4
		style.shadow_offset = Vector2(2, 3)
		
		# Base border for all tiles
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = base_color.darkened(0.3)
		
		# Combo highlighting - override border
		if combo_type == "pong":
			style.border_width_top = 4
			style.border_width_bottom = 4
			style.border_width_left = 4
			style.border_width_right = 4
			style.border_color = Color(1.0, 0.75, 0.0)  # Gold for pong
			style.shadow_color = Color(1.0, 0.8, 0.0, 0.5)
			style.shadow_size = 6
		elif combo_type == "pair":
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_color = Color(0.4, 0.7, 1.0)  # Light blue for pair
			style.shadow_color = Color(0.3, 0.6, 1.0, 0.4)
			style.shadow_size = 5
		
		# Hover style
		var hover_style = style.duplicate()
		hover_style.bg_color = base_color.lightened(0.3)
		
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", style)
	else:
		var empty_label = Label.new()
		empty_label.text = "?"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile_visual.add_child(empty_label)
	
	slot.add_child(button)
	
	if tile:
		var weight_label = Label.new()
		weight_label.text = "%d" % tile.weight
		weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		weight_label.add_theme_font_size_override("font_size", 11)
		weight_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.75, 0.9))
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

	# Clear previous selection highlighting and reset scales
	for i in range(hand_container.get_child_count()):
		var child = hand_container.get_child(i)
		if child.get_child_count() > 0:
			# Reset scale with animation
			var tween = create_tween()
			tween.tween_property(child, "scale", Vector2(1.0, 1.0), 0.1)

	selected_tile_index = index
	var selected_slot = hand_container.get_child(index)
	if selected_slot.get_child_count() > 0:
		# Animate selected tile up
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(selected_slot, "scale", Vector2(1.1, 1.1), 0.15)

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
	var final_score = 0
	var combo_name = ""
	
	if combo.is_empty():
		print("No combos found")
		_show_score_popup(0, "No Combo")
	else:
		var base_score = ComboDetector.calculate_score(hand, combo)
		final_score = ComboDetector.apply_spirit_bonuses(base_score, combo, hand)
		combo_name = combo.get("name", "Combo")
		
		if game_manager:
			game_manager.add_score(final_score)
		
		print("Hand played, Score: +%d (Global total: %d)" % [
			final_score, 
			game_manager.current_score if game_manager else 0
		])
		
		_show_score_popup(final_score, combo_name)
	
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
	is_game_ended = true
	
	if game_manager:
		game_manager.set_final_stats(discards_left, plays_left)
	
	# Calculate bonus preview (unused plays + unused discards + base income)
	var bonus = 0
	bonus += plays_left * 1  # Unused plays bonus
	bonus += discards_left * 1  # Unused discards bonus
	bonus += 5  # Base blind income
	
	# Show win screen
	_show_win_screen(bonus)

func _end_round_failure():
	print("=== GAME OVER ===")
	is_game_ended = true
	
	var reached_blind = 1
	if game_manager:
		reached_blind = game_manager.current_blind
	
	# Show lose screen
	_show_lose_screen(reached_blind)

func _show_win_screen(bonus: int):
	if not win_overlay:
		# Fallback to old behavior
		if game_manager:
			game_manager._on_blind_completed()
		return
	
	# Update labels
	if win_score_label and game_manager:
		win_score_label.text = "Score: %d / %d" % [game_manager.current_score, game_manager.target_score]
	
	if win_bonus_label:
		win_bonus_label.text = "+$%d bonus" % bonus
	
	# Show with animation
	win_overlay.visible = true
	win_overlay.modulate.a = 0
	
	var panel = win_overlay.get_node_or_null("CenterContainer/WinPanel")
	if panel:
		panel.scale = Vector2(0.7, 0.7)
		panel.pivot_offset = panel.size / 2
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(win_overlay, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	if panel:
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _show_lose_screen(reached_blind: int):
	if not lose_overlay:
		# Fallback to old behavior
		_perform_game_over_cleanup()
		return
	
	# Update labels
	if lose_score_label and game_manager:
		lose_score_label.text = "Score: %d / %d" % [game_manager.current_score, game_manager.target_score]
	
	if lose_blind_label:
		lose_blind_label.text = "Reached Blind: %d" % reached_blind
	
	# Show with animation
	lose_overlay.visible = true
	lose_overlay.modulate.a = 0
	
	var panel = lose_overlay.get_node_or_null("CenterContainer/LosePanel")
	if panel:
		panel.scale = Vector2(0.7, 0.7)
		panel.pivot_offset = panel.size / 2
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(lose_overlay, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	if panel:
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _perform_game_over_cleanup():
	var save_system = get_node_or_null("/root/SaveSystem")
	
	if save_system and game_manager:
		var reached_blind = game_manager.current_blind
		print("Updating stats: reached blind %d" % reached_blind)
		save_system.update_profile_stats(reached_blind)
	
	if save_system:
		save_system.delete_save()
		print("Save deleted (profile stats kept)")

func _on_win_continue_pressed():
	print("Continuing to shop...")
	if game_manager:
		game_manager._on_blind_completed()

func _on_lose_retry_pressed():
	print("Retrying game...")
	_perform_game_over_cleanup()
	
	# Reset game and start fresh
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("reset_game"):
		gm.reset_game()
	
	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		inventory.spirits.clear()
		inventory.beers.clear()
		inventory.money = 10
		inventory.emit_signal("inventory_changed")
		inventory.emit_signal("money_changed", inventory.money)
	
	get_tree().change_scene_to_file("res://scenes/main/shop_scene.tscn")

func _on_lose_menu_pressed():
	print("Returning to main menu...")
	_perform_game_over_cleanup()
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
	
	# Update hint message
	_update_hint_message()
	
	if open_discard_container:
		_update_open_discard_display()

func _update_hint_message():
	if not hint_label:
		return
	
	if selected_discard_index != -1:
		hint_label.text = "🔄 Select a tile from your hand to swap"
		hint_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	elif selected_tile_index != -1 and discards_left > 0:
		hint_label.text = "🗑️ Press 'Discard' or click another tile"
		hint_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	elif discards_left <= 0 and plays_left > 0:
		hint_label.text = "🎴 No discards left - Play your hand!"
		hint_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	elif plays_left <= 0:
		hint_label.text = "⏳ Round ending..."
		hint_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.5))
	elif tile_deck.open_discard.size() > 0:
		hint_label.text = "💡 Select a tile to discard, swap from open discard, or play"
		hint_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.9))
	else:
		hint_label.text = "💡 Select a tile to discard or play your hand"
		hint_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.9))

func _show_score_popup(score: int, combo_name: String):
	if not score_popup:
		return
	
	# Set text
	if score > 0:
		score_popup.text = "+%d\n%s" % [score, combo_name]
		score_popup.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	else:
		score_popup.text = "No Score\n%s" % combo_name
		score_popup.add_theme_color_override("font_color", Color(0.7, 0.5, 0.4))
	
	# Animate popup
	score_popup.modulate.a = 0
	score_popup.scale = Vector2(0.5, 0.5)
	score_popup.pivot_offset = score_popup.size / 2
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in and scale up
	tween.tween_property(score_popup, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_popup, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Wait then fade out
	tween.chain().tween_interval(1.0)
	tween.chain().tween_property(score_popup, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.chain().tween_property(score_popup, "scale", Vector2(1.2, 1.2), 0.5)

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
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(52, 70)
	
	var button = Button.new()
	button.custom_minimum_size = Vector2(48, 62)
	
	var tile_visual = VBoxContainer.new()
	tile_visual.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(tile_visual)
	
	if tile:
		var suit_label = Label.new()
		suit_label.text = tile._get_suit_symbol()
		suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		suit_label.add_theme_font_size_override("font_size", 20)
		suit_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		tile_visual.add_child(suit_label)
		
		var rank_label = Label.new()
		rank_label.text = str(tile.rank)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_font_size_override("font_size", 14)
		rank_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
		tile_visual.add_child(rank_label)
	
	var base_color = tile.get_suit_color() if tile else Color.GRAY
	var style = StyleBoxFlat.new()
	style.bg_color = base_color.lightened(0.1).darkened(0.1)  # Slightly muted
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 3
	style.shadow_offset = Vector2(1, 2)
	
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = base_color.darkened(0.4)
	
	# Highlight selected discard tile
	if index == selected_discard_index:
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_color = Color(1.0, 0.9, 0.3)
		style.shadow_color = Color(1.0, 0.85, 0.0, 0.6)
		style.shadow_size = 6
	
	var hover_style = style.duplicate()
	hover_style.bg_color = base_color.lightened(0.2)
	
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.connect("pressed", Callable(self, "_on_discard_tile_clicked").bind(index))
	
	container.add_child(button)
	return container

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

# Keyboard shortcuts
func _input(event):
	# Don't process input if game has ended
	if is_game_ended:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				# Toggle pause menu
				_toggle_pause()
			KEY_SPACE:
				# Play hand with spacebar (only when not paused)
				if not is_paused and play_hand_button and not play_hand_button.disabled:
					_on_play_hand_pressed()
			KEY_ENTER:
				# Confirm discard with Enter (only when not paused)
				if not is_paused and draw_button and not draw_button.disabled:
					_on_discard_confirm_pressed()
			KEY_I:
				# Open inventory (only when not paused)
				if not is_paused:
					_on_inventory_pressed()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				# Quick select tiles 1-9 (only when not paused)
				if not is_paused:
					var tile_index = event.keycode - KEY_1
					if tile_index < hand.size() and is_discard_phase:
						_on_tile_selected(tile_index)
			KEY_0:
				# Select tile 10 (only when not paused)
				if not is_paused and 9 < hand.size() and is_discard_phase:
					_on_tile_selected(9)
			KEY_MINUS:
				# Select tile 11 (only when not paused)
				if not is_paused and 10 < hand.size() and is_discard_phase:
					_on_tile_selected(10)
			KEY_EQUAL:
				# Select tile 12 (only when not paused)
				if not is_paused and 11 < hand.size() and is_discard_phase:
					_on_tile_selected(11)
			KEY_BACKSPACE:
				# Select tile 13 (only when not paused)
				if not is_paused and 12 < hand.size() and is_discard_phase:
					_on_tile_selected(12)

# Pause Menu Functions
func _toggle_pause():
	is_paused = not is_paused
	
	if pause_overlay:
		if is_paused:
			_show_pause_menu()
		else:
			_hide_pause_menu()

func _show_pause_menu():
	if not pause_overlay:
		return
	
	pause_overlay.visible = true
	pause_overlay.modulate.a = 0
	
	# Get the panel for animation
	var panel = pause_overlay.get_node_or_null("CenterContainer/PausePanel")
	if panel:
		panel.scale = Vector2(0.8, 0.8)
		panel.pivot_offset = panel.size / 2
	
	# Animate in
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pause_overlay, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	if panel:
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _hide_pause_menu():
	if not pause_overlay:
		return
	
	var panel = pause_overlay.get_node_or_null("CenterContainer/PausePanel")
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pause_overlay, "modulate:a", 0.0, 0.15).set_ease(Tween.EASE_IN)
	if panel:
		tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.15).set_ease(Tween.EASE_IN)
	
	tween.chain().tween_callback(func(): pause_overlay.visible = false)

func _on_save_pressed():
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		# Save current game state
		if game_manager:
			game_manager.set_final_stats(discards_left, plays_left)
		save_system.save_game()
		print("Game saved!")
		
		# Show feedback
		if save_button:
			save_button.text = "✓ Saved!"
			await get_tree().create_timer(1.0).timeout
			save_button.text = "💾 Save & Continue"

func _on_main_menu_pressed():
	# Save before leaving
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		if game_manager:
			game_manager.set_final_stats(discards_left, plays_left)
		save_system.save_game()
	
	is_paused = false
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_quit_pressed():
	# Save before quitting
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		if game_manager:
			game_manager.set_final_stats(discards_left, plays_left)
		save_system.save_game()
	
	get_tree().quit()
