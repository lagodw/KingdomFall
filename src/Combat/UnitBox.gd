class_name UnitBox
extends Control

const TOKEN_SLOT_SCENE = preload("uid://cshkmwknv7s5g")

enum BoxType { FRONTLINE, BACKLINE }

@export_enum("Player", "Enemy") var box_owner: String = "Player"
@export var box_type: BoxType = BoxType.FRONTLINE
@export var num_slots: int = 4

@onready var shield_icon = preload("uid://b6lm11rvw7ni3")
@onready var broken_shield_icon = preload("uid://b1odsqq1346uc")
@onready var box: HBoxContainer = $Box
@onready var stats_preview: Label = %StatsPreview
@onready var stat_icon: TextureRect = %StatIcon
@onready var shield_mat: ShaderMaterial = %StatIcon.material

var all_slots: Array[TokenSlot] = []
var current_highlight: TokenSlot = null
var is_breached: bool = false
var pooled_additive: int = 0
var pooled_multiplier: float = 1.0

func _ready():
	add_to_group("UnitBoxes")
	if box_type == BoxType.FRONTLINE:
		stat_icon.texture = load("uid://b6lm11rvw7ni3")
	for i in num_slots:
		var slot = TOKEN_SLOT_SCENE.instantiate()
		slot.slot_exited.connect(_on_slot_exited)
		slot.box = self
		slot.card_owner = box_owner
		box.add_child(slot)
		all_slots.append(slot)
	
	ee.start_turn.connect(on_start_turn)
	mouse_exited.connect(show_highlight.bind(false))

func on_start_turn(_turn_num: int, _turn_owner: String):
	is_breached = false
	if box_type == BoxType.FRONTLINE:
		stat_icon.texture = shield_icon
	$AnimationPlayer.play("RESET")

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
		if unit.can_act and (unit.remaining_life > 0 or real):
			total += unit.get(dmg_var)
			
	total = int(max(0, (total + pooled_additive) * pooled_multiplier))
	return total

func get_pooled_shield(real: bool = true) -> int:
	var total = 0
	var shield_var = "current_shield" if real else "current_shield"
	for unit in get_units():
		# Add shield if the unit can act OR if the unit has the Prompt tag
		if unit.can_act or kf.Tag.Prompt in unit.tags:
			total += unit.get(shield_var)
			
	total = int(max(0, (total + pooled_additive) * pooled_multiplier))
	return total
	
func reset_effects() -> void:
	pooled_additive = 0
	pooled_multiplier = 1.0

func update_preview():
	if box_type == BoxType.FRONTLINE:
		stats_preview.text = str(get_pooled_shield(false))
	else:
		stats_preview.text = str(get_pooled_damage(false))

# --- Drag and Drop Logic ---
func _on_slot_exited(_slot_exited):
	clear_all_highlights()

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

# Called automatically by Godot when dragging over the UnitBox Control
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if is_drop_valid(data):
		show_highlight(true)
		return true
	return false

# Called automatically by Godot when dropping onto the UnitBox Control
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	drop_unit(data)

func drop_unit(unit: Unit) -> void:
	var target_slot = get_first_unoccupied_slot()
	if target_slot:
		target_slot.set_unit(unit)
	
	kf.dragging = null
	show_highlight(false)

func is_drop_valid(unit: Unit) -> bool:
	if box_owner != "Player": 
		return false
	# Enforce Support units to Backline only
	if box_type == BoxType.FRONTLINE and unit.has_support:
		return false
	# Make sure there is room in the box
	if get_first_unoccupied_slot() == null:
		return false
	return true

func get_first_unoccupied_slot() -> TokenSlot:
	for slot in all_slots:
		if slot.occupied_unit == null:
			return slot
	return null

func show_highlight(highlight: bool) -> void:
	$Outline.visible = highlight
	
func shift_units() -> void:
	# 1. Gather all currently placed units in order
	var current_units = get_units()
	
	# 2. Temporarily clear all slots to prevent assignment conflicts
	for slot in all_slots:
		slot.occupied_unit = null
		
	# 3. Reassign the units to the slots sequentially
	for i in range(current_units.size()):
		all_slots[i].set_unit(current_units[i])
		
	# Update the aggregate stats preview just in case
	update_preview()

func sword_animation():
	$AnimationPlayer.play("Slash_%s"%box_owner)
	await $AnimationPlayer.animation_finished

func send_block_animation():
	var defender_box: UnitBox = Bus.Grid.get("%s_front"%kf.invert_owner(box_owner).to_lower())
	defender_box.block_animation()

func block_animation():
	if not is_breached:
		$AnimationPlayer.play("Block")
		
	var flash_color = Color.FIREBRICK if is_breached else Color.WHITE
	shield_mat.set_shader_parameter("gleam_color", flash_color)
	# Tween the progress parameter from -0.5 (left) to 1.5 (right)
	var gleam_tween = create_tween()
	gleam_tween.tween_property(shield_mat, "shader_parameter/progress", 1.5, 0.5).from(-0.5)
	await gleam_tween.finished
	if is_breached:
		stat_icon.texture = broken_shield_icon
