class_name MapScene
extends Control

@onready var grid := $ScrollControl/GridContainer
@onready var signpost = preload("uid://dapbgl6me51m")

var event_marker = preload("uid://bq7hg1qy46035")
var main_road = preload("uid://0g4jfxi1jd1w")
var side_road = preload("uid://0g4jfxi1jd1w")

var s := Vector2(300, 300)
var node_map: Dictionary[Vector2, Control] = {}
var initial_scroll_size: Vector2
var world: Control

func _ready():
	Audio.play_music("Embers Before the Storm")
	$NightFall.pressed.connect(night_fall)
	#kf.add_player_deck(self)
	place_act(Bus.map.act)
	
	#call_deferred("tutorial")
	
func tutorial():
	kf.load_tutorial_scene("uid://dnm8jinnsrswh")
	
func place_act(act: Act):
	var max_row: int = act.paths["N"].length + 1
	var max_width: int = act.paths["E"].length + 1
	grid.columns = max_width * 2 + 1
	for row in range(max_row, -max_row - 1, -1):
		for col in range(-max_width, max_width + 1):
			if (Vector2(row, col) in act.revealed_spots or 
				not kf.fog) and Vector2(row, col) in act.events:
				place_event(row, col, act.events[Vector2(row, col)])
			else:
				place_empty(row, col)
			
			#if row == max_row and col == -max_width:
				#world = load("res://src/Map/MapDecoration.tscn").instantiate()
				#node_map[Vector2(max_row, -max_width)].add_child(world)
	await get_tree().process_frame
	
	for point in act.connection_dict:
		#if not act.revealed_spots.has(point) and kf.fog:
			#continue
		for target in act.connection_dict[point]:
			if act.revealed_spots.has(target) or not kf.fog:
				var marker_pos: Vector2 = Vector2.ZERO
				var curve_pos: Vector2 = Vector2.ZERO
				#if act.marker_positions.has(target):
					#marker_pos = act.marker_positions[target]
				#if act.curve_points.has(target):
					#curve_pos = act.curve_points[target]
				connect_points(point, target, marker_pos, curve_pos)
	
	place_castle()

func place_empty(row: int, col: int):
	var spot = Control.new()
	spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spot.custom_minimum_size = s
	grid.add_child(spot)
	spot.name = "(%s, %s)"%[row, col]
	node_map[Vector2(row, col)] = spot
	
func add_signpost(spot: Vector2, path_start: Vector2) -> void:
	var sign_instance = signpost.instantiate()
	sign_instance.event_dict = Bus.map.act.signpost_dict[path_start]
	node_map[spot].add_child(sign_instance)
	if path_start.y < spot.y:
		sign_instance.position.x = 0
	else:
		sign_instance.position.x = 181
	if path_start.x < spot.x:
		sign_instance.position.y = 200
	elif path_start.x == spot.x:
		sign_instance.position.y = 0
	else:
		sign_instance.position.y = -75
	
func place_event(row: int, col: int, event: Event):
	var point = Vector2(row, col)
	var spot = event_marker.instantiate()
	spot.spot = point
	spot.event = event
	grid.add_child(spot)
	spot.name = "(%s, %s)"%[row, col]
	node_map[point] = spot
	
func connect_points(point1: Vector2, point2: Vector2, marker_position: Vector2,
							curve_point: Vector2) -> void:
	var start_node: Control = node_map[point1]
	var end_node: Control = node_map[point2]
	var curve = side_road.instantiate().duplicate(true)
	if end_node.has_node("Button"):
		var end_button = end_node.get_node("Button")
		end_button.position = marker_position
		end_button.add_child(curve)
		end_button.move_child(curve, 0)
		curve.position = end_button.size/2
	else:
		curve.position = s/2
		end_node.add_child(curve)
	var end_point: Vector2
	if start_node.has_node("Button"):
		var start_button = start_node.get_node("Button")
		end_point = curve.to_local(start_button.global_position) + start_button.size / 2
	else:
		end_point = curve.to_local(start_node.global_position) + s / 2
	curve.curve.add_point(Vector2(0, 0), Vector2(0, 0), curve_point)
	curve.curve.add_point(end_point, Vector2(0, 0), Vector2(0, 0))
	curve.get_node("Line2D").points = curve.curve.tessellate(10)

func place_castle():
	var castle = $Castle
	remove_child(castle)
	node_map[Vector2(0, 0)].add_child(castle)
	castle.position = Vector2(0, 0)

func night_fall():
	# day counter incremented in town
	Bus.map.current_location = Bus.map.act.night_combat[Bus.map.day_counter - 1]
	kf.load_scene("uid://dvld0lyuo33oq")
