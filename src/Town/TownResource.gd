class_name TownResource
extends Resource

@export var building_spots: int = 10
@export var buildings: Array[BuildingResource]

func dupe() -> TownResource:
	var duped: TownResource = duplicate(true)
	var duped_bldgs: Array[BuildingResource]
	for building in buildings:
		var duped_bldg = building.dupe()
		duped_bldgs.append(duped_bldg)
	duped.buildings = duped_bldgs
	return(duped)
