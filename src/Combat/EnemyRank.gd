class_name EnemyRank
extends Resource

@export var units: Array[UnitResource]

func dupe() -> EnemyRank:
	var duped: EnemyRank = duplicate(true)
	var duped_units: Array[UnitResource]
	for unit in units:
		duped_units.append(unit.dupe())
	duped.units = duped_units
	return(duped)
