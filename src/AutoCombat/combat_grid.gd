@tool
class_name CombatGrid
extends Node2D

@export var grid_width: int = 15:
	set(value):
		grid_width = max(1, value)
		queue_redraw()
		if is_node_ready(): update_camera_limits()

@export var grid_height: int = 5:
	set(value):
		grid_height = max(1, value)
		queue_redraw()
		if is_node_ready(): update_camera_limits()

@export var hex_size: float = 80.0:
	set(value):
		hex_size = max(10.0, value)
		queue_redraw()
		if is_node_ready(): update_camera_limits()

var grid: Dictionary = {}
var astar: AStar2D = AStar2D.new()
var hex_to_id: Dictionary = {}
var id_to_hex: Dictionary = {}

var manager: Node
var hovered_hex: Vector2i = Vector2i(-999, -999)
var is_hover_valid: bool = false
var drop_zone: Control

# Viewport Camera Variables
var is_panning: bool = false
var min_zoom: float = 0.3
var max_zoom: float = 2.0
var zoom_speed: float = 0.1
var camera: Camera2D

const HEX_DIRECTIONS = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), 
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
]

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_initialize_astar()
	
	drop_zone = Control.new()
	var script = load("res://src/AutoCombat/grid_drop_zone.gd")
	if script:
		drop_zone.set_script(script)
	drop_zone.grid = self
	drop_zone.mouse_filter = Control.MOUSE_FILTER_PASS
	drop_zone.size = Vector2(4000, 4000)
	drop_zone.position = Vector2(-1000, -1000)
	add_child(drop_zone)
	
	# Instantiate a dynamic camera for zooming and panning across large grids
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	update_camera_limits()

func _initialize_astar() -> void:
	var board_hexes = generate_rectangular_board()
	var id = 0
	for hex in board_hexes:
		astar.add_point(id, Vector2(hex.x, hex.y))
		hex_to_id[hex] = id
		id_to_hex[id] = hex
		id += 1
		
	# Connect neighbors
	for hex in board_hexes:
		var current_id = hex_to_id[hex]
		for dir in HEX_DIRECTIONS:
			var neighbor = hex + dir
			if hex_to_id.has(neighbor):
				var neighbor_id = hex_to_id[neighbor]
				if not astar.are_points_connected(current_id, neighbor_id):
					astar.connect_points(current_id, neighbor_id)

func set_hex_occupied(hex: Vector2i, occupied: bool) -> void:
	if hex_to_id.has(hex):
		astar.set_point_disabled(hex_to_id[hex], occupied)

func get_path_to_hex(start_hex: Vector2i, target_hex: Vector2i) -> Array[Vector2i]:
	if not hex_to_id.has(start_hex) or not hex_to_id.has(target_hex):
		return []
		
	var start_id = hex_to_id[start_hex]
	var target_id = hex_to_id[target_hex]
	
	# Temporarily enable target hex so an exact path can be found
	var was_disabled = astar.is_point_disabled(target_id)
	if was_disabled:
		astar.set_point_disabled(target_id, false)
		
	var path_ids = astar.get_id_path(start_id, target_id)
	
	# Restore disabled state
	if was_disabled:
		astar.set_point_disabled(target_id, true)
		
	var path_hexes: Array[Vector2i] = []
	for pid in path_ids:
		path_hexes.append(id_to_hex[pid])
		
	return path_hexes

func _draw() -> void:
	var board_hexes = generate_rectangular_board()
	var line_color = Color(1, 1, 1, 0.4) 
	var line_thickness = 2.0
	
	if hovered_hex != Vector2i(-999, -999):
		var center = to_local(hex_to_pixel(hovered_hex))
		var corners = get_hex_corners(center)
		var fill_color = Color(0, 1, 0, 0.4) if is_hover_valid else Color(1, 0, 0, 0.4)
		draw_colored_polygon(corners, fill_color)
	
	for hex in board_hexes:
		var center = to_local(hex_to_pixel(hex))
		var corners = get_hex_corners(center)
		corners.append(corners[0]) 
		draw_polyline(corners, line_color, line_thickness)

func generate_rectangular_board() -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	for row in range(grid_height):
		for col in range(grid_width):
			var q = col - int(floor(row / 2.0))
			var r = row
			hexes.append(Vector2i(q, r))
	return hexes

# ==========================================
# HEXAGON MATH 
# ==========================================

