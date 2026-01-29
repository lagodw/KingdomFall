class_name BuildingResource
extends Resource

@export var building_name: String
@export var capacity: int = 1
@export var construction_cost: int = 5
@export var current_construction: int = 0
@export var description: String
@export var effects: Array[Effect]


func dupe() -> BuildingResource:
	var duped: BuildingResource = duplicate(true)
	var duped_effects: Array[Effect]
	for effect in effects:
		duped_effects.append(effect.dupe())
	duped.effects = duped_effects
	return(duped)
