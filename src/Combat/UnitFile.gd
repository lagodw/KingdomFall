class_name UnitFile
extends Control

@onready var slot_scene = preload("uid://cshkmwknv7s5g")
@onready var box: HBoxContainer = $Box

func create_slots(num_player_slots: int = 1, num_neutral_slots: int = 1,
			num_enemy_slots: int = 1) -> void:
	for i in num_enemy_slots:
		add_slot(TokenSlot.SlotType.Enemy)
	for i in num_neutral_slots:
		add_slot(TokenSlot.SlotType.Neutral)
	for i in num_player_slots:
		add_slot(TokenSlot.SlotType.Player)
	
func add_slot(slot_type: TokenSlot.SlotType):
	var slot: TokenSlot = slot_scene.instantiate()
	slot.slot_type = slot_type
	slot.file = self
	box.add_child(slot)
	
func get_units(unit_owner: String = "All") -> Array[CardToken]:
	var units: Array[CardToken]
	for slot: TokenSlot in box.get_children():
		if slot.occupied_unit:
			var unit = slot.occupied_unit
			if unit.card_owner == unit_owner or unit_owner == "All":
				units.append(unit)
	return(units)
	
func add_enemy_unit(unit: Unit) -> void:
	var slots = box.get_children()
	slots.reverse()
	var target_slot: TokenSlot
	for slot: TokenSlot in slots:
		if slot.slot_type == TokenSlot.SlotType.Enemy and not slot.occupied_unit:
			target_slot = slot
	unit.move_to(target_slot)
	
func find_next_target(attacker: CardToken = null, real: bool = true) -> CardToken:
	var health_var: String = "current_health"
	if not real:
		health_var = "remaining_life"
	
	var towards_gate: bool = attacker.card_owner == "Enemy"
	var next_slot: TokenSlot = attacker.current_slot
	for i in attacker.current_attack_range:
		if not next_slot:
			break
		next_slot = next_slot.get_next_slot(towards_gate)
		if not next_slot:
			if attacker.card_owner == "Enemy":
				return(Bus.gate)
			return(null)
		if not next_slot.occupied_unit:
			continue
		var next_unit: CardToken = next_slot.occupied_unit
		if next_unit.get(health_var) > 0 and next_unit.card_owner != attacker.card_owner:
			return(next_unit)
			
	return(null)

func combat(real: bool = true):
	var health_var = "current_health" if real else "remaining_life"
	var unit_dicts: Array[Dictionary] = []

	unit_dicts.append_array(get_unit_dict())

	# 3. Sort by: Speed (Highest First) -> Rank (Frontmost First) -> Side (Enemy First)
	unit_dicts.sort_custom(sort_combat)
	
	# 4. Execute combat sequence
	for entry in unit_dicts:
		if Bus.gate.get(health_var) <= 0:
			return
			
		await _process_unit_combat(entry.unit, real)
		
		if real and Bus.Board.combat_over:
			return

func get_unit_dict() -> Array[Dictionary]:
	var units: Array[Dictionary]
	for unit: CardToken in get_units("All"):
		var rank_idx = unit.current_slot.get_index()
		units.append({
			"unit": unit,
			"speed": unit.current_speed,
			"rank": rank_idx,
		})
	return(units)

func sort_combat(unitA: Dictionary, unitB: Dictionary) -> bool:
	if unitA.speed != unitB.speed:
		return unitA.speed > unitB.speed
		
	if unitA.rank != unitB.rank:
		return unitA.rank < unitB.rank
	
	return false

# Helper to process a unit's full attack sequence (until exhausted or dead)
func _process_unit_combat(unit: CardToken, real: bool) -> void:
	var attack_var: String = "current_damage"
	var health_var: String = "current_health"
	if not real:
		attack_var = "remaining_base_damage"
		health_var = "remaining_life"
	
	# Check if unit is capable of attacking
	if unit.get(health_var) <= 0 or unit.get(attack_var) <= 0 or not unit.can_act:
		return
	
	# Attack loop
	var target = find_next_target(unit, real)
	if not target:
		return
		
	if real:
		if Bus.Board.combat_over:
			return
	await unit.attack(target, real)

func update_previews():
	if Bus.Board.combat_happening:
		return
	combat(false)

func start_attacks() -> void:
	await combat(true)