func get_hex_corners(center: Vector2) -> PackedVector2Array:
	var corners = PackedVector2Array()
	for i in 6:
		var angle_deg = 60 * i - 30 # -30 offsets angles to form pointy-topped hexes (flat vertical edges)
		var angle_rad = deg_to_rad(angle_deg)
		var point = center + Vector2(hex_size * cos(angle_rad), hex_size * sin(angle_rad))
		corners.append(point)
	return corners

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

func hex_to_pixel(hex: Vector2i) -> Vector2:
	var x = hex_size * sqrt(3.0) * (hex.x + hex.y / 2.0)
	var y = hex_size * (3.0 / 2.0 * hex.y)
	return to_global(Vector2(x, y))

func pixel_to_hex(pixel: Vector2) -> Vector2i:
	var local_pixel = to_local(pixel)
	var q = (sqrt(3.0)/3.0 * local_pixel.x - 1.0/3.0 * local_pixel.y) / hex_size
	var r = (2.0/3.0 * local_pixel.y) / hex_size
	return hex_round(q, r)

func hex_round(q: float, r: float) -> Vector2i:
	var s = -q - r
	var rq = round(q)
	var rr = round(r)
	var rs = round(s)
	
	var q_diff = abs(rq - q)
	var r_diff = abs(rr - r)
	var s_diff = abs(rs - s)
	
	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
		
	return Vector2i(rq, rr)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
			else:
				is_panning = false
				
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(1.0 + zoom_speed, get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(1.0 - zoom_speed, get_global_mouse_position())
			
	elif event is InputEventMouseMotion and is_panning:
		camera.position -= event.relative / camera.zoom
		_clamp_camera_hard()

func _zoom_camera(factor: float, mouse_pos: Vector2) -> void:
	if not is_instance_valid(camera): return
	var previous_zoom = camera.zoom
	var new_zoom = camera.zoom * factor
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	
	if new_zoom == previous_zoom:
		return
		
	camera.global_position = camera.global_position + (mouse_pos - camera.global_position) * (1.0 - previous_zoom.x / new_zoom.x)
	camera.zoom = new_zoom
	_clamp_camera_hard()

func get_pixel_bounds() -> Rect2:
	var min_x = 999999.0
	var min_y = 999999.0
	var max_x = -999999.0
	var max_y = -999999.0
	var board = generate_rectangular_board()
	if board.is_empty():
		return Rect2(0, 0, 1920, 1080)
		
	for hex in board:
		var center = hex_to_pixel(hex)
		var corners = get_hex_corners(center)
		for point in corners:
			min_x = min(min_x, point.x)
			min_y = min(min_y, point.y)
			max_x = max(max_x, point.x)
			max_y = max(max_y, point.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func update_camera_limits() -> void:
	if not is_instance_valid(camera): return
	
	var bounds = get_pixel_bounds()
	var available_w = 1920.0
	var available_h = 1080.0 - 350.0 - 50.0 
	
	var min_z_x = available_w / bounds.size.x
	var min_z_y = available_h / bounds.size.y
	min_zoom = max(min_z_x, min_z_y)
	max_zoom = max(2.5, min_zoom)
	
	# We rely solely on logic clamping to prevent zoom scaling offset gaps 
	camera.limit_left = -10000000
	camera.limit_top = -10000000
	camera.limit_right = 10000000
	camera.limit_bottom = 10000000
	
	camera.zoom = Vector2(min_zoom, min_zoom)
	camera.position = bounds.get_center()
	_clamp_camera_hard()

func _clamp_camera_hard() -> void:
	if not is_instance_valid(camera): return
	var cam_w = (1920.0 / 2.0) / camera.zoom.x
	var cam_h = (1080.0 / 2.0) / camera.zoom.y
	
	var bounds = get_pixel_bounds()
	
	# Natively transform Screen UI padding into active World distances so it perfectly docks
	var lim_top = bounds.position.y - (50.0 / camera.zoom.y)
	var lim_bot = bounds.end.y + (350.0 / camera.zoom.y)
	var lim_left = bounds.position.x
	var lim_right = bounds.end.x
	
	var min_x = lim_left + cam_w
	var max_x = lim_right - cam_w
	if min_x > max_x:
		min_x = (lim_left + lim_right) / 2.0
		max_x = min_x
		
	var min_y = lim_top + cam_h
	var max_y = lim_bot - cam_h
	if min_y > max_y:
		min_y = (lim_top + lim_bot) / 2.0
		max_y = min_y
		
	camera.global_position = Vector2(
		clamp(camera.global_position.x, min_x, max_x),
		clamp(camera.global_position.y, min_y, max_y)
	)
