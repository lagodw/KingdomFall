class_name StateIdle
extends State

func enter() -> void:
	unit.find_nearest_target()

func on_tick() -> void:
	if not is_instance_valid(unit.target) or unit.target.current_health <= 0:
		unit.find_nearest_target()
		
	if is_instance_valid(unit.target) and unit.target.current_health > 0:
		var dist = unit.manager.hex_distance(unit.hex_pos, unit.target.hex_pos)
		if dist <= unit.attack_range:
			transitioned.emit(self, "Attacking")
		else:
			transitioned.emit(self, "Moving")
