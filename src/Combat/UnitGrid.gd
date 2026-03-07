class_name UnitGrid
extends VBoxContainer

@export var player_front: UnitBox
@export var player_back: UnitBox
@export var enemy_front: UnitBox
@export var enemy_back: UnitBox

func _ready() -> void:
	Bus.Grid = self
	Bus.trigger_occurred.connect(on_trigger)
	
func on_turn_start(_turn_num: int):
	for unit in player_front.get_units():
		unit.current_fatigue += 1
	for unit in player_back.get_units():
		unit.current_fatigue += 1

func on_trigger(trigger: String, _trigger_card: Control) -> void:
	if trigger in ['target', 'cast', 'discard', 'attach', 'move', 'consume_used']:
		await get_tree().process_frame
		update_previews()

func get_units(unit_owner: String) -> Array:
	var units: Array = []
	if unit_owner == "Player":
		units.append_array(player_front.get_units())
		units.append_array(player_back.get_units())
	else:
		units.append_array(enemy_front.get_units())
		units.append_array(enemy_back.get_units())
	return units

func update_previews() -> void:
	get_tree().call_group("Tokens", "reset_remaining")
	await get_tree().process_frame
	
	# Simulate combat phases sequentially to accurately determine remaining_life
	execute_enemy_attack(false)
	execute_player_attack(false)

func execute_enemy_attack(real: bool) -> void:
	# 1. ENEMY GOES FIRST: Calculate Enemy Attack vs Player Shield
	var enemy_back_dmg = enemy_back.get_pooled_damage(real)
	var player_front_shield = player_front.get_pooled_shield(real)
	var enemy_overflow = enemy_back_dmg - player_front_shield
	
	# 2. Distribute Enemy Overflow -> Player Side
	if enemy_overflow > 0:
		set_breach_preview("Player", true)
		if real:
			distribute_overflow_damage(enemy_overflow, "Player", true)
		else:
			distribute_overflow_damage(enemy_overflow, "Player", false)
	else:
		set_breach_preview("Player", false)
		
func execute_player_attack(real: bool) -> void:
	# 3. PLAYER GOES SECOND: Calculate Player Attack (using surviving units) vs Enemy Shield
	var player_back_dmg = player_back.get_pooled_damage(real)
	var enemy_front_shield = enemy_front.get_pooled_shield(real)
	var player_overflow = player_back_dmg - enemy_front_shield
	
	# 4. Distribute Player Overflow -> Enemy Side
	if player_overflow > 0:
		set_breach_preview("Enemy", true)
		Bus.Board.is_breached = true
		
		# Find all enemy tokens
		var enemies = get_tree().get_nodes_in_group("Tokens").filter(func(t): return t.card_owner == "Enemy")
		
		# Sum up all currently assigned breach damage
		var total_assigned = 0
		for enemy in enemies:
			total_assigned += enemy.assigned_breach_damage
			
		# Check if we still have enough overflow to cover the existing assignments
		if player_overflow >= total_assigned:
			Bus.Board.breach_amount = player_overflow - total_assigned
			
			# Re-apply assigned damage to remaining_life since reset_remaining() cleared it
			for enemy in enemies:
				if enemy.assigned_breach_damage > 0:
					# Safety check: if an enemy's health decreased (e.g. from a spell), refund excess
					var excess = enemy.assigned_breach_damage - enemy.remaining_life
					if excess > 0:
						enemy.assigned_breach_damage -= excess
						Bus.Board.breach_amount += excess
						
					enemy.remaining_life -= enemy.assigned_breach_damage
		else:
			# Overflow decreased below what was assigned, reset all assignments
			Bus.Board.breach_amount = player_overflow
			for enemy in enemies:
				enemy.assigned_breach_damage = 0
	else:
		set_breach_preview("Enemy", false)
		Bus.Board.is_breached = false
		Bus.Board.breach_amount = 0
		
		# Reset all assignments since we have no overflow
		if not real:
			var enemies = get_tree().get_nodes_in_group("Tokens").filter(func(t): return t.card_owner == "Enemy")
			for enemy in enemies:
				enemy.assigned_breach_damage = 0

