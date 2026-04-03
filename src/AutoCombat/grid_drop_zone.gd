extends Control

var grid

func _ready() -> void:
	# Keep it in background so it doesn't block other clicks unless dragging
	mouse_filter = Control.MOUSE_FILTER_PASS

func is_valid_hex(hex: Vector2i) -> bool:
	if not grid.hex_to_id.has(hex): 
		return false
	if grid.astar.is_point_disabled(grid.hex_to_id[hex]): 
		return false
	# Only allow the left 2 columns of the grid (q = 0 or q = 1)
	if hex.x > 4: 
		return false
	return true

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Accept only Unit cards
	if not (data is Unit or (typeof(data) == TYPE_OBJECT and data.has_method("get_class") and data.get_class() == "Unit")):
		grid.hovered_hex = Vector2i(-999, -999)
		grid.queue_redraw()
		return false
		
	# Get the grid's local mouse position to accurately map to the hex grid
	var mouse_pos = grid.get_global_mouse_position()
	var hex = grid.pixel_to_hex(mouse_pos)
	
	grid.hovered_hex = hex
	var valid = is_valid_hex(hex)
	grid.is_hover_valid = valid
	
	grid.queue_redraw()
	
	# We can always return true so we don't drop the `_can_drop_data` tracking,
	# but setting it to `valid` enables Godot to show the forbidden cursor symbol!
	return valid

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Dragging state cleanly off
	kf.dragging = null
	
	var mouse_pos = grid.get_global_mouse_position()
	var hex = grid.pixel_to_hex(mouse_pos)
	
	if is_valid_hex(hex):
		grid.hovered_hex = Vector2i(-999, -999)
		grid.queue_redraw()
		
		# Hooking up with manager
		if grid.manager and grid.manager.has_method("deploy_unit"):
			grid.manager.deploy_unit(data, hex)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if is_instance_valid(grid):
			grid.hovered_hex = Vector2i(-999, -999)
			grid.queue_redraw()
