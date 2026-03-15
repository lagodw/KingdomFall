class_name Combat
extends Control

@onready var card_button = preload("uid://7iyrp623m11p")
@onready var draw_pile: Pile = $Draw
@onready var discard_pile: Pile = $Discard
@onready var energy_txt: Label = $Energy/EnergyText
@onready var deck_count: Label = %DeckCount
@onready var deck_choice_grid: GridContainer = %DeckChoiceGrid

var turn_counter: int = 0
var combat_happening: bool = false
var combat_over: bool = false
var selected_cards: Array[Button]
var selected_unit_resources: Array[UnitResource]

# filters for cards during deck choice
enum FilterType { ALL, UNIT, ITEM, CONSUMABLE, SPELL }
var current_filter: FilterType = FilterType.ALL
var hide_fatigued_units: bool = false

func _ready() -> void:
	Bus.Board = self
	Bus.draw = draw_pile
	Bus.discard = discard_pile
	Bus.PlayerGraveyard = $PlayerGraveyard
	Bus.EnemyGraveyard = $EnemyGraveyard
	$EndTurn.pressed.connect(end_turn)
	Bus.energy_changed.connect(update_energy)
	Bus.energy = 3
	%ConfirmDeck.pressed.connect(begin_combat)
	$CombatWon.choices = Bus.map.current_location.unit_options
	$CombatWon.setup()
	$DeckChoice/Filters/UnitFilter.toggled.connect(
			_on_type_filter_toggled.bind(FilterType.UNIT))
	$DeckChoice/Filters/SpellFilter.toggled.connect(
			_on_type_filter_toggled.bind(FilterType.SPELL))
	$DeckChoice/Filters/ItemFilter.toggled.connect(
			_on_type_filter_toggled.bind(FilterType.ITEM))
	$DeckChoice/Filters/ConsumeFilter.toggled.connect(
			_on_type_filter_toggled.bind(FilterType.CONSUMABLE))
	$DeckChoice/Filters/FatigueFilter.toggled.connect(
			toggle_fatigued_filter)
	
	add_deck_choice()
	get_tree().paused = true
	$DeckChoice.visible = true
	Bus.emit_signal("board_loaded")
	
	$Cheat.pressed.connect(combat_won)

func add_deck_choice():
	# Duplicate the deck array so we don't accidentally scramble the underlying deck
	var sorted_cards = Bus.deck.cards.duplicate()
	sorted_cards.sort_custom(sort_deck)
	
	for resource in sorted_cards:
		var card = kf.create_card(resource)
		var button = card_button.instantiate()
		button.card = card
		button.add_child(card)
		button.pressed.connect(select_card.bind(button))
		deck_choice_grid.add_child(button)
		
	# Make sure filters apply properly on initial load
	apply_filters()
		
func select_card(button: Button):
	if selected_cards.has(button):
		selected_cards.erase(button)
		button.selected = false
	else:
		selected_cards.append(button)
		button.selected = true
	%DeckCount.text = str(selected_cards.size())

func end_turn():
	combat_happening = true
	await Bus.Grid.start_combat()
	combat_happening = false
	await Bus.hand.discard()
	ee.emit_signal("start_turn", turn_counter)
	draw_pile.draw_cards(5)
	Bus.energy = 3
	update_energy()
	turn_counter += 1

func update_energy():
	energy_txt.text = str(Bus.energy)

func game_over():
	combat_over = true
	$GameOver.appear()

func begin_combat():
	$UnitGrid.visible = true
	for button: Button in selected_cards:
		var card: Card = button.card
		if card.card_resource is UnitResource:
			selected_unit_resources.append(card.card_resource)
		var old_pos: Vector2 = card.global_position
		card.get_parent().remove_child(card)
		add_child(card)
		card.global_position = old_pos
		card.move_to(draw_pile.cards)
	
	$DeckChoice.visible = false
	get_tree().paused = false
		
	await get_tree().create_timer(kf.tween_time * 1.5).timeout
	draw_pile.shuffle()
	end_turn()

func combat_won():
	if Bus.map.current_location.enemy.is_final_enemy:
		kf.load_scene("uid://b5u1o6v1y4j3i")
		return
	# wait for last units to tween
	# TODO: hide remaining cards instead
	await get_tree().create_timer(kf.tween_time*1.5).timeout
	for card in Bus.hand.get_children():
		card.queue_free()
	for unit in Bus.deck.get_units():
		if not selected_unit_resources.has(unit):
			unit.fatigue -= 5
	#for card in Bus.PlayerGraveyard.get_units():
		#card.card_resource.fatigue += 10
	get_tree().paused = true
	combat_over = true
	$CombatWon.visible = true

func sort_deck(a: CardResource, b: CardResource) -> bool:
	var a_is_unit = a is UnitResource
	var b_is_unit = b is UnitResource
	
	# 1. Units always come first
	if a_is_unit and not b_is_unit:
		return true
	elif not a_is_unit and b_is_unit:
		return false
		
	# 2. If both are units, check fatigue
	elif a_is_unit and b_is_unit:
		if a.fatigue != b.fatigue:
			return a.fatigue < b.fatigue
		# If fatigue is equal, we let the code fall through to the alphabetical check below

	# 3. Fallback: Sort alphabetically by card_name
	# (This handles units with tied fatigue, and all non-unit cards)
	return a.card_name < b.card_name
	
func _on_type_filter_toggled(toggled_on: bool, type: FilterType):
	if toggled_on:
		# A specific filter was turned on
		current_filter = type
	else:
		# The active filter was turned off, revert to showing everything
		current_filter = FilterType.ALL
		
	apply_filters()

func toggle_fatigued_filter(toggled_on: bool):
	hide_fatigued_units = toggled_on
	apply_filters()

func apply_filters():
	for button in deck_choice_grid.get_children():
		var card_res = button.card.card_resource
		var is_card_visible = true
		
		# 1. Check Card Type Filter
		match current_filter:
			FilterType.UNIT:
				if not card_res is UnitResource: is_card_visible = false
			FilterType.ITEM:
				if not card_res is ItemResource: is_card_visible = false
			FilterType.CONSUMABLE:
				if not card_res is ConsumeResource: is_card_visible = false
			FilterType.SPELL:
				if not card_res is SpellResource: is_card_visible = false
				
		# 2. Check Fatigue Filter
		if hide_fatigued_units and card_res is UnitResource:
			# Assuming a unit with fatigue > 0 is considered fatigued
			if card_res.fatigue > 0:
				is_card_visible = false
				
		button.visible = is_card_visible
