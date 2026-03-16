class_name UnitFile
extends MarginContainer

@onready var slot_scene = preload("uid://cshkmwknv7s5g")
@onready var PlayerBox: UnitBox = $Boxes/PlayerBox
@onready var EnemyBox: UnitBox = $Boxes/EnemyBox

func _ready() -> void:
	ee.start_turn.connect(on_start_turn)

func create_slots(num_player_slots: int = 1, num_enemy_slots: int = 1) -> void:
	PlayerBox.file = self
	EnemyBox.file = self
	for i in num_enemy_slots:
		add_slot("Enemy")
	for i in num_player_slots:
		add_slot("Player")
		
	PlayerBox.setup()
	EnemyBox.setup()
	
func on_start_turn(_turn_num: int):
	for unit in get_units("Player"):
		unit.current_fatigue += 1
	
func add_slot(slot_owner: String):
	var slot: TokenSlot = slot_scene.instantiate()
	slot.card_owner = slot_owner
	slot.slot_type = TokenSlot.SlotType.Vanguard
	slot.file = self
	slot.box = get("%sBox"%slot_owner)
	get("%sBox"%slot_owner).box.add_child(slot)
	
func get_units(unit_owner: String) -> Array[CardToken]:
	var box: UnitBox = get("%sBox"%unit_owner)
	return(box.get_units())
	
func add_enemy_unit(unit: Unit) -> void:
	var slots = EnemyBox.all_slots
	slots.reverse()
	var target_slot: TokenSlot
	for slot: TokenSlot in slots:
		if slot.card_owner == "Enemy" and not slot.occupied_unit:
			target_slot = slot
	unit.move_to(target_slot)
	
func find_next_target(attacker: CardToken = null, real: bool = true) -> CardToken:
	var health_var: String = "current_health"
	if not real:
		health_var = "remaining_life"
		
	if Bus.gate.get(health_var) <= 0:
		return(null)
	
	var target_owner: String = kf.invert_owner(attacker.card_owner)
	var box: UnitBox = get("%sBox"%target_owner)
	
	if attacker.card_resource.tags.has(kf.Tag.Stealth):
		# Stealth Targeting: Rearmost Support -> Rearmost Fighting -> Face
		for i in range(box.support_slots.size() - 1, -1, -1):
			var slot = box.support_slots[i]
			if slot.occupied_unit:
				if slot.occupied_unit.get(health_var) > 0:
					return slot.occupied_unit
		for i in range(box.fighting_slots.size() - 1, -1, -1):
			var slot = box.fighting_slots[i]
			if slot.occupied_unit:
				if slot.occupied_unit.get(health_var) > 0:
					return slot.occupied_unit
	else:
		# Standard Targeting: Frontmost Fighting -> Frontmost Support -> Face
		for slot in box.fighting_slots:
			if slot.occupied_unit:
				if slot.occupied_unit.get(health_var) > 0:
					return(slot.occupied_unit)
		for slot in box.support_slots:
			if slot.occupied_unit:
				if slot.occupied_unit.get(health_var) > 0:
					return(slot.occupied_unit)
	
	if attacker.card_owner == "Enemy":
		return(Bus.gate)
	return(null)
	
func combat(real: bool = true):
	var health_var = "current_health" if real else "remaining_life"
	var unit_dicts: Array[Dictionary] = []
	
	unit_dicts.append_array(get_box_unit_dict(PlayerBox))
	unit_dicts.append_array(get_box_unit_dict(EnemyBox))
	
	# 3. Sort by: Speed (Highest First) -> Rank (Frontmost First) -> Side (Enemy First)
	unit_dicts.sort_custom(sort_combat)
	
	# 4. Execute combat sequence
	for entry in unit_dicts:
		if Bus.gate.get(health_var) <= 0:
			return
			
		await _process_unit_combat(entry.unit, real)
		
		if real and Bus.Board.combat_over:
			return

func get_box_unit_dict(box: UnitBox) -> Array[Dictionary]:
	var side: String = "Enemy"
	if box.player_box:
		side = "Player"
	var units: Array[Dictionary]
	for unit: CardToken in box.get_units():
		var rank_idx = unit.current_slot.get_index()
		if side == "Enemy":
			rank_idx = box.box.get_child_count() - rank_idx - 1
		units.append({
			"unit": unit,
			"speed": unit.current_speed,
			"rank": rank_idx,
			"side": side
		})
	return(units)

func sort_combat(unitA: Dictionary, unitB: Dictionary) -> bool:
	if unitA.speed != unitB.speed:
		return unitA.speed > unitB.speed
	
	if unitA.rank != unitB.rank:
		return unitA.rank < unitB.rank
	
	return unitA.side == "Enemy"

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
	while unit.get(attack_var) > 0 and unit.get(health_var) > 0 and Bus.gate.get(health_var) > 0:
		var target = find_next_target(unit, real)
		if not target:
			break
			
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
