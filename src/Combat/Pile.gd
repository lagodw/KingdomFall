class_name Pile
extends Control

@onready var cards: Control = $Cards

func load_deck(deck: Deck):
	for res in deck.cards:
		var card = kf.create_card(res)
		add_card(card)
	shuffle()

func add_card(card: Card):
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
