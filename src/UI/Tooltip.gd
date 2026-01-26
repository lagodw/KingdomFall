class_name Tooltip
extends Control

@export var icon_path: String
@export var title: String
@export var description: String

@onready var content: RichTextLabel = $MarginContainer/Background/VBoxContainer/Content

## doesn't really work for smaller sizes currently
@export var x_size: int = 200

var Damage: int = 0
var Health: int = 0
var Shield: int = 0

func _ready() -> void:
	if title:
		setup()
	
func setup() -> void:
	content.text = description
	
	var stripped_title = title.replace("[b]", "").replace("[/b]", "")
	$MarginContainer/Background/VBoxContainer/HBoxContainer/Shadow/Title.text = stripped_title
	$MarginContainer/Background/VBoxContainer/HBoxContainer/Shadow.text = stripped_title
	kf.fit_font_single_line($MarginContainer/Background/VBoxContainer/HBoxContainer/Shadow/Title)
	kf.fit_font_single_line($MarginContainer/Background/VBoxContainer/HBoxContainer/Shadow)
	
	if icon_path != "":
		$MarginContainer/Background/VBoxContainer/HBoxContainer/IconBG/Icon.texture = load(icon_path)
	else:
		$MarginContainer/Background/VBoxContainer/HBoxContainer/IconBG.visible = false
	
	for stat in ["Damage", "Health", "Shield"]:
		if get(stat) > 0:
			get_node("%" + stat + "Text").text = str(get(stat))
			get_node("%" + stat).visible = true
			$MarginContainer/Background/VBoxContainer/Stats.visible = true
	
	call_deferred("set_node_sizes")

func set_node_sizes():
	# 70 is size with blank content
	var y_size = get_y_size(content) + 70
	custom_minimum_size = Vector2(x_size, y_size)
	
func get_y_size(node: Control):
	node.text = description
	var font = node.get_theme_font("font")
	var font_size = node.get_theme_font_size("font_size")
	
	var text_size = font.get_multiline_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, 
		x_size - 2, font_size, -1, 2)
	if $MarginContainer/Background/VBoxContainer/Stats.visible:
		text_size.y += $MarginContainer/Background/VBoxContainer/Stats.size.y
	return(text_size.y)
