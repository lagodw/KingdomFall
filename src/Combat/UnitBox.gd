class_name UnitBox
extends Control

const TOKEN_SLOT_SCENE = preload("uid://cshkmwknv7s5g")

enum BoxType { FRONTLINE, BACKLINE }

@export_enum("Player", "Enemy") var box_owner: String = "Player"
@export var box_type: BoxType = BoxType.FRONTLINE
@export var num_slots: int = 4

@onready var box: VBoxContainer = $Box
@onready var stats_preview: Label = %StatsPreview

var all_slots: Array[TokenSlot] = []
var current_highlight: TokenSlot = null

func _ready():
	if box_type == BoxType.FRONTLINE:
		%StatIcon.texture = load("uid://b6lm11rvw7ni3")
	for i in num_slots:
		var slot = TOKEN_SLOT_SCENE.instantiate()
		slot.slot_exited.connect(_on_slot_exited)
		slot.box = self
		slot.card_owner = box_owner
		box.add_child(slot)
		all_slots.append(slot)
	
	Bus.trigger_occurred.connect(on_trigger)

func on_trigger(trigger: String, _trigger_card: Control):
	if Bus.Board and Bus.Board.combat_happening:
		return
	if trigger in ["start_turn", "discard", "play", "cast", "move"]:
		update_preview()

# --- Pooled Stats Calculation ---
func get_units() -> Array[CardToken]:
	var units: Array[CardToken] = []
	for slot in all_slots:
		if slot.occupied_unit:
			units.append(slot.occupied_unit)
	return units

func get_pooled_damage(real: bool = true) -> int:
	var total = 0
	var dmg_var = "current_damage" if real else "current_damage"
	for unit in get_units():
		if unit.can_act and (unit.remaining_life > 0 or box_owner == "Enemy"):
			total += unit.get(dmg_var)
	return total

func get_pooled_shield(real: bool = true) -> int:
	var total = 0
	var shield_var = "current_shield" if real else "current_shield"
	for unit in get_units():
		total += unit.get(shield_var)
	return total

func update_preview():
	if box_type == BoxType.FRONTLINE:
		stats_preview.text = str(get_pooled_shield(false))
	else:
		stats_preview.text = str(get_pooled_damage(false))

# --- Drag and Drop Logic ---
func _on_slot_exited(_slot_exited):
	clear_all_highlights()

func can_drop_on_slot(slot_queried: TokenSlot, unit: Unit, _direction: String = "Back") -> bool:
	clear_all_highlights()
	if is_drop_valid(slot_queried, unit):
		slot_queried.show_highlight(true)
		current_highlight = slot_queried
		return true
	return false

func drop_unit_on_slot(slot_dropped_on: TokenSlot, unit: Unit):
	if is_drop_valid(slot_dropped_on, unit):
		slot_dropped_on.set_unit(unit)
	
	kf.dragging = null
	clear_all_highlights()
	update_preview()
	Bus.Grid.update_previews()

func is_drop_valid(target_slot: TokenSlot, unit: Unit) -> bool:
	if box_owner != "Player": 
		return false
	if target_slot.occupied_unit:
		return false
	# Optional: Enforce Support units to Backline only
	if box_type == BoxType.FRONTLINE and unit.has_support:
		return false
	return true

func clear_all_highlights():
	if current_highlight:
		current_highlight.show_highlight(false)
		current_highlight = null

func set_breach(breached: bool):
	if breached:
		%StatsPreview.set("theme_override_colors/font_color", Color.DARK_RED)
		%BreachHighlight.visible = true
	else:
		%StatsPreview.set("theme_override_colors/font_color", Color.WHITE)
		%BreachHighlight.visible = false
