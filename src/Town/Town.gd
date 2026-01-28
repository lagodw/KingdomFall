class_name Town
extends Control

func _ready() -> void:
	$Bottom/UnitPanel.load_units(Bus.deck.cards)
	$Bottom/EndTurn.pressed.connect(night_fall)
	
func night_fall():
	get_tree().call_group("Buildings", "end_day")
	kf.load_scene("uid://dvld0lyuo33oq")
