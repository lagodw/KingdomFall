class_name Town
extends Control

@onready var cards_box: HBoxContainer = %CardsBox

func _ready() -> void:
	load_units()
	Bus.emit_signal("town_loaded")
	
func load_units():
	for res in Bus.deck.cards:
		if res is UnitResource:
			var card = kf.create_card(res)
			cards_box.add_child(card)
