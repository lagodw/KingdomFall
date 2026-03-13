class_name Enemy
extends Control

var enemy_dupe: EnemyResource
var card_grid: Control

func _ready() -> void:
	Bus.enemy = self
	var res: EnemyResource = Bus.map.current_location.enemy
	enemy_dupe = res.dupe()
	Bus.trigger_occurred.connect(on_trigger)
	Bus.board_loaded.connect(init_card_grid)
	ee.start_turn.connect(on_turn_start)
	
func init_card_grid():
	card_grid = Bus.Board.get_node("EnemyCards")

func on_turn_start(turn_num: int, turn_owner: String):
	if turn_owner != "Enemy":
		return
	# 1. Check if the current turn has an enemy wave scheduled
	add_cards_for_turn(turn_num)
	await get_tree().process_frame
	# 2. Deploy available units in the queue
	deploy_units()

## Spawn units into the deploy queue if the current turn dictates it
func add_cards_for_turn(turn_num: int):
	var ranks_to_remove: Array
	for rank in enemy_dupe.ranks:
		if rank.turn == turn_num:
			ranks_to_remove.append(rank)
			# Generate the cards and add them to the staging queue
			while rank.units.size() > 0:
				var unit = rank.units.pop_front()
				var card = kf.create_card(unit, "Enemy")
				card_grid.add_child(card)
	for rank in ranks_to_remove:
		enemy_dupe.ranks.erase(rank)

func deploy_units():
	#var units: Array = []
	
	# 1. Gather all available enemy units (board + incoming)
	#units.append_array(Bus.Grid.enemy_front.get_units())
	#units.append_array(Bus.Grid.enemy_back.get_units())
	
	var max_front = Bus.Grid.enemy_front.all_slots.size()
	var max_back = Bus.Grid.enemy_back.all_slots.size()
	#var total_capacity = max_front + max_back
	
	var grid_units = card_grid.get_children()
	#while units.size() < total_capacity and grid_units.size() > 0:
		#var deploy_card = grid_units[0]
		#if deploy_card is Control: 
			#units.append(deploy_card)
			#grid_units.erase(deploy_card)
			#
	#if units.is_empty():
		#return
		
	# 2. Sort available enemy units by best attackers first
	var available_attackers: Array[CardToken]
	available_attackers.append_array(Bus.Grid.enemy_front.get_units())
	available_attackers.append_array(Bus.Grid.enemy_back.get_units())
	available_attackers.sort_custom(sort_by_attack_ratio) # Assuming this still exists!
	
	# 3. Calculate Enemy's Absolute Maximum Damage
	var max_potential_damage = 0
	for attacker in available_attackers:
		if attacker.can_act:
			max_potential_damage += attacker.current_damage
		
	# 4. Gather and sort Player targets by our new Priority Score
	var player_units = Bus.Grid.get_units("Player")
	
	# UPDATED: Pass 'true' for real stats, and 'max_potential_damage' to check for lethality
	player_units.sort_custom(func(a, b): return _get_target_priority(a, true, max_potential_damage) > _get_target_priority(b, true, max_potential_damage))
	
	# 5. Determine required damage for kills
	var player_front_shield = Bus.Grid.player_front.get_pooled_shield(false)
	var required_damage = player_front_shield
	var confirmed_kills_damage = 0
	
	for target in player_units:
		# Can we break the shield AND kill this target?
		if max_potential_damage >= (required_damage + target.current_health):
			required_damage += target.current_health
			confirmed_kills_damage = required_damage # Save the threshold
		else:
			break # Stop planning attacks, any extra damage is just blocked anyway
			
	# 6. Assign roles based on required damage
	var backline_units: Array = grid_units
	var frontline_units: Array = []
	var committed_damage = 0
	
	for unit in available_attackers:
		# If we haven't met our kill quota, and there's room, put them in back
		if committed_damage < confirmed_kills_damage and backline_units.size() < max_back:
			backline_units.append(unit)
			committed_damage += unit.current_damage
		# Otherwise, we don't need their damage, so put them in front to defend
		elif frontline_units.size() < max_front:
			frontline_units.append(unit)
		# If the front is full, overflow back into the backline
		else:
			if backline_units.size() < max_back:
				backline_units.append(unit)
	
	# 7. Execute Movement 
	var back_slots = Bus.Grid.enemy_back.all_slots.duplicate()
	var front_slots = Bus.Grid.enemy_front.all_slots.duplicate()
	
	for unit in backline_units:
		if unit.current_slot and unit.current_slot.box == Bus.Grid.enemy_back:
			back_slots.erase(unit.current_slot)
			
	for unit in frontline_units:
		if unit.current_slot and unit.current_slot.box == Bus.Grid.enemy_front:
			front_slots.erase(unit.current_slot)
	
	for unit in backline_units:
		if back_slots.is_empty(): continue
		if unit.current_slot and unit.current_slot.box == Bus.Grid.enemy_back: continue
		unit.move_to(back_slots.pop_front())
			
	for unit in frontline_units:
		if front_slots.is_empty(): continue
		if unit.current_slot and unit.current_slot.box == Bus.Grid.enemy_front: continue
		unit.move_to(front_slots.pop_front())
		
