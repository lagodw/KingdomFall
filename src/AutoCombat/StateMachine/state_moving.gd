class_name StateMoving
extends State

var ticks_waited: int = 0

func enter() -> void:
	ticks_waited = 0

func on_tick() -> void:
	if not is_instance_valid(unit.target) or unit.target.current_health <= 0:
		transitioned.emit(self, "Idle")
		return
		
	var dist = unit.manager.hex_distance(unit.hex_pos, unit.target.hex_pos)
	if dist <= unit.attack_range:
		transitioned.emit(self, "Attacking")
		return
		
	# Process Movement Tick
	ticks_waited += 1
	if ticks_waited >= unit.move_ticks:
		execute_move()
		ticks_waited = 0 # Reset for the next hex step

func execute_move() -> void:
	var best_hex = unit.hex_pos
	var shortest_dist = unit.manager.hex_distance(unit.hex_pos, unit.target.hex_pos)
	
	# Look at all 6 neighboring hexes
	for dir in unit.manager.HEX_DIRECTIONS:
		var neighbor = unit.hex_pos + dir
		
		# Skip if someone is already standing there
		if unit.manager.grid.has(neighbor):
			continue 
			
		var dist_to_target = unit.manager.hex_distance(neighbor, unit.target.hex_pos)
		if dist_to_target < shortest_dist:
			shortest_dist = dist_to_target
			best_hex = neighbor
			
	if best_hex != unit.hex_pos:
		# 1. Update the logical grid immediately so no one else claims it
		unit.manager.grid.erase(unit.hex_pos)
		unit.manager.grid[best_hex] = unit
		unit.hex_pos = best_hex
		
		# 2. Visually slide to the new hex over the duration of the next movement cycle
		var pixel_dest = unit.manager.hex_to_pixel(best_hex)
		var tween_time = unit.manager.heartbeat_timer.wait_time * unit.move_ticks
		
		var tween = create_tween()
		tween.tween_property(unit, "global_position", pixel_dest, tween_time).set_trans(Tween.TRANS_LINEAR)