func distribute_overflow_damage(amount: int, target_owner: String, real: bool) -> void:
	var remaining_damage = amount
	var all_target_units = get_units(target_owner)
	
	# Filter valid targets based on whether this is real or a preview
	var valid_targets = []
	for unit in all_target_units:
		var hp = unit.current_health if real else unit.remaining_life
		if hp > 0:
			valid_targets.append(unit)
			
	# Sort by the dynamic ratio
	valid_targets.sort_custom(func(a, b): return _sort_by_threat(a, b, real, remaining_damage))
	
	# Apply damage
	for unit in valid_targets:
		if remaining_damage <= 0:
			break
			
		var hp = unit.current_health if real else unit.remaining_life
		var health_dmg = min(remaining_damage, hp)
		
		if real:
			unit.current_health -= health_dmg
			remaining_damage -= health_dmg
			
		else:
			# Modifying remaining_life automatically updates the preview UI in CardToken.gd
			unit.remaining_life -= health_dmg
			remaining_damage -= health_dmg
			
	# Hit the gate if real combat overflows past all units
	if remaining_damage > 0 and target_owner == "Player":
		if Bus.gate and real:
			Bus.gate.current_health -= remaining_damage

func _sort_by_attack_ratio(a, b, real: bool) -> bool:
	var hp_a = a.current_health if real else a.remaining_life
	var hp_b = b.current_health if real else b.remaining_life
	
	var dmg_a = a.current_damage if real else a.remaining_base_damage
	var dmg_b = b.current_damage if real else b.remaining_base_damage
	
	var ratio_a = float(dmg_a) / float(hp_a) if hp_a > 0 else 0.0
	var ratio_b = float(dmg_b) / float(hp_b) if hp_b > 0 else 0.0
	
	return ratio_a > ratio_b
	
func _sort_by_threat(a, b, real: bool, available_damage: int) -> bool:
	# 1. Get HP values
	var hp_a = a.current_health if real else a.remaining_life
	var hp_b = b.current_health if real else b.remaining_life
	
	# 2. Get Damage values
	var dmg_a = a.current_damage if real else a.remaining_base_damage
	var dmg_b = b.current_damage if real else b.remaining_base_damage
	
	# 3. Get Block/Shield values 
	var block_a = a.current_shield
	var block_b = b.current_shield
	
	# Weights (Adjust these to tweak AI behavior)
	var damage_weight = 1.0
	var block_weight = 1.0
	
	# 4. Calculate Base Threat (Take the MAX of their offensive or defensive potential)
	var primary_threat_a = max(dmg_a * damage_weight, block_a * block_weight)
	var primary_threat_b = max(dmg_b * damage_weight, block_b * block_weight)
	
	# Divide by HP to find the most efficient target
	var threat_a = float(primary_threat_a) / float(hp_a) if hp_a > 0 else 0.0
	var threat_b = float(primary_threat_b) / float(hp_b) if hp_b > 0 else 0.0
	
	# 5. Lethality Check: Massive priority to units we can kill
	var kill_bonus = 100.0
	
	if available_damage >= hp_a:
		threat_a += kill_bonus
	if available_damage >= hp_b:
		threat_b += kill_bonus
		
	# Sort descending (highest threat first)
	return threat_a > threat_b

func apply_breach_damage():
	# Find all enemy tokens on the board
	var enemies = get_tree().get_nodes_in_group("Tokens").filter(func(t): return t.card_owner == "Enemy")
	
	for enemy in enemies:
		if enemy.assigned_breach_damage > 0:
			# Apply the real damage. 
			# Pass 'self' or null for the damaging_card depending on your setup
			enemy.take_damage(enemy.assigned_breach_damage, null, false) 
			enemy.assigned_breach_damage = 0
			
	# Reset state
	Bus.Board.is_breached = false
	Bus.Board.breach_amount = 0

func set_breach_preview(who_breached: String, is_breached: bool):
	get("%s_front"%who_breached.to_lower()).set_breach(is_breached)
	
