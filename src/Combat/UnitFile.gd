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
	
func get_units(_unit_owner: String) -> Array[CardToken]:
	return([])
	
func add_enemy_unit(unit: Unit) -> void:
	var slots = box.get_children()
	slots.reverse()
	for slot: TokenSlot in slots:
		if slot.slot_type == TokenSlot.SlotType.Enemy and not slot.occupied_unit:
			unit.move_to(slot)
	
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
			return(null)
		if not next_slot.occupied_unit:
			continue
		var next_unit: CardToken = next_slot.occupied_unit
		if next_unit.get(health_var) > 0 and next_unit.card_owner != attacker.card_owner:
			return(next_unit)
	return(null)

func combat(real: bool = true):
	for slot: TokenSlot in box.get_children():
		if not slot.occupied_unit:
			continue
		var unit: CardToken = slot.occupied_unit
			
		await _process_unit_combat(unit, real)
		if real and Bus.Board.combat_over: return

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
