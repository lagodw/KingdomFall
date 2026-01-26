class_name UnitFile
extends Control

@onready var slot_scene = preload("uid://cshkmwknv7s5g")
@onready var box: HBoxContainer = $Box

func create_slots(num_player_slots: int = 1, num_neutral_slots: int = 1,
			num_enemy_slots: int = 1, even_file: bool = false) -> void:
	for i in num_enemy_slots:
		add_slot(TokenSlot.SlotType.Enemy, even_file)
	for i in num_neutral_slots:
		add_slot(TokenSlot.SlotType.Neutral, even_file)
	for i in num_player_slots:
		add_slot(TokenSlot.SlotType.Player, even_file)
	
func add_slot(slot_type: TokenSlot.SlotType, dark: bool):
	var slot: TokenSlot = slot_scene.instantiate()
	slot.slot_type = slot_type
	slot.dark_floor = dark
	slot.file = self
	box.add_child(slot)
	
func get_units(_unit_owner: String) -> Array[CardToken]:
	return([])
	
func find_next_target(target_owner: String, _attacker: CardToken = null, _real: bool = true) -> CardToken:
	#var health_var: String = "current_health"
	#if not real:
		#health_var = "remaining_life"
		#
	#if Bus.get("%sFace"%target_owner).get(health_var) <= 0:
		#return(null)
	#
	#if attacker.card_resource.tags.has(kf.Tag.Stealth):
		## Stealth Targeting: Rearmost Support -> Rearmost Fighting -> Face
		#for i in range(box.support_slots.size() - 1, -1, -1):
			#var slot = box.support_slots[i]
			#if slot.occupied_unit:
				#if slot.occupied_unit.get(health_var) > 0:
					#return slot.occupied_unit
		#for i in range(box.fighting_slots.size() - 1, -1, -1):
			#var slot = box.fighting_slots[i]
			#if slot.occupied_unit:
				#if slot.occupied_unit.get(health_var) > 0:
					#return slot.occupied_unit
	#else:
		## Standard Targeting: Frontmost Fighting -> Frontmost Support -> Face
		#for slot in box.fighting_slots:
			#if slot.occupied_unit:
				#if slot.occupied_unit.get(health_var) > 0:
					#return(slot.occupied_unit)
		#for slot in box.support_slots:
			#if slot.occupied_unit:
				#if slot.occupied_unit.get(health_var) > 0:
					#return(slot.occupied_unit)
					
	return(Bus.get("%sFace"%target_owner))

func combat(real: bool = true):
	return(real)
	#var health_var: String = "current_health"
	#if not real:
		#health_var = "remaining_life"
		#
	## Iterate Rank by Rank
	#for i in range(num_fighting_slots + num_support_slots + 1):
		## Stop if either Face is dead
		#if Bus.PlayerFace.get(health_var) <= 0 or Bus.EnemyFace.get(health_var) <= 0:
			#return
#
		## Identify units in this rank
		## Note: fighting_slots are 0-indexed from the Front for both boxes
		#var player_unit: CardToken = null
		#if i < PlayerBox.fighting_slots.size():
			#player_unit = PlayerBox.fighting_slots[i].occupied_unit
		#elif i < PlayerBox.fighting_slots.size() + PlayerBox.support_slots.size():
			#var unit = PlayerBox.support_slots[i - PlayerBox.fighting_slots.size()].occupied_unit
			#if unit:
				#if unit.card_resource.tags.has(kf.Tag.Volley):
					#player_unit = unit
		#elif PlayerBox.face_slot:
			#if Bus.PlayerFace.current_damage > 0:
				#player_unit = Bus.PlayerFace
			#
		#var enemy_unit: CardToken = null
		#if i < EnemyBox.fighting_slots.size():
			#enemy_unit = EnemyBox.fighting_slots[i].occupied_unit
		#elif i < EnemyBox.fighting_slots.size() + EnemyBox.support_slots.size():
			#var unit = EnemyBox.support_slots[i - EnemyBox.fighting_slots.size()].occupied_unit
			#if unit:
				#if unit.card_resource.tags.has(kf.Tag.Volley):
					#enemy_unit = unit
		#elif EnemyBox.face_slot:
			#if Bus.EnemyFace.current_damage > 0:
				#enemy_unit = Bus.EnemyFace
			#
		## Determine Turn Order (Default: Enemy First)
		#var first: CardToken = enemy_unit
		#var second: CardToken = player_unit
		#
		## If Player is Mounted, they go first
		#if player_unit and player_unit.card_resource.tags.has(kf.Tag.Mounted):
			#first = player_unit
			#second = enemy_unit
			#
		## Execute Turns
		#if first:
			#await _process_unit_combat(first, real)
			#if real and Bus.Board.combat_over: return
			#if not real and (Bus.PlayerFace.get(health_var) <= 0 or Bus.EnemyFace.get(health_var) <= 0): return
			#
		#if second:
			#await _process_unit_combat(second, real)
			#if real and Bus.Board.combat_over: return
			#if not real and (Bus.PlayerFace.get(health_var) <= 0 or Bus.EnemyFace.get(health_var) <= 0): return

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
		
	var target_owner: String = "Enemy"
	if unit.card_owner == "Enemy":
		target_owner = "Player"
	
	var face = Bus.get("%sFace"%target_owner)
	
	# Attack loop
	while unit.get(attack_var) > 0 and unit.get(health_var) > 0 and face.get(health_var) > 0:
		var target = find_next_target(target_owner, unit, real)
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
	#await combat(true)
	pass
