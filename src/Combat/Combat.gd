class_name Combat
extends Control

@onready var deck_choice: PackedScene = preload("uid://bm1r3rnq4vc3w")
@onready var draw_pile: Pile = $Draw
@onready var discard_pile: Pile = $Discard
@onready var energy_txt: Label = $Energy/EnergyText

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
	$CombatWon.choices = Bus.map.current_location.unit_options
	$CombatWon.setup()
	
	if Bus.map.current_location.enemy.is_night_enemy:
		get_tree().paused = true
		var choice = deck_choice.instantiate()
		choice.available_cards = Bus.deck.cards
		add_child(choice)
		Bus.deck_chosen.connect(begin_combat)
	else:
		begin_combat(Bus.player.day_deck)
	Bus.emit_signal("board_loaded")
	
	$Cheat.pressed.connect(combat_won)

func end_turn():
	combat_happening = true
	await Bus.Grid.start_combat()
	combat_happening = false
	await Bus.hand.discard()
	turn_counter += 1
	ee.emit_signal("start_turn", turn_counter)
	draw_pile.draw_cards(5)
	Bus.energy = 3
	update_energy()

func update_energy():
	energy_txt.text = str(Bus.energy)

func game_over():
	combat_over = true
	$GameOver.appear()

func begin_combat(cards: Array[CardResource]):
	$UnitGrid.visible = true
	for resource: CardResource in cards:
		var card: Card = kf.create_card(resource)
		if card.card_resource is UnitResource:
			selected_unit_resources.append(card.card_resource)
		draw_pile.cards.add_child(card)
	
	get_tree().paused = false
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
		if not selected_unit_resources.has(unit) and Bus.map.current_location.enemy.is_night_enemy:
			unit.fatigue -= 5
	#for card in Bus.PlayerGraveyard.get_units():
		#card.card_resource.fatigue += 10
	get_tree().paused = true
	combat_over = true
	$CombatWon.visible = true
