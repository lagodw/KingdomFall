class_name TokenSlot
extends TextureRect

# Emitted when mouse exits this slot *while* dragging
signal slot_exited(slot: TokenSlot)

enum SlotType {
	Player,
	Neutral,
	Enemy,
}

@export var slot_type: SlotType
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
	match slot_type:
		SlotType.Player:
			$PlayerOutline.visible = true
		SlotType.Neutral:
			$NeutralOutline.visible = true
		SlotType.Enemy:
			$EnemyOutline.visible = true
		
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
	
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if slot_type == SlotType.Player and not occupied_unit and data.current_activation <= Bus.energy:
		show_highlight(true)
		return(true)
	return(false)

func _drop_data(_at_position: Vector2, data: Variant):
	data.move_to(self)
	kf.dragging = null
	
# Called when dragging *from* this slot
func clear_unit() -> void:
	occupied_unit = null

# Called by the File
func get_occupied_unit_data() -> Unit:
	if occupied_unit:
		return occupied_unit
	return null

func get_next_slot(towards_gate: bool = true) -> TokenSlot:
	var idx = get_index()
	if idx >= file.box.get_child_count() - 1 or idx <= 0:
		return(null)
	var next_idx: int = idx
	if towards_gate:
		next_idx += 1
	else:
		next_idx -= 1
	return(file.box.get_children()[next_idx])
