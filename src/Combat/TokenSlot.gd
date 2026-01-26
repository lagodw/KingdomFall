class_name TokenSlot
extends TextureRect

# Emitted when mouse exits this slot *while* dragging
signal slot_exited(slot: TokenSlot)

enum SlotType {
	Vanguard,
	Assault,
	Support,
	Empty,
}

@export_enum("Player", "Neutral", "Enemy") var card_owner: String = "Player"
@export var slot_type: SlotType
var dark_floor: bool = false
var occupied_unit: CardToken = null:
	set(value):
		occupied_unit = value
		
		# Auto-Revert Logic:
		# If this slot becomes empty (value == null), and we have a unit 
		# that was temporarily bumped from here, bring it back.
		# We check 'current_mouse_zone == "None"' to ensure we are not the 
		# active slot being hovered (the active slot handles its own revert via mouse exit).
		if occupied_unit == null and temporary_bumped_unit and current_mouse_zone == "None":
			temporary_bumped_unit.move_to(self, false)
			temporary_bumped_unit = null
var box: UnitBox
var file: UnitFile
var current_mouse_zone: String = "None":
	set(new_zone):
		# If zone changes, we might need to revert a temporary bump
		if temporary_bumped_unit and new_zone != current_mouse_zone:
			temporary_bumped_unit.move_to(self, false)
			temporary_bumped_unit = null
		current_mouse_zone = new_zone
var temporary_bumped_unit: CardToken

func _ready() -> void:
	mouse_exited.connect(_on_mouse_exit)
		
func _on_mouse_exit():
	show_highlight(false)

func add_token(token: CardToken):
	occupied_unit = token
	if token.current_slot and token.current_slot != self:
		# Double check that the previous box actually thinks it holds this token
		# (Prevents clearing a slot that has already been taken over by someone else)
		if token.current_slot.occupied_unit == token:
			token.current_slot.occupied_unit = null
	# Only add as child if it isn't already our child
	if token.get_parent() != self:
		# Safety check: Remove from old parent if it has one
		if token.get_parent():
			token.get_parent().remove_child(token)
		add_child(token)
		
	token.current_slot = self
	token.visible = true
	$Border.visible = false

func show_highlight(highlight: bool = true):
	$Border.visible = highlight
	
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	show_highlight(true)
	return(true)

func _drop_data(_at_position: Vector2, data: Variant):
	data.move_to(self)
	kf.dragging = null
	
func get_box() -> UnitBox:
	return box
	
# Called when dragging *from* this slot
func clear_unit() -> void:
	occupied_unit = null

# Called by the File
func get_occupied_unit_data() -> Unit:
	if occupied_unit:
		return occupied_unit
	return null

func validate_state() -> void:
	# 1. Validate the Occupied Unit reference
	if occupied_unit:
		# If the object was deleted from memory but we still hold a ref
		if not is_instance_valid(occupied_unit):
			occupied_unit = null
		# If the unit exists but is physically parented to a different node
		elif occupied_unit.get_parent() != self:
			# This detects the specific glitch you mentioned.
			# By setting it to null, we trigger the setter you added previously,
			# which effectively says "I'm empty now, revert any temporary bumps!"
			occupied_unit = null
			
	# 2. Validate Physical Children (The Truth)
	# If variables say we are empty, but we actually hold a Unit child, claim it.
	if occupied_unit == null:
		for child in get_children():
			if child is CardToken and not child.is_queued_for_deletion():
				# We found a squatter. Update variable to match reality.
				occupied_unit = child
				# If we had a temp bump waiting, this line will incidentally 
				# prevent it from returning (since we are now occupied), which is correct.
				break
	
	if occupied_unit:
		occupied_unit.position = Vector2.ZERO
		
	# 3. Clean up stale Temporary Bumps
	if temporary_bumped_unit:
		# If the bumped unit died or was deleted while waiting
		if not is_instance_valid(temporary_bumped_unit):
			temporary_bumped_unit = null
		
	# 4. Evict Extra Children
	# If we have children that are not the occupied unit and not the temp bump, they are stuck.
	for child in get_children():
		if child is CardToken and not child.is_queued_for_deletion():
			# If child is occupied_unit, it's fine.
			# If child is temporary_bumped_unit, it's fine (waiting to return).
			if child != occupied_unit and child != temporary_bumped_unit:
				# This is an extra unit. Use the box to find it a home.
				if box:
					var target_slot = box.get_first_unoccupied(child.has_support)
					if target_slot:
						# Found a home, move it.
						child.move_to(target_slot, false)
