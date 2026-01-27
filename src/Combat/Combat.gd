class_name Combat
extends Control

@onready var draw_pile: Pile = $Draw
@onready var discard_pile: Pile = $Discard

var turn_counter: int = 0
var combat_happening: bool = false
var combat_over: bool = false

func _ready() -> void:
	Bus.Board = self
	Bus.draw = draw_pile
	Bus.discard = discard_pile
	draw_pile.load_deck(Bus.deck)
	$EndTurn.pressed.connect(end_turn)
	end_turn()

func end_turn():
	await Bus.Grid.start_combat()
	$Enemy.on_turn_start(turn_counter)
	await Bus.hand.discard()
	draw_pile.draw_cards(5)
	ee.emit_signal("start_turn", turn_counter)
	turn_counter += 1
