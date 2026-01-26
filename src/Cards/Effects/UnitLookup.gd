class_name UnitLookup
extends Resource

@export var calling_owner: bool = true
@export_enum("Attack", "Life", "Health") var ranking: String
@export var descending: bool = true
@export var num_units: int = 1

func get_units(calling_card: Card) -> Array[Control]:
	var units: Array[Control] = []
	var grid: UnitGrid
	if calling_owner:
		grid = Bus.get_grid(calling_card.card_owner)
	else:
		grid = Bus.get_grid(kf.invert_owner(calling_card.card_owner))
	var all_units = grid.get_units(calling_card.card_owner)
	var sort_func: Callable = Callable.create(self, "sort_by_%s"%ranking)
	all_units.sort_custom(sort_func)
	for i in num_units:
		if descending:
			units.append(all_units.pop_front())
		else:
			units.append(all_units.pop_back())
	return(units)

func sort_by_Attack(card1: Unit, card2: Unit) -> bool:
	return(card1.current_damage >= card2.current_damage)

func sort_by_Life(card1: Unit, card2: Unit) -> bool:
	return(card1.current_health + card1.current_shield >= 
			card2.current_health + card2.current_shield)

func sort_by_Health(card1: Unit, card2: Unit) -> bool:
	return(card1.current_health >= card2.current_health)
