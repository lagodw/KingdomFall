## A custom node that extends Path2D so it can be drawn as a Line2D
## Original adapted code: https://www.hedberggames.com/blog/rendering-curves-in-godot
@tool
extends Path2D
class_name  DrawablePath2D

signal line_changed()

## The Line2D controlled by this Path2D
@export var line: Line2D:
	set(_line):
		line = _line
		line_changed.emit()


## Controls whether the path is treated as static (only update in editor) or dynamic (can be updated during runtime)
## If you set this to true, be alert for potential performance issues
@export var update_curve_at_runtime: bool = false

## Controls the paramaters used to divide up the line  in segments.
## These settings are prefilled with the default values.
@export_group("Tesselation settings")
## Controls how many subdivisions a curve segment may face before it is considered approximate enough. 
## Each subdivision splits the segment in half, so the default 5 stages may mean up to 32 subdivisions 
## per curve segment. Increase with care!
@export_range(1, 10) var max_stages : int = 5:
	set(_max_stages):
		max_stages = _max_stages
		line_changed.emit()
## Controls how many degrees the midpoint of a segment may deviate from the real curve, before the 
## segment has to be subdivided.
@export_range(0.0, 180.0) var tolerance_degrees := 4.0:
	set(_tolerance_degrees):
		tolerance_degrees = _tolerance_degrees
		line_changed.emit()

# Wire up signals at runtime
func _ready():
	if update_curve_at_runtime:
		if not curve.changed.is_connected(curve_changed):
			curve.changed.connect(curve_changed)


# Wire up signals on enter tree for the editor
func _enter_tree():
	if Engine.is_editor_hint():
		if not curve.changed.is_connected(curve_changed):
			curve.changed.connect(curve_changed)
		if not line_changed.is_connected(_on_line_changed):
			line_changed.connect(_on_line_changed)


# Clean up signals (ie. when closing scene) to prevent error messages in the editor
func _exit_tree():
	if curve.changed.is_connected(curve_changed):
		curve.changed.disconnect(curve_changed)


func _on_line_changed():
	if is_instance_valid(line):
		line.set_meta("_edit_lock_", true)
		curve_changed()


# Redraw the line based on the new curve, using its tesselate method
func curve_changed():
	if is_instance_valid(line):
		line.points = curve.tessellate(max_stages, tolerance_degrees)
