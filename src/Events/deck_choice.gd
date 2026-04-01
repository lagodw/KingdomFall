extends Control

@onready var deck_count: Label = %DeckCount
@onready var deck_choice_grid: GridContainer = %DeckChoiceGrid
@onready var card_button = preload("uid://7iyrp623m11p")

# filters for cards during deck choice
enum FilterType { ALL, UNIT, ITEM, CONSUMABLE, SPELL }
var current_filter: FilterType = FilterType.ALL
var hide_fatigued_units: bool = false
var available_cards: Array[CardResource]
var selected_cards: Array[Button]

func _ready() -> void:
	add_deck_choice()
	%ConfirmDeck.pressed.connect(confirm)
	$Filters/UnitFilter.toggled.connect(
			_on_type_filter_toggled.bind(FilterType.UNIT))
	$Filters/SpellFilter.toggled.connect(
			_on_type_filter_toggled.bind(FilterType.SPELL))
	$Filters/ItemFilter.toggled.connect(
			_on_type_filter_toggled.bind(FilterType.ITEM))
	$Filters/ConsumeFilter.toggled.connect(
			_on_type_filter_toggled.bind(FilterType.CONSUMABLE))
	$Filters/FatigueFilter.toggled.connect(
			toggle_fatigued_filter)

func add_deck_choice():
	# Duplicate the deck array so we don't accidentally scramble the underlying deck
	var sorted_cards = available_cards.duplicate()
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

func confirm():
	var cards: Array[CardResource]
	for button: Button in selected_cards:
		var resource: CardResource = button.card.card_resource
		cards.append(resource)
	Bus.emit_signal("deck_chosen", cards)
	queue_free()

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
