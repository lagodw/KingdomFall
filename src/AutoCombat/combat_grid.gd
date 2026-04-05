@tool
class_name CombatGrid
extends Node2D

@export var grid_width: int = 15:
	set(value):
		grid_width = max(1, value)
		queue_redraw()

@export var grid_height: int = 5:
	set(value):
		grid_height = max(1, value)
		queue_redraw()

@export var hex_size: float = 80.0:
	set(value):
		hex_size = max(10.0, value)
		queue_redraw()

var grid: Dictionary = {}
var astar: AStar2D = AStar2D.new()
var hex_to_id: Dictionary = {}
var id_to_hex: Dictionary = {}

var manager: Node
var hovered_hex: Vector2i = Vector2i(-999, -999)
var is_hover_valid: bool = false
var drop_zone: Control

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
