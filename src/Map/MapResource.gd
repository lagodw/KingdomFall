class_name Map
extends Resource

@export var day_counter: int = 0:
	set(val):
		day_counter = val
		if Bus.ui:
			Bus.ui.get_node("%DayCount").text = str(Bus.map.day_counter)
@export var act: Act
@export var current_location: Event

func setup() -> void:
	act = load("uid://hnvrwusray14").duplicate(true)
	act.setup()
