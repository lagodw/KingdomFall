class_name Map
extends Resource

@export var day_counter: int = 0
@export var night_enemies: Array[EnemyResource]

func setup() -> void:
	choose_night_enemies()

func choose_night_enemies() -> void:
	for night in range(1, 4):
		var enemy: EnemyResource
		var search: String = "**NightEnemies/Night%s/**.tres"%night
		enemy = R.enemies.get_matching_resource([search])[0]
		night_enemies.append(enemy)
