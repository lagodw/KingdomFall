class_name StateDead
extends State

func enter() -> void:
	if is_instance_valid(unit.tree):
		unit.tree.get("parameters/playback").travel("Die")

func on_tick() -> void:
	pass
