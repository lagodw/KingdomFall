class_name StateIdle
extends State

func enter() -> void:
	unit.find_nearest_target()
	if is_instance_valid(unit.tree):
		unit.tree.get("parameters/playback").travel("Idle")
		if is_instance_valid(unit.target):
			var dir = (unit.target.global_position - unit.global_position).normalized()
			unit.tree.set("parameters/Idle/BlendSpace2D/blend_position", dir)

func on_tick() -> void:
	if not is_instance_valid(unit.target) or unit.target.current_health <= 0:
		unit.find_nearest_target()
		
	if is_instance_valid(unit.target) and unit.target.current_health > 0:
		var dist = unit.grid.hex_distance(unit.hex_pos, unit.target.hex_pos)
		if dist <= unit.attack_range:
			transitioned.emit(self, "Attacking")
		else:
			transitioned.emit(self, "Moving")
