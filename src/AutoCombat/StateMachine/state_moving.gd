class_name StateMoving
extends State

var ticks_waited: int = 0

func enter() -> void:
	ticks_waited = 0
	if is_instance_valid(unit.tree):
		unit.tree.get("parameters/playback").travel("Walk")
		if is_instance_valid(unit.target):
			var dir = (unit.target.global_position - unit.global_position).normalized()
			unit.tree.set("parameters/Walk/BlendSpace2D/blend_position", dir)

func on_tick() -> void:
	unit.find_nearest_target()
	
	if not is_instance_valid(unit.target) or unit.target.current_health <= 0:
		transitioned.emit(self, "Idle")
		return
		
	var dist = unit.grid.hex_distance(unit.hex_pos, unit.target.hex_pos)
	if dist <= unit.attack_range:
		transitioned.emit(self, "Attacking")
		return
		
	# Process Movement Tick
	ticks_waited += 1
	if ticks_waited >= unit.move_ticks:
		execute_move()
		ticks_waited = 0 # Reset for the next hex step

func execute_move() -> void:
	var path = unit.grid.get_path_to_hex(unit.hex_pos, unit.target.hex_pos)
	
	if path.size() > 1:
		var best_hex = path[1]
		
		# Skip if someone is already standing there
		if not unit.grid.grid.has(best_hex):
			# 1. Update the logical grid immediately so no one else claims it
			unit.grid.grid.erase(unit.hex_pos)
			unit.grid.set_hex_occupied(unit.hex_pos, false)
			
			unit.grid.grid[best_hex] = unit
			unit.grid.set_hex_occupied(best_hex, true)
			
			unit.hex_pos = best_hex
			
			# 2. Visually slide to the new hex over the duration of the next movement cycle
			var pixel_dest = unit.grid.hex_to_pixel(best_hex)
			
			if is_instance_valid(unit.tree) and pixel_dest != unit.global_position:
				var dir = (pixel_dest - unit.global_position).normalized()
				unit.tree.set("parameters/Walk/BlendSpace2D/blend_position", dir)
				
			var tween_time = unit.manager.heartbeat_timer.wait_time * unit.move_ticks
			
			var tween = create_tween()
			tween.tween_property(unit, "global_position", pixel_dest, tween_time).set_trans(Tween.TRANS_LINEAR)
