extends Control

var event_dict: Dictionary

func _ready() -> void:
	var i: int = 0
	for event_name in event_dict.keys():
		get_node("V/Board%s"%i).visible = true
		get_node("V/Board%s/Icon"%i).texture = load(event_dict[event_name]["icon_path"])
		
		var tool = get_node("Tooltips/Tooltip%s"%i)
		tool.title = "KEY_%s"%event_name
		tool.description = event_dict[event_name]["description"]
		tool.icon_path = event_dict[event_name]["icon_path"]
		tool.setup()
		tool.visible = true
		
		i += 1
		
	$V.mouse_entered.connect(_on_mouse_enter)
	$V.mouse_exited.connect(_on_mouse_exit)
	Bus.map_scale_changed.connect(set_tooltip_scale)
	set_tooltip_scale(get_tree().current_scene.get_node("ScrollControl").starting_zoom)

func _on_mouse_enter():
	$Tooltips.visible = true
	
func _on_mouse_exit():
	$Tooltips.visible = false

func set_tooltip_scale(map_scale: float):
	var tool_scale = 1 / map_scale
	$Tooltips.scale = Vector2(tool_scale, tool_scale)
