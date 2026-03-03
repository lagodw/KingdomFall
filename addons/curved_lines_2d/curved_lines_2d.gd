@tool
extends EditorPlugin

var plugin


func _enter_tree():
	plugin = preload("res://addons/curved_lines_2d/line_2d_generator_inspector_plugin.gd").new()
	add_inspector_plugin(plugin)
	add_custom_type(
		"DrawablePath2D", 
		"Path2D", 
		preload("res://addons/curved_lines_2d/drawable_path_2d.gd"),
		preload("res://addons/curved_lines_2d/DrawablePath2D.svg")
	)


func _exit_tree():
	remove_inspector_plugin(plugin)
	remove_custom_type("DrawablePath2D")
