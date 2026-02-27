class_name Combat
extends Control

@onready var card_button = preload("uid://7iyrp623m11p")
@onready var draw_pile: Pile = $Draw
@onready var discard_pile: Pile = $Discard
@onready var energy_txt: Label = $Energy/EnergyText
@onready var deck_count: Label = %DeckCount

var turn_counter: int = 0
var combat_happening: bool = false
var combat_over: bool = false
var selected_cards: Array[Button]
var selected_unit_resources: Array[UnitResource]

func _ready() -> void:
	Bus.Board = self
	Bus.draw = draw_pile
	Bus.discard = discard_pile
	Bus.PlayerGraveyard = $PlayerGraveyard
	Bus.EnemyGraveyard = $EnemyGraveyard
	$EndTurn.pressed.connect(end_turn)
	Bus.energy_changed.connect(update_energy)
	Bus.energy = 3
	$%ConfirmDeck.pressed.connect(begin_combat)
	add_deck_choice()
	get_tree().paused = true
	$DeckChoice.visible = true
	Bus.emit_signal("board_loaded")
	
	#$DeckChoice.visible = false
	#combat_won()

func add_deck_choice():
	for resource in Bus.deck.cards:
		var card = kf.create_card(resource)
		var button = card_button.instantiate()
		button.card = card
		button.add_child(card)
		button.pressed.connect(select_card.bind(button))
		%DeckChoiceGrid.add_child(button)
		
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
	draw_pile.draw_cards(5)
	Bus.energy = 3
	update_energy()
	ee.emit_signal("start_turn", turn_counter)
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
	# wait for last units to tween
	# TODO: hide remaining cards instead
	await get_tree().create_timer(kf.tween_time*1.5).timeout
	for card in Bus.hand.get_children():
		card.queue_free()
	for unit in Bus.deck.get_units():
		if selected_unit_resources.has(unit):
			unit.fatigue += 5
		else:
			unit.fatigue -= 5
	for card in Bus.PlayerGraveyard.get_units():
		card.card_resource.fatigue += 10
	get_tree().paused = true
	combat_over = true
	$CombatWon.visible = true
