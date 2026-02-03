class_name Deck
extends Resource

@export var sort_deck: bool:
	set(val):
		sort_deck = false
		notify_property_list_changed()
@export var cards: Array[CardResource] = []
@export var graveyard: Array[CardResource] = []

func _init():
	resource_local_to_scene = true
	
## TODO: when this is fixed maybe don't need to dupe
## https://www.reddit.com/r/godot/comments/1425ei3/comment/jn3ayqs/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1
func dupe() -> Deck:
	var new: Deck = self.duplicate(true)
	var blank: Array[CardResource] = []
	new.cards = blank
	for card in cards:
		var duped = card.dupe()
		duped.resource_local_to_scene = true
		new.add_card(duped)
	var blank2: Array[CardResource] = []
	new.graveyard = blank2
	for card in graveyard:
		var duped = card.dupe()
		new.graveyard.append(duped)
	return(new)
	
func add_card(card: CardResource):
	cards.append(card)
	sort()
	
func remove_card(card: CardResource):
	cards.erase(card)

func sort():
	cards.sort_custom(sort_resources)

func _get_property_list() -> Array:
	if Engine.is_editor_hint():
		sort()
	return([])

func sort_resources(data_a: CardResource, data_b: CardResource) -> bool:
	# sort by activation cost -> type -> name
	if data_a.activation == data_b.activation:
		if data_a.card_type == data_b.card_type:
			if data_a.card_name < data_b.card_name:
				return(true)
		# use > so units are before spells
		elif data_a.card_type > data_b.card_type:
			return(true)
	elif data_a.activation < data_b.activation:
		return(true)
	return(false)

## Returns unit resources of all units in deck
func get_units() -> Array[UnitResource]:
	var units: Array[UnitResource]
	for card in cards:
		if card is UnitResource:
			units.append(card)
	return(units)
