class_name Path
extends Resource

@export var forward_direction: Vector2
@export var length: int = 5
@export var max_width: int = 3
@export var events: Array[Event]

@export var event_dict: Dictionary[Vector2, Event] 
@export var connection_dict: Dictionary[Vector2, Array]

func setup():
	for i in length:
		event_dict[forward_direction * (i + 1)] = events[i]
		connection_dict[forward_direction * (i)] = [forward_direction * (i + 1)]
