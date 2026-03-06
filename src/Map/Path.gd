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
		place_event(forward_direction * (i + 1), events[i], i + 1)
		connection_dict[forward_direction * (i)] = [forward_direction * (i + 1)]

func place_event(point: Vector2, specific_event: Event, tier: int) -> void:
	var event: Event
	if specific_event:
		event = specific_event.dupe()
	event.spot = point
	event.tier = tier
	event.setup()
	event_dict[point] = event
