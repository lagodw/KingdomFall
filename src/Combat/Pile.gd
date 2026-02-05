class_name Pile
extends Control

@onready var cards: Control = $Cards

func load_deck(resources: Array[CardResource]):
	for resource in resources:
		var card = kf.create_card(resource)
		add_card(card)
	shuffle()

#func add_card(card: Card):
	#cards.add_child(card)

func add_card(card: Card, animation: bool = true):
	if animation:
		await card.move_to(self)
	card.get_parent().remove_child(card)
	cards.add_child(card)

func shuffle():
	var all_cards: Array = cards.get_children()
	all_cards.shuffle()
	for card in all_cards:
		cards.move_child(card, 0)

func draw_cards(num: int):
	for i in num:
		if cards.get_child_count() == 0:
			await Bus.discard.shuffle_discard()
		if cards.get_child_count() == 0:
			return
		var card = cards.get_child(0)
		Bus.hand.draw_card(card)
		
func shuffle_discard():
	shuffle()
	for card in cards.get_children():
		card.move_to(Bus.draw.cards, false)
	await get_tree().process_frame
	await get_tree().process_frame

func get_cards() -> Array[Card]:
	var card_array: Array[Card]
	for child in cards.get_children():
		card_array.append(child)
	return(card_array)
	
func get_units() -> Array[Unit]:
	var units: Array[Unit]
	for child in cards.get_children():
		if child is Unit:
			units.append(child)
	return(units)
