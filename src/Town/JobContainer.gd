class_name JobContainer
extends Control

@onready var slot_scene = preload("uid://cshkmwknv7s5g")
@onready var progress_scene = preload("uid://bpxp4s2o7n5ef")
@onready var token_grid: GridContainer = %TokenGrid
@onready var highlight: ReferenceRect = $Highlight

var job: Job
var bldg: Building

func _ready() -> void:
	%Description.text = kf.replace_skill_icons(job.description)
	update_progress()
	setup_slots()
	for effect in job.effects:
		effect.connect_signal(self)
	mouse_exited.connect(show_highlight.bind(false))
	call_deferred("set_control_size")
	
func set_control_size():
	custom_minimum_size = $V.size

func update_progress():
	if job.requirements.size() == 0 or bldg.under_construction:
		%Requirements.visible = false
		return
	else:
		%Requirements.visible = true
	for requirement in job.requirements:
		var skill: UnitSkill.Skill = requirement.skill
		var current_progress: int = 0
		for progress in job.progress:
			if skill == progress.skill:
				current_progress += progress.amount
		var scene = progress_scene.instantiate()
		scene.skill = skill
		scene.progress = current_progress
		scene.required = requirement.amount
		%Requirements.add_child(scene)

func setup_slots():
	for child in token_grid.get_children():
		child.queue_free()
	for i in job.capacity:
		var slot: TokenSlot = slot_scene.instantiate()
		slot.job = self
		if bldg.under_construction:
			slot.slot_type = TokenSlot.SlotType.Neutral
		token_grid.add_child(slot)

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	if find_first_slot():
		show_highlight(true)
		return(true)
	return(false)

func _drop_data(_at_position: Vector2, data: Variant):
	kf.dragging = null
	if data.current_slot:
		data.current_slot.job.release_unit(data)
	add_unit(data)
	show_highlight(false)
	
func find_first_slot() -> TokenSlot:
	for slot: TokenSlot in token_grid.get_children():
		if not slot.occupied_unit:
			return(slot)
	return(null)

func add_unit(unit: Unit):
	bldg.fill_capacity_slot()
	var slot = find_first_slot()
	unit.move_to(slot, false)
	if unit is not CardToken:
		await get_tree().process_frame
		unit.token.move_card()

func move_tokens_up():
	for i in range(token_grid.get_child_count() - 1):
		var slot: TokenSlot = token_grid.get_child(i)
		if slot.occupied_unit:
			continue
		var next_slot: TokenSlot = token_grid.get_child(i + 1)
		if next_slot.occupied_unit:
			next_slot.occupied_unit.move_to(slot, false)

func release_unit(token: CardToken):
	token.current_slot.occupied_unit = null
	move_tokens_up()
	bldg.empty_capacity_slot()
	
func show_highlight(value: bool):
	highlight.visible = value

func get_occupants() -> Array[CardToken]:
	var units: Array[CardToken]
	for slot: TokenSlot in token_grid.get_children():
		if slot.occupied_unit:
			units.append(slot.occupied_unit)
	return(units)
