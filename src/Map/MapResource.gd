class_name Map
extends Resource

@export var day_counter: int = 0
@export var act: Act
@export var current_location: Event

func setup() -> void:
	act = load("uid://hnvrwusray14").duplicate(true)
	act.setup()
