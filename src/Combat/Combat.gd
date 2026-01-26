class_name Combat
extends Control

@onready var draw_pile: Pile = $Draw
@onready var discard_pile: Pile = $Discard

func _ready() -> void:
	draw_pile.load_deck(Bus.deck)
	Bus.draw = draw_pile
	Bus.discard = discard_pile
	$EndTurn.pressed.connect(end_turn)
	end_turn()

func end_turn():
	await Bus.hand.discard()
	draw_pile.draw_cards(5)
	
