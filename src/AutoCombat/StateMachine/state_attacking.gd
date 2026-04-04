class_name StateAttacking
extends State

var ticks_waited: int:
	set(val):
		ticks_waited = val
		if val == 0:
			execute_attack()

func enter() -> void:
	ticks_waited = 0
	if is_instance_valid(unit.tree):
		unit.tree.get("parameters/playback").travel("Attack")
		if is_instance_valid(unit.target):
			var dir = (unit.target.global_position - unit.global_position).normalized()
			unit.tree.set("parameters/Attack/BlendSpace2D/blend_position", dir)
			unit.tree.set("parameters/Idle/BlendSpace2D/blend_position", dir)

func on_tick() -> void:
	# If our target died, check immediately if the battle is completely over
	# We break out of the swing cooldown early ONLY if there are 0 enemies left globally
	if not is_instance_valid(unit.target) or unit.target.current_health <= 0:
		unit.find_nearest_target()
		if not is_instance_valid(unit.target):
			transitioned.emit(self, "Idle")
			return

	# Process the swing timer regardless of current target validity
	ticks_waited += 1
	
	if ticks_waited >= unit.attack_ticks:
		# Swing is finished. Update target if needed.
		if not is_instance_valid(unit.target) or unit.target.current_health <= 0:
			unit.find_nearest_target()
			
		var dist = unit.grid.hex_distance(unit.hex_pos, unit.target.hex_pos)
		if dist > unit.attack_range:
			transitioned.emit(self, "Moving")
			return
			
		# Target is valid and in range! Strike again.
		if unit.target.is_visually_moving():
			transitioned.emit(self, "Idle")
			return
			
		if is_instance_valid(unit.tree):
			unit.tree.get("parameters/playback").travel("Attack")
			var dir = (unit.target.global_position - unit.global_position).normalized()
			unit.tree.set("parameters/Attack/BlendSpace2D/blend_position", dir)
			unit.tree.set("parameters/Idle/BlendSpace2D/blend_position", dir)
		ticks_waited = 0

func execute_attack() -> void:
	# Here you could trigger an AnimationPlayer!
	unit.target.take_damage(unit.attack_damage)
