class_name EnemyResource
extends UnitResource

@export var portrait: Texture
@export var deck: Deck
## cards that will be played in order to start
@export var ordered_cards: Array[CardResource]
## random pool of cards that will be chosen from after ordered cards
@export var random_cards: Array[CardResource]
## Number of cards from random_cards to be added to deck in random order
@export var num_random_cards: int = 0
@export var item_prob: float = 0.0
@export var item_list: Array[ItemResource] 
## Allow each enemy to use different card art without requiring unique resources
@export var card_art_dict: Dictionary[String, String]

@export var num_files: int = 3
@export var num_vanguard: int = 1
@export var num_assault: int = 1
@export var num_support: int = 1

func add_cards() -> void:
	# enemies could be repeated
	deck = deck.dupe()
	for i in num_random_cards:
		if random_cards.size() == 0:
			return
		var card = random_cards.pick_random()
		deck.add_card(card)
		random_cards.erase(card)
	if randf() <= item_prob:
		var item = item_list.pick_random()
		deck.add_card(item)
