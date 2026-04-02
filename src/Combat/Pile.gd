class_name Pile
extends Button

enum PileType {DRAW, DISCARD}

@export var type: PileType = PileType.DRAW
@export var player_pile: bool = true

@onready var cards: Control = $Cards
@onready var highlight: Panel = $Highlight

func _ready() -> void:
	pressed.connect(preview_cards)
	mouse_exited.connect(show_highlight.bind(false))

func load_deck(resources: Array[CardResource]):
	for resource in resources:
		var card = kf.create_card(resource)
		add_card(card)
	shuffle()

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

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# 1. Ensure this pile is actually the Discard pile
	if not player_pile or type != PileType.DISCARD:
		return false
		
	# 2. Check if the dragged data is a token
	if data is not CardToken:
		return(false)
	
	# 3. Only allow dropping if it's a valid token and belongs to the Player
	if data.card_owner == "Player":
		show_highlight(true)
		return true
	
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var card = data.turn_to_card()
	await get_tree().process_frame
	add_card(card)
	ee.emit_signal("move", data)
	show_highlight(false)
	data.current_health = data.max_health

func show_highlight(to_show: bool):
	highlight.visible = to_show

func preview_cards():
	var resources: Array[CardResource]
	for card in cards.get_children():
		resources.append(card.card_resource)
	Bus.ui.load_cards_preview(resources)
