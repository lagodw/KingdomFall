extends Control

var anim_name = "axe"

var required_types = ["Unit"]

var required_tags = []

var excluded_tags = [
]

var required_name

func play():
	$AnimationPlayer.play("attack")
