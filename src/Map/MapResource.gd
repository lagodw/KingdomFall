class_name Map
extends Resource

@export var day_counter: int = 0
@export var night_enemies: Array[EnemyResource]
@export var act: Act
@export var current_location: Event

func setup() -> void:
	choose_night_enemies()
	act = load("uid://hnvrwusray14").duplicate(true)
	act.setup()

func choose_night_enemies() -> void:
	for night in range(1, 4):
		var enemy: EnemyResource
		var search: String = "**NightEnemies/Night%s/**.tres"%night
		enemy = R.enemies.get_matching_resource([search])[0]
		night_enemies.append(enemy)
