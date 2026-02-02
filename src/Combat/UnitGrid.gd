class_name UnitGrid
extends VBoxContainer

@onready var file_scene: PackedScene = preload("uid://bsp0fgo7c1qcn")

@export var num_files: int = 5
@export var num_enemy_slots: int = 2
@export var num_player_slots: int = 2
var files: Array[UnitFile]

func _ready() -> void:
	Bus.Grid = self
	for i in num_files:
		add_file()
	Bus.trigger_occurred.connect(on_trigger)

func on_trigger(trigger: String, _trigger_card: Control):
	if trigger in ['target', 'cast', 'discard', 'attach', 'move', 'consume_used']:
		perform_maintenance()
		await get_tree().process_frame
		update_previews()
		
func add_file():
	var file: UnitFile = file_scene.instantiate()
	add_child(file)
	file.create_slots(num_player_slots, num_enemy_slots)
	files.append(file)

func deploy_enemy_rank(rank: EnemyRank):
	var lane_num: int = 0
	for res in rank.units:
		var unit: Unit = kf.create_card(res, "Enemy")
		Bus.Board.get_node("Enemy").add_child(unit)
		get_child(lane_num).add_enemy_unit(unit)
		await get_tree().process_frame
		lane_num += 1
	
func calculate_slot_distance(slot1: TokenSlot, slot2: TokenSlot) -> int:
	if slot1.file == slot2.file:
		return(abs(slot1.get_index() - slot2.get_index()))
	else:
		return(abs(slot1.file.get_index() - slot2.file.get_index()))

func start_combat():
	for file: UnitFile in get_children():
		await file.start_attacks()

func reset_previews() -> void:
	get_tree().call_group("Tokens", "reset_remaining")
	
func update_previews() -> void:
	reset_previews()
	await get_tree().process_frame
	for file: UnitFile in get_children():
		file.update_previews()

func get_units(unit_owner: String = "All") -> Array[CardToken]:
	var units: Array[CardToken]
	for file: UnitFile in get_children():
		units.append_array(file.get_units(unit_owner))
	return(units)

func get_slot_distance(slot1: TokenSlot, slot2: TokenSlot) -> int:
	var slot_distance = abs(slot1.get_index() - slot2.get_index())
	var file_distance = abs(slot1.file.get_index() - slot2.file.get_index())
	return(slot_distance + file_distance)

func bump_units_sideways(selected_slot: TokenSlot, direction: String) -> TokenSlot:
	if not selected_slot.occupied_unit:
		if selected_slot.temporary_bumped_unit:
			selected_slot.temporary_bumped_unit.move_to(selected_slot)
			selected_slot.temporary_bumped_unit = null
		return(null)
		
	var selected_box: UnitBox = selected_slot.box
	var file_index: int = files.find(selected_box.file)
	var slot_index: int = selected_slot.get_index()
	
	var dir_int: int = 0
	if direction == "Left":
		dir_int = -1
	elif direction == "Right":
		dir_int = 1
	else:
		return null
		
	# 1. Find the target file (the first one with an empty slot)
	var target_file_index: int = -1
	var check_index: int = file_index + dir_int
	
	while check_index >= 0 and check_index < files.size():
		var box_to_check: UnitBox = files[check_index].PlayerBox
		if slot_index < box_to_check.box.get_child_count():
			var slot_to_check: TokenSlot = box_to_check.box.get_child(slot_index)
			if not slot_to_check.occupied_unit:
				target_file_index = check_index
				break
		check_index += dir_int
		
	if target_file_index == -1:
		return null
		
	# 2. Cascade Move
	# We iterate backwards from the empty target slot to the selected slot.
	# For each step, we move the unit AND store it as a temporary bump.
	var current_dest_file_index: int = target_file_index
	
	while current_dest_file_index != file_index:
		var source_file_index: int = current_dest_file_index - dir_int
		
		var dest_box: UnitBox = files[current_dest_file_index].PlayerBox
		var dest_slot: TokenSlot = dest_box.box.get_child(slot_index)
		
		var source_box: UnitBox = files[source_file_index].PlayerBox
		var source_slot: TokenSlot = source_box.box.get_child(slot_index)
		
		# Move the unit
		var unit_moving = source_slot.occupied_unit
		if unit_moving:
			unit_moving.move_to(dest_slot, false)
			# Tell the source slot it is temporarily missing this unit.
			# We do this AFTER the move so the slot doesn't fight us.
			source_slot.temporary_bumped_unit = unit_moving
				
		current_dest_file_index = source_file_index
		
	return selected_slot

func show_rank_highlight(selected_slot: TokenSlot):
	$RankHighlight.global_position.y = selected_slot.global_position.y
	$RankHighlight.visible = true
	
func hide_rank_highlight():
	$RankHighlight.visible = false
	
func perform_maintenance() -> void:
	if kf.dragging != null or Bus.Board.combat_happening:
		return
		
	for file in files:
		if file.PlayerBox:
			for slot in file.PlayerBox.all_slots:
				slot.validate_state()
			file.PlayerBox.move_units_up()
				
		if file.EnemyBox:
			for slot in file.EnemyBox.all_slots:
				slot.validate_state()
			file.EnemyBox.move_units_up()

func get_next_open_slot(slot_type: TokenSlot.SlotType, slot_owner: String = "Enemy") -> TokenSlot:
	for file in files:
		var box: UnitBox = file.get("%sBox"%slot_owner)
		for slot: TokenSlot in box.all_slots:
			if slot.slot_type == slot_type and not slot.occupied_unit:
				return(slot)
	return(null)
