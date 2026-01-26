extends Control

var anim_name = 'footman'

var required_types = ["Unit"]

var excluded_tags = []

var required_tags = []

var required_name = "Footman"

func play():
	$AnimationPlayer.play("attack")
