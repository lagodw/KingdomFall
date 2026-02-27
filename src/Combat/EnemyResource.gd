class_name EnemyResource
extends Resource

## key denotes what turn number the rank will be deployed on
@export var ranks: Dictionary[int, EnemyRank] = {}

func dupe() -> EnemyResource:
	var duped: EnemyResource = duplicate(true)
	var duped_ranks: Dictionary[int, EnemyRank]
	for turn in ranks.keys():
		duped_ranks[turn] = ranks[turn].dupe()
	duped.ranks = duped_ranks
	return(duped)
