class_name Act
extends Resource

@export var paths: Dictionary[String, Path] = {
	"N": Path.new(),
	"E": Path.new(),
	"S": Path.new(),
	"W": Path.new()
}
@export var night_combat: Array[Event]
@export var revealed_spots: Array[Vector2]
@export var spots_done: Array[Vector2]
@export var events: Dictionary[Vector2, Event]
@export var connection_dict: Dictionary[Vector2, Array]


func setup():
	for path: Path in paths.values():
		path.setup()
		events.merge(path.event_dict)
		for point in path.connection_dict:
			if connection_dict.has(point):
				connection_dict[point].append_array(path.connection_dict[point])
			else:
				connection_dict[point] = path.connection_dict[point]
	spots_done.append(Vector2(0, 0))
	revealed_spots.append(Vector2(0, 0))
	
	for combat in night_combat:
		combat.setup()
