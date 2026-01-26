extends Control

var anim_name = "fireball"

var required_types = ["Unit"]

var excluded_tags = []

var required_tags = [
]

var required_name

func play():
	$AnimationPlayer.play("attack")