func on_trigger(trigger: String, trigger_card: Control):
	if enemy_dupe.ranks.size() > 0:
		return
	# Check if no enemy units left to trigger combat win
	if trigger == "discard" and trigger_card.card_owner == "Enemy":
		await get_tree().process_frame
		
		# Check if any enemy units are still on the board
		var alive_units = Bus.Grid.get_units("Enemy")
		for unit in alive_units:
			if unit.card_owner == "Enemy":
				return
				
		# Check if there are any pending cards in the queue
		for child in card_grid.get_children():
			# Replace "Control" with "Card" or your base card class name
			if child is Control: 
				return
				
		Bus.Board.combat_won()

func sort_by_attack_ratio(unit1, unit2) -> bool:
	var get_ratio = func(u):
		var dmg = float(u.current_damage)
		if u.card_resource.box_priority == "Support":
			dmg = float(u.card_resource.equivalent_damage)
		return Utils.safe_divide(dmg, float(u.current_health + u.current_shield))
		
	var r1 = get_ratio.call(unit1)
	var r2 = get_ratio.call(unit2)
	
	# Higher ratio goes first
	if r1 > r2: return true
	if r1 == r2: return unit1.current_damage >= unit2.current_damage
	return false

func sort_by_block_efficiency(unit1, unit2) -> bool:
	# Prioritize units with high block and health vs low attack
	var get_ratio = func(u):
		var block_val = float(u.current_shield + u.current_health)
		var dmg_val = float(u.current_damage)
		
		if dmg_val == 0:
			return block_val * 10.0 # High priority for pure blockers
		return block_val / dmg_val
		
	var r1 = get_ratio.call(unit1)
	var r2 = get_ratio.call(unit2)
	
	# Higher block ratio goes first
	if r1 > r2: return true
	if r1 == r2: return (unit1.current_shield + unit1.current_health) >= (unit2.current_shield + unit2.current_health)
	return false

func _get_target_priority(unit: Control, real: bool, available_damage: int) -> float:
	# 1. Absolute Priority: Taunt
	if unit.has_method("has_tag") and unit.has_tag("Taunt"):
		return 9999.0
		
	var hp = unit.current_health if real else unit.remaining_life
	var dmg = unit.current_damage if real else unit.remaining_base_damage
	var shield = unit.current_shield
	
	if hp <= 0:
		return -1.0 # Dead units are ignored
		
	var score: float = 0.0
	
	# 2. Value per HP: Target high-value, fragile units (Glass Cannons or weak Tanks)
	score += float(dmg + shield) / float(hp)
	
	# 3. Lethality Check: Massive priority to units we can completely kill this turn
	var kill_bonus = 100.0
	if available_damage >= hp:
		score += kill_bonus
		
	return score

func get_sorted_targets(real: bool, available_damage: int) -> Array:
	# Gather living player units
	var player_units = Bus.Grid.get_units("Player").filter(func(u): return (u.current_health if real else u.remaining_life) > 0)
	
	# Sort them using the AI priority system
	player_units.sort_custom(func(a, b): return _get_target_priority(a, real, available_damage) > _get_target_priority(b, real, available_damage))
	
	return player_units

func distribute_damage(amount: int, real: bool) -> void:
	var remaining_damage = amount
	var valid_targets = get_sorted_targets(real, remaining_damage)
	
	# Apply damage sequentially based on AI priority
	for unit in valid_targets:
		if remaining_damage <= 0:
			break
			
		var hp = unit.current_health if real else unit.remaining_life
		var health_dmg = min(remaining_damage, hp)
		
		if real:
			unit.current_health -= health_dmg
			remaining_damage -= health_dmg
		else:
			# Preview update
			unit.remaining_life -= health_dmg
			remaining_damage -= health_dmg
			
	# Hit the gate if real combat overflows past all units
	if remaining_damage > 0 and real and Bus.gate:
		Bus.gate.current_health -= remaining_damage
