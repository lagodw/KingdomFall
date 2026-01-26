class_name Combat
extends Control

@onready var draw_pile: Pile = $Draw
@onready var discard_pile: Pile = $Discard

func _ready() -> void:
	load_deck(Bus.deck)

func load_deck(deck: Deck) -> void:
	for res in deck.cards:
		var card = kf.create_card(res)
		draw_pile.add_card(card)
