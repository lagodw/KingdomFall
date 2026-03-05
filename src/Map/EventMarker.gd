class_name EventMarker
extends Control

var spot: Vector2
var event: Event

func _ready() -> void:
	if not kf.fog:
		$Button.disabled = false
	$Button/Icons/Icon.texture = load(event.icon_path)
	$Button.pressed.connect(load_event)
	if spot in Bus.map.act.spots_done:
		set_color("green")
	else:
		for spot_done in Bus.map.act.spots_done:
			if Bus.map.act.connection_dict[spot_done].has(spot):
				enable()

func enable():
	$Button.disabled = false
	set_color("yellow")
	$Button.mouse_entered.connect(set_color.bind("orange"))
	$Button.mouse_exited.connect(set_color.bind("yellow"))
	
func load_event() -> void:
	Bus.map.current_location = event
	kf.load_scene(event.scene_path)

func set_color(color: String) -> void:
	# TODO: switch to resourcegroup
	$Button/Icons/Plinth.texture = load("res://assets/Map/Plinth_%s.png"%color)
