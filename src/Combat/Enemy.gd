class_name Enemy
extends Control

var enemy_dupe: EnemyResource
var card_grid: Control

func _ready() -> void:
	var res: EnemyResource = Bus.map.current_location.enemy
	enemy_dupe = res.dupe()
	Bus.trigger_occurred.connect(on_trigger)
	Bus.board_loaded.connect(on_board_loaded)
	ee.start_turn.connect(on_turn_start)
	
func on_board_loaded():
	card_grid = Bus.Board.get_node("EnemyCards")
	
## add enemy units to a hidden grid on board
## units will be deployed from this grid
## 1 by 1 when space is available in each file
func add_cards(turn_num: int):
	if not turn_num in enemy_dupe.ranks:
		return
	var rank: EnemyRank = enemy_dupe.ranks[turn_num].dupe()
	enemy_dupe.ranks.erase(turn_num)
	for resource in rank.units:
		var card = kf.create_card(resource, "Enemy")
		card_grid.add_child(card)

func on_turn_start(turn_num: int):
	add_cards(turn_num)
	# don't play before CardToken or can_act will be true
	await get_tree().process_frame
	play_units()

		
func on_trigger(trigger: String, trigger_card: Control):
	# Check if no enemy units left
	if trigger == "discard":
		if trigger_card.card_owner == "Enemy":
			await get_tree().process_frame
			for unit: CardToken in Bus.Grid.get_units("Enemy"):
				if unit.card_owner == "Enemy":
					return
			if card_grid.get_child_count() > 0:
				return
			if enemy_dupe.ranks.size() > 0:
				return
			Bus.Board.combat_won()

## Evaluates the current board state and enemy hand to determine the optimal 
## placement for all available enemy units. 
##
## The logic follows these steps:
## 1. Gathering & Sorting: Collects all units (from hand and board) and splits 
##    them into two pools: active fighters (can attack this turn), inactive 
##    fighters (cannot act, like newly played units).
## 2. Priority Filtering: Sorts fighters based on their attack_ratio (attack / health).
## 3. Tactical Placement: Iterates through the board files. It prioritizes 
##    filling fighting slots with active fighters first. If it runs out of 
##    active fighters to fill a file, it merges the remaining active fighters 
##    with inactive fighters and continues.
## 4. Stack Composition: Within a file, the unit with the lowest attack ratio 
##    (typically a tank) is placed in the front slot as a defender. Units with 
##    higher attack ratios are placed in the back slots as attackers.
## 5. Execution: Commands all evaluated units to move to their new positions.
func play_units() -> void:
	if not Bus.Board: return
	if Bus.Board.combat_over: return
	
	var active_fighters: Array[Unit] = []
	var inactive_fighters: Array[Unit] = []
	
	# 1. Gather all Units (Hand + Board)
	var all_units = []
	for card in card_grid.get_children():
		if card is Unit: 
			all_units.append(card)
			inactive_fighters.append(card)
	for unit in Bus.Grid.get_units("Enemy"):
		# Ensure we gather all units on the board regardless of can_act status
		if unit is not Face and not unit.discarded: 
			all_units.append(unit)
			if not unit.act_disabled:
				active_fighters.append(unit)
	
	# 2. Sort Fighting Pools by Attack Ratio
	active_fighters.sort_custom(sort_by_attack_ratio)
	inactive_fighters.sort_custom(sort_by_attack_ratio)
	
	var file_index: int = 0
	var destinations: Dictionary[Unit, TokenSlot] = {}
	
	var combined_pool: Array[Unit] = []
	var using_combined: bool = false
	
	# 3. Place Fighting Units
	while file_index < Bus.Grid.files.size():
		var current_box: UnitBox = Bus.Grid.files[file_index].EnemyBox
		var slots: Array[TokenSlot] = current_box.fighting_slots.duplicate(true)
		var slots_needed: int = slots.size()
		
		var current_pool: Array[Unit]
		
		# Check if we have enough active fighters to fully fill this file's slots
		if not using_combined and active_fighters.size() >= slots_needed:
			current_pool = active_fighters
		else:
			# If we don't have enough, merge remaining active and inactive fighters
			if not using_combined:
				combined_pool = active_fighters + inactive_fighters
				combined_pool.sort_custom(sort_by_attack_ratio)
				using_combined = true
			current_pool = combined_pool
			
		# Stop trying to fill files if we ran out of fighting units
		if current_pool.is_empty():
			break
			
		# Defender (Front) - lowest ratio (pop_back)
		var defender: Unit = current_pool.pop_back()
		var target_slot = slots.pop_front()
		destinations[defender] = target_slot
		
		# Attacker (Back) - highest ratio (pop_front)
		# Have highest ratio unit in back
		slots.reverse() 
		for fighting_slot in slots:
			if not current_pool.is_empty():
				var attacker: Unit = current_pool.pop_front()
				destinations[attacker] = fighting_slot
			
		file_index += 1
	
	# 4. Execute Moves
	for unit in destinations:
		unit.move_to(destinations[unit])

func sort_by_attack_ratio(unit1: Unit, unit2: Unit) -> bool:
	var get_ratio = func(u: Unit):
		var dmg = float(u.current_damage)
		if u.card_resource.box_priority == "Support":
			dmg = float(u.card_resource.equivalent_damage)
		return Utils.safe_divide(dmg, float(u.current_health + u.current_shield))
		
	var r1 = get_ratio.call(unit1)
	var r2 = get_ratio.call(unit2)
	
	if r1 > r2: return true
	if r1 == r2: return unit1.current_damage >= unit2.current_damage
	return false
