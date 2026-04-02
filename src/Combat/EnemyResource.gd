class_name EnemyResource
extends Resource

## key denotes what turn number the rank will be deployed on
@export var face: UnitResource
@export var ranks: Dictionary[int, EnemyRank]
@export var num_files: int = 5
@export var num_player_ranks: int = 3
@export var num_enemy_ranks: int = 3
@export var is_night_enemy: bool = false
@export var is_final_enemy: bool = false

func dupe() -> EnemyResource:
	var duped: EnemyResource = duplicate(true)
	var duped_ranks: Dictionary[int, EnemyRank]
	for turn in ranks.keys():
		duped_ranks[turn] = ranks[turn].dupe()
	duped.ranks = duped_ranks
	return(duped)
