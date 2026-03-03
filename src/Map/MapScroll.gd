# MapViewport.gd
extends Control

# --- Configuration & Variables ---

# DRAG VARIABLES
const DRAG_THRESHOLD: float = 0.05 
var is_holding: bool = false
var press_start_pos: Vector2 = Vector2.ZERO
var drag_scrolling_active: bool = false
var player_marker: Control:
	set(val):
		player_marker = val
		var calculated_pos = get_viewport_rect().size - map_content.global_position - player_marker.global_position
		calculated_pos.x -= get_viewport_rect().size.x / 2
		calculated_pos.y -= 200
		map_content.position = _clamp_content_position(calculated_pos, current_zoom)

@export var drag_speed_multiplier: float = 3.0

# ZOOM VARIABLES
# Stores the size of the *content node* at zoom 1.0. Used for boundary checks.
var unscaled_base_size: Vector2 = Vector2.ZERO 
# Reference to the GridContainer, initialized in _ready.
@onready var map_content: Control = $GridContainer 

var current_zoom: float = 1.0 : 
	set(value):
		var previous_zoom = current_zoom
		# 1. Clamp the new zoom value
		current_zoom = clampf(value, min_zoom, max_zoom)
		
		if is_equal_approx(previous_zoom, current_zoom):
			return
		
		# 2. Apply the new scale to the content node
		map_content.scale = Vector2(current_zoom, current_zoom)
		
		Bus.emit_signal("map_scale_changed", current_zoom)
		
@export var zoom_speed: float = 0.1     
@export var min_zoom: float = 0.5  
@export var max_zoom: float = 1.0
var starting_zoom: float = 0.35  

# --- Initialization ---
func _ready():
	# call deferred because control size is not available on ready
	call_deferred("_initial_setup")
	
func _initial_setup():
	unscaled_base_size = map_content.get_size()
	current_zoom = starting_zoom

# --- Helper Function for Centering Zoom ---
# Calculates the new position needed to keep the point under the mouse stationary.
func _calculate_zoom_center_position(old_content_pos: Vector2, mouse_local_pos: Vector2, old_zoom: float, new_zoom: float) -> Vector2:
	if is_equal_approx(old_zoom, new_zoom):
		return old_content_pos
	
	# 1. Determine the World Point (P_content) currently under the mouse.
	# P_content = (Mouse_local - Content_Pos_old) / Zoom_old
	var point_in_content_space: Vector2 = (mouse_local_pos - old_content_pos) / old_zoom

	# 2. Calculate the New Content Position (Content_Pos_new) that keeps P_content at Mouse_local.
	# Content_Pos_new = Mouse_local - (P_content * Zoom_new)
	var new_content_pos: Vector2 = mouse_local_pos - (point_in_content_space * new_zoom)
	
	return new_content_pos

# --- Boundary Clamping Function ---
func _clamp_content_position(new_position: Vector2, the_current_zoom: float) -> Vector2:
	# Max displacement is the viewport size minus the scaled content size.
	# This value will be 0 or negative.
	var max_displacement: Vector2 = self.size - unscaled_base_size * the_current_zoom

	# Clamping range is from max_displacement (to keep the right/bottom edge visible) to 0 (to keep the top/left edge visible).
	var clamped_x = clampf(new_position.x, max_displacement.x, 0.0)
	var clamped_y = clampf(new_position.y, max_displacement.y, 0.0)
	
	return Vector2(clamped_x, clamped_y)

# --- Input Handling ---

func _gui_input(event: InputEvent) -> void:
	# 1. Handle Mouse Button Input (Zoom & Drag Start/End)
	if event is InputEventMouseButton:
		
		# --- Zoom via Mouse Wheel ---
		if (event.button_index == MOUSE_BUTTON_WHEEL_UP or 
			event.button_index == MOUSE_BUTTON_WHEEL_DOWN) and not event.pressed:
			
			var old_zoom = current_zoom
			var mouse_local_pos = event.position 
			var old_content_pos = map_content.position
			
			# Calculate New Zoom
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				current_zoom += zoom_speed * current_zoom
			else: 
				current_zoom -= zoom_speed * current_zoom
				
			accept_event() # Consume the event to block default behavior
			
			if is_equal_approx(old_zoom, current_zoom):
				return
			
			# Calculate new position to center the zoom on the mouse
			var calculated_pos = _calculate_zoom_center_position(old_content_pos, mouse_local_pos, old_zoom, current_zoom)
			
			# Apply and clamp the new position immediately
			map_content.position = _clamp_content_position(calculated_pos, current_zoom)
			
			return

		# --- Drag Start/End ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_holding = true
				press_start_pos = event.global_position
				drag_scrolling_active = false
			else:
				is_holding = false
				if drag_scrolling_active:
					accept_event()
				drag_scrolling_active = false
					
	# 2. Handle Mouse Motion (Active Drag)
	if event is InputEventMouseMotion:
		if is_holding:
			var current_pos: Vector2 = event.global_position
			var mouse_delta: Vector2 = current_pos - press_start_pos

			# --- Drag Start Check (Threshold) ---
			if !drag_scrolling_active:
				var distance_traveled: float = press_start_pos.distance_to(current_pos)
				if distance_traveled >= DRAG_THRESHOLD:
					drag_scrolling_active = true
					accept_event()
					press_start_pos = current_pos 
					return

			# --- Active Drag Movement ---
			if drag_scrolling_active:
				# Calculate the desired new position (opposite direction of mouse movement)
				var new_content_pos = map_content.position + mouse_delta * drag_speed_multiplier
				
				# Apply the new position after clamping it to stay within the viewport bounds
				map_content.position = _clamp_content_position(new_content_pos, current_zoom)
				#map_content.position = new_content_pos
				
				# Update mouse position for next frame's delta calculation
				press_start_pos = current_pos
				
				accept_event()
