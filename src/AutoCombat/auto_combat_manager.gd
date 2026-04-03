class_name AutoCombatManager
extends Node2D

@onready var heartbeat_timer: Timer = $TickTimer
@onready var start_button: Button = $Start

@export var hex_size: float = 40.0 
var grid: Dictionary = {}

# Keep track of all living units in combat
var active_units: Array[AutoUnit] = []

func _ready() -> void:
	start_button.pressed.connect(start_combat)
	heartbeat_timer.timeout.connect(_on_heartbeat)
func start_combat() -> void:
	start_button.visible = false
	
	# Gather all units
	var player_units = get_tree().get_nodes_in_group("player_units")
	var enemy_units = get_tree().get_nodes_in_group("enemy_units")
	
	for unit in player_units + enemy_units:
		if unit is AutoUnit:
			active_units.append(unit) # Add to our managed queue
			
			var start_hex = pixel_to_hex(unit.global_position)
			unit.hex_pos = start_hex
			grid[start_hex] = unit
			unit.global_position = hex_to_pixel(start_hex)
			unit.manager = self
			
			if unit.current_health > 0:
				unit.state_machine.transition_to("Idle")
				
	heartbeat_timer.start(0.25)

func _on_heartbeat() -> void:
	# 1. Clean up any dead units from the array
	active_units = active_units.filter(func(u): return is_instance_valid(u) and u.current_health > 0)
	
	# 2. SORTING (The Tie-Breaker)
	# Shuffle the array so that ties are resolved completely randomly each tick.
	# This prevents the same unit from always bullying others out of a hex.
	active_units.shuffle()
	
	# 3. Execution
	# Now we tick them one by one in the newly randomized order
	for unit in active_units:
		unit.state_machine.on_tick()

# ==========================================
# HEXAGON MATH (Axial Coordinates)
# ==========================================

# 6 possible directions a unit can move on a flat-topped hex grid
const HEX_DIRECTIONS = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), 
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
]

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

func hex_to_pixel(hex: Vector2i) -> Vector2:
	var x = hex_size * (3.0/2.0 * hex.x)
	var y = hex_size * (sqrt(3.0)/2.0 * hex.x + sqrt(3.0) * hex.y)
	return Vector2(x, y)

func pixel_to_hex(pixel: Vector2) -> Vector2i:
	var q = (2.0/3.0 * pixel.x) / hex_size
	var r = (-1.0/3.0 * pixel.x + sqrt(3.0)/3.0 * pixel.y) / hex_size
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

# Add a variable to control how big the battlefield is
@export var board_radius: int = 5 

# We add _draw() which Godot automatically calls once when the node is added to the scene
func _draw() -> void:
	var board_hexes = generate_board_hexes(board_radius)
	var line_color = Color(1, 1, 1, 0.2) # White, but highly transparent
	var line_thickness = 2.0
	
	for hex in board_hexes:
		var center = hex_to_pixel(hex)
		var corners = get_hex_corners(center)
		
		# draw_polyline needs the first point added to the end again to "close" the loop
		corners.append(corners[0]) 
		
		draw_polyline(corners, line_color, line_thickness)

# ==========================================
# BOARD GENERATION & DRAWING HELPERS
# ==========================================

# Generates a list of all hex coordinates that form a giant hexagon shape
func generate_board_hexes(radius: int) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			hexes.append(Vector2i(q, r))
	return hexes

# Calculates the 6 pixel corners of a flat-topped hex
func get_hex_corners(center: Vector2) -> PackedVector2Array:
	var corners = PackedVector2Array()
	for i in 6:
		# Flat topped hexes have corners at 0, 60, 120, 180, 240, 300 degrees
		var angle_deg = 60 * i
		var angle_rad = deg_to_rad(angle_deg)
		var point = center + Vector2(hex_size * cos(angle_rad), hex_size * sin(angle_rad))
		corners.append(point)
	return corners
