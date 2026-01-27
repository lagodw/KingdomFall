class_name Combat
extends Control

@onready var draw_pile: Pile = $Draw
@onready var discard_pile: Pile = $Discard
@onready var energy_txt: Label = $Energy/EnergyText

var turn_counter: int = 0
var combat_happening: bool = false
var combat_over: bool = false

func _ready() -> void:
	Bus.Board = self
	Bus.draw = draw_pile
	Bus.discard = discard_pile
	draw_pile.load_deck(Bus.deck)
	$EndTurn.pressed.connect(end_turn)
	Bus.energy_changed.connect(update_energy)
	end_turn()

func end_turn():
	await Bus.Grid.start_combat()
	$Enemy.on_turn_start(turn_counter)
	await Bus.hand.discard()
	draw_pile.draw_cards(5)
	Bus.energy = 3
	update_energy()
	ee.emit_signal("start_turn", turn_counter)
	turn_counter += 1

func update_energy():
	energy_txt.text = str(Bus.energy)

func game_over():
	$GameOver.appear()
