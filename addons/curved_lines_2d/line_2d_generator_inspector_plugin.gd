@tool
extends EditorInspectorPlugin

var GenerateLine2dButton : PackedScene = preload("res://addons/curved_lines_2d/generate_line_2d_button.tscn")

func _can_handle(obj) -> bool:
	return obj is DrawablePath2D


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name == "line" and object is DrawablePath2D:
		var button : Button = GenerateLine2dButton.instantiate()
		add_custom_control(button)
		button.pressed.connect(func(): _on_generate_button_pressed(object))
	return false


func _on_generate_button_pressed(drawable_path_2d : DrawablePath2D):
	var line_2d := Line2D.new()
	var root := EditorInterface.get_edited_scene_root()
	drawable_path_2d.add_child(line_2d, true)
	line_2d.set_owner(root)
	drawable_path_2d.line = line_2d
