class_name BuildingResource
extends Resource

@export var building_name: String
@export var capacity: int = 1
@export var construction_cost: int = 5
@export var current_construction: int = 0
@export var description: String



func dupe() -> BuildingResource:
	var duped: BuildingResource = duplicate(true)
	return(duped)
