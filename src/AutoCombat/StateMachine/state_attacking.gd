class_name StateAttacking
extends State

var ticks_waited: int = 0

func enter() -> void:
	ticks_waited = 0

func on_tick() -> void:
	if not is_instance_valid(unit.target) or unit.target.current_health <= 0:
		transitioned.emit(self, "Idle")
		return
		
	var dist = unit.manager.hex_distance(unit.hex_pos, unit.target.hex_pos)
	if dist > unit.attack_range:
		transitioned.emit(self, "Moving")
		return
		
	# Process Attack Tick
	ticks_waited += 1
	if ticks_waited >= unit.attack_ticks:
		execute_attack()
		ticks_waited = 0

func execute_attack() -> void:
	# Here you could trigger an AnimationPlayer!
	unit.target.take_damage(unit.attack_damage)
