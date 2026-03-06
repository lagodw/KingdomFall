class_name EnemyResource
extends Resource

## key denotes what turn number the rank will be deployed on
@export var ranks: Array[EnemyRank]
@export var is_night_enemy: bool = false
@export var is_final_enemy: bool = false

func dupe() -> EnemyResource:
	var duped: EnemyResource = duplicate(true)
	var duped_ranks: Array[EnemyRank]
	for rank in ranks:
		duped_ranks.append(rank.dupe())
	duped.ranks = duped_ranks
	return(duped)
