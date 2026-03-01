class_name EnemyResource
extends Resource

## key denotes what turn number the rank will be deployed on
@export var ranks: Array[EnemyRank]

func dupe() -> EnemyResource:
	var duped: EnemyResource = duplicate(true)
	var duped_ranks: Array[EnemyRank]
	for rank in ranks:
		duped_ranks.append(rank.dupe())
	duped.ranks = duped_ranks
	return(duped)
