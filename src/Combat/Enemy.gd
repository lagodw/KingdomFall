class_name Enemy
extends Control

var enemy_dupe: EnemyResource
var card_grid: Control

func _ready() -> void:
	var res: EnemyResource = Bus.map.night_enemies.pop_front()
	enemy_dupe = res.dupe()
	Bus.trigger_occurred.connect(on_trigger)
	Bus.board_loaded.connect(init_card_grid)
	ee.start_turn.connect(on_turn_start)
	
func init_card_grid():
	card_grid = Bus.Board.get_node("EnemyCards")

func on_turn_start(turn_num: int):
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
	var units: Array = []
	
	# 1. Gather units already on the board
	units.append_array(Bus.Grid.enemy_front.get_units())
	units.append_array(Bus.Grid.enemy_back.get_units())
	
	# 2. Determine max capacity
	var max_front = Bus.Grid.enemy_front.all_slots.size()
	var max_back = Bus.Grid.enemy_back.all_slots.size()
	var total_capacity = max_front + max_back
	
	var grid_units = card_grid.get_children()
	# 3. Pull new units from the queue until we hit capacity
	while units.size() < total_capacity and grid_units.size() > 0:
		var deploy_card = grid_units[0]
		
		if deploy_card is Unit:
			units.append(deploy_card)
			if grid_units.has(deploy_card):
				grid_units.erase(deploy_card)
		#else:
			#deploy_card.queue_free()
			
	if units.is_empty():
		return
		
	# 4. Sort by attack ratio (highest ratio first)
	units.sort_custom(sort_by_attack_ratio)
	
	var backline_units: Array = []
	var frontline_units: Array = []
	
	# 5. Divide in half. Highest attack units go to backline.
	var target_back_size = min(max_back, ceil(units.size() / 2.0))
	
	for unit in units:
		if backline_units.size() < target_back_size:
			backline_units.append(unit)
		elif frontline_units.size() < max_front:
			frontline_units.append(unit)
		else:
			# Fallback in case frontline filled up but backline still has room
			if backline_units.size() < max_back:
				backline_units.append(unit)
			
	var back_slots = Bus.Grid.enemy_back.all_slots.duplicate()
	var front_slots = Bus.Grid.enemy_front.all_slots.duplicate()
	
	# 6. Move backline units to slots
	for unit in backline_units:
		if not back_slots.is_empty():
			var slot = back_slots.pop_front()
			unit.move_to(slot)
			
	# 7. Move frontline units to slots
	for unit in frontline_units:
		if not front_slots.is_empty():
			var slot = front_slots.pop_front()
			unit.move_to(slot)

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
