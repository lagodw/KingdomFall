class_name UnitBox
extends Control

@export var player_box: bool = false
@export_enum("Player", "Neutral", "Enemy") var box_owner: String = "Neutral"

@onready var box: VBoxContainer = $Box
@onready var fighting_slots: Array[TokenSlot] = []
@onready var support_slots: Array[TokenSlot] = []
@onready var face_slot: TokenSlot
var file: UnitFile

# --- State ---
var all_slots: Array[TokenSlot] = []
var current_highlight: TokenSlot = null

func setup():
	for child in box.get_children():
		if child is TokenSlot:
			all_slots.append(child)
			match child.slot_type:
				TokenSlot.SlotType.Support:
					support_slots.append(child)
				TokenSlot.SlotType.Vanguard, TokenSlot.SlotType.Assault:
					fighting_slots.append(child)
	
			child.slot_exited.connect(_on_slot_exited)
			
	if not player_box:
		fighting_slots.reverse()
		support_slots.reverse()
		
	Bus.trigger_occurred.connect(on_trigger)
	
func on_trigger(trigger: String, _trigger_card: Control):
	if Bus.Board.combat_happening:
		return
	if trigger in ["start_turn", "discard"]:
		move_units_up()

func _on_slot_exited(_slot_exited):
	move_units_up()
	clear_all_highlights()

# Called by TokenSlot._get_drag_data
func _on_unit_drag_started(_unit: Unit, slot_dragged_from: TokenSlot):
	slot_dragged_from.clear_unit()
	move_units_up()

# --- Drop Logic Functions (Called by TokenSlot) ---
func can_drop_on_slot(slot_queried: TokenSlot, unit: Unit, direction: String = "Back") -> bool:
	# 1. Clear previous highlights (prevents multiple slots lighting up)
	clear_all_highlights()
	
	# 2. Calculate logic
	var target_slot = find_target_slot(slot_queried, direction)
	
	if target_slot and is_drop_valid(target_slot, unit):
		# 3. Apply Highlight
		target_slot.show_highlight()
		current_highlight = target_slot
		return true
	
	return false

func drop_unit_on_slot(slot_dropped_on: TokenSlot, unit: Unit):
	var target_slot = find_target_slot(slot_dropped_on)
	
	if not target_slot or not is_drop_valid(target_slot, unit):
		kf.dragging = null
		clear_all_highlights()
		return
	# If we found a valid slot, it is guaranteed to be empty now
	# (either it was empty, or find_target_slot pushed units during hover)
	target_slot.set_unit(unit)
	# If we dropped onto the slot that had a temporary bump (side bump),
	# we must clear the reference so the bumped unit doesn't try to return 
	# when the mouse leaves.
	if target_slot == slot_dropped_on and slot_dropped_on.temporary_bumped_unit:
		slot_dropped_on.temporary_bumped_unit = null

	# Finalize drop
	kf.dragging = null
	clear_all_highlights()

func find_target_slot(slot_hovered: TokenSlot, push_direction: String = "Back") -> TokenSlot:
	if not slot_hovered.get_box().player_box:
		return null
		
	var slot_list: Array[TokenSlot] = []
	# Determine which list to use
	if slot_hovered.slot_type == TokenSlot.SlotType.Support:
		slot_list = support_slots
	else:
		slot_list = fighting_slots
	
	# 1. If slot is not occupied:
	# Return the furthest forward unoccupied slot.
	# Note: If a side-bump happened, slot_hovered.occupied_unit is null, so we enter here.
	if not slot_hovered.occupied_unit:
		for slot in slot_list:
			if not slot.occupied_unit:
				return(slot)
	
	var index: int = slot_list.find(slot_hovered)
	if index == -1:
		return null
	
	# 2. Try Side Bump if requested
	if push_direction in ["Left", "Right"]:
		var side_bump_slot: TokenSlot = Bus.Grid.bump_units_sideways(slot_hovered, push_direction)
		if side_bump_slot:
			return(side_bump_slot)
	# 3. Try Push Back (Default or Fallback)
	# This runs if push_direction is "Back" OR if the side bump above failed
	var space_available = false
	for i in range(index, slot_list.size()):
		if not slot_list[i].occupied_unit:
			space_available = true
			break
		
	if space_available:
		push_units_back(slot_hovered)
		return(slot_hovered)
			
	return null

# Checks if a unit can *legally* be placed in a target slot
func is_drop_valid(target_slot: TokenSlot, unit: Unit) -> bool:
	if not player_box: 
		return(false)
	
	if target_slot.slot_type == TokenSlot.SlotType.Support:
		if not unit.has_support:
			return(false)
		
	if target_slot.occupied_unit:
		return(false)
		
	return(true)

func clear_all_highlights():
	if current_highlight:
		current_highlight.show_highlight(false)
		current_highlight = null
	
	# Failsafe in case state gets weird
	for slot in all_slots:
		slot.show_highlight(false)

func move_units_up():
	for i in range(1, fighting_slots.size()):
		if fighting_slots[i].occupied_unit and not fighting_slots[i - 1].occupied_unit:
			fighting_slots[i].occupied_unit.move_to(fighting_slots[i - 1], false)
			
	for i in range(1, support_slots.size()):
		if support_slots[i].occupied_unit and not support_slots[i - 1].occupied_unit:
			support_slots[i].occupied_unit.move_to(support_slots[i - 1], false)

func push_units_back(starting_slot: TokenSlot) -> void:
	var slot_list: Array[TokenSlot] = []
	if starting_slot.slot_type == TokenSlot.SlotType.Support:
		slot_list = support_slots
	else:
		slot_list = fighting_slots
		
	var index = slot_list.find(starting_slot)
	if index == -1:
		return 
	
	for i in range(slot_list.size() - 1, index, -1):
		var slot_to_move = slot_list[i - 1]
		var slot_to_fill = slot_list[i]
		
		if slot_to_fill.occupied_unit == null and slot_to_move.occupied_unit != null:
			slot_to_move.occupied_unit.move_to(slot_to_fill, false)

func get_units() -> Array[CardToken]:
	var units: Array[CardToken] = []
	for slot: TokenSlot in box.get_children():
		if slot.occupied_unit:
			units.append(slot.occupied_unit)
	return(units)
	
func get_first_unoccupied(support: bool = false) -> TokenSlot:
	var slot_list: Array[TokenSlot] = []
	if support:
		slot_list = support_slots
	else:
		slot_list = fighting_slots
	for slot in slot_list:
			if not slot.occupied_unit:
				return(slot)
	return(null)

func get_last_fighting_slot() -> TokenSlot:
	if fighting_slots[-1].occupied_unit:
		return(null)
	else:
		return(fighting_slots[-1])
	
func get_last_support_slot() -> TokenSlot:
	if support_slots[-1].occupied_unit:
		return(null)
	else:
		return(support_slots[-1])

func set_highlight(show_highlight: bool):
	$Highlight.visible = show_highlight
