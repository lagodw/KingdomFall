class_name TokenSlot
extends TextureRect

# Emitted when mouse exits this slot *while* dragging
signal slot_exited(slot: TokenSlot)

enum SlotType {
	Player,
	Neutral,
	Enemy,
}

@onready var border: TextureRect = $Border

@export var slot_type: SlotType
var occupied_unit: CardToken = null
var file: UnitFile
var job: JobContainer

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
	border.visible = false

func show_highlight(highlight: bool = true):
	border.visible = highlight
	
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is CardToken:
		if Bus.Board:
			if slot_type != SlotType.Enemy and data.can_act and (
				Bus.Grid.get_slot_distance(data.current_slot, self) <= 1):
				show_highlight(true)
				return(true)
			else:
				return(false)
		else:
			return(true)
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
	if (idx >= file.box.get_child_count() - 1 and towards_gate) or (
			idx <= 0 and not towards_gate):
		return(null)
	var next_idx: int = idx
	if towards_gate:
		next_idx += 1
	else:
		next_idx -= 1
	return(file.box.get_children()[next_idx])

func toggle_highlight(slot_owner: String):
	for color in ["Enemy", "Neutral", "Player"]:
		var highlight = get_node("%sOutline"%slot_owner)
		highlight.visible = (color == slot_owner)
	
