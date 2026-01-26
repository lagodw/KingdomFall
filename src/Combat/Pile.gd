class_name Pile
extends Control

@onready var cards: Control = $Cards

func add_card(card: Card):
	cards.add_child(card)
