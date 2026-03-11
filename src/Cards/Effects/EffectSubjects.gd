class_name EffectSubjects
extends Resource

func none() -> Array[Control]:
	return([])

func target(the_target: Control, target_type: String) -> Array[Control]:
	var targets: Array[Control]
	match target_type:
		"Unit", "CardLabel":
			targets.append(the_target)
		# target is TokenSlot
		"Rank":
			for unit in Bus.Grid.get_rank_units(the_target):
				targets.append(unit)
		# target is TokenSlot
		"File":
			for unit in the_target.box.get_units():
				targets.append(unit)
	return(targets)
	
func Board() -> Array[Control]:
	var subjects: Array[Control] = []
	for subject in Bus.Grid.get_units("Player") + Bus.Grid.get_units("Enemy"):
		subjects.append(subject)
	return(subjects)
	
func call_card(calling_card: Card) -> Array[Control]:
	return([calling_card])

func trigger(trigger_card: Control) -> Array[Control]:
	return([trigger_card])

func allied_frontline_box(calling_card: Unit) -> Array[Control]:
	var card_owner = calling_card.card_owner
	return([Bus.Grid.get("%s_front"%card_owner.to_lower())])

func allied_backline_box(calling_card: Unit) -> Array[Control]:
	var card_owner = calling_card.card_owner
	return([Bus.Grid.get("%s_back"%card_owner.to_lower())])

func enemy_frontline_box(calling_card: Unit) -> Array[Control]:
	var card_owner = calling_card.card_owner
	return([Bus.Grid.get("%s_front"%kf.invert_owner(card_owner).to_lower())])

func enemy_backline_box(calling_card: Unit) -> Array[Control]:
	var card_owner = calling_card.card_owner
	return([Bus.Grid.get("%s_back"%kf.invert_owner(card_owner).to_lower())])

func host(host_card: CardToken) -> Array[Control]:
	if host_card:
		return([host_card])
	else:
		return([])
		
func attachments(trigger_card: Control) -> Array[Control]:
	# attachments are stored as Array[Card]
	var attached_cards: Array[Control] = []
	for card in trigger_card.attachments:
		attached_cards.append(card)
	return(attached_cards)
	
func Faces() -> Array[Control]:
	return([Bus.PlayerFace, Bus.EnemyFace])
	
func Decks() -> Array[Control]:
	var subjects: Array[Control] = []
	for label in Bus.PlayerDeck.get_labels() + Bus.EnemyDeck.get_labels():
		# should be label.preview_card?
		subjects.append(label)
	return(subjects)
	
func Hands() -> Array[Control]:
	var subjects: Array[Control]
	for card in Bus.hand.get_children() + Bus.EnemyHand.get_children():
		subjects.append(card)
	return(subjects)

func attack_target(defender: CardToken) -> Array[Control]:
	return([defender])
	
func attacking_unit(attacker: CardToken) -> Array[Control]:
	return([attacker])

func lookup(calling_card: Card, unit_lookup: UnitLookup) -> Array[Control]:
	return(unit_lookup.get_units(calling_card))

func job_occupants(calling_card: JobContainer) -> Array[Control]:
	var occupants: Array[Control]
	for occupant in calling_card.get_occupants():
		occupants.append(occupant)
	return(occupants)
