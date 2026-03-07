class_name JobContainer
extends MarginContainer

@onready var slot_scene = preload("uid://cshkmwknv7s5g")
@onready var progress_scene = preload("uid://bpxp4s2o7n5ef")
@onready var token_grid: GridContainer = %TokenGrid
@onready var highlight: ReferenceRect = $Highlight

var job: Job
var bldg: Building
var disabled: bool = false

func _ready() -> void:
	%Description.text = kf.replace_skill_icons(job.description)
	update_progress()
	setup_slots()
	for effect in job.effects:
		effect.connect_signal(self)
	mouse_exited.connect(show_highlight.bind(false))
	call_deferred("set_control_size")
	ee.night_fall.connect(on_night_fall)
	
func set_control_size():
	#custom_minimum_size = $V.size
	custom_minimum_size.y += job.requirements.size() * 80

func update_progress():
	if job.requirements.size() == 0:
		%Requirements.visible = false
		return
	else:
		%Requirements.visible = true
	for requirement in job.requirements:
		var skill: UnitSkill.Skill = requirement.skill
		var scene = progress_scene.instantiate()
		scene.skill = skill
		scene.progress = requirement.progress
		scene.required = requirement.amount
		%Requirements.add_child(scene)

func setup_slots():
	for child in token_grid.get_children():
		child.queue_free()
	if job.capacity > %TokenGrid.columns:
		$V/ScrollContainer.custom_minimum_size.y += Bus.token_size.y
	for i in job.capacity:
		var slot: TokenSlot = slot_scene.instantiate()
		slot.job = self
		if disabled:
			slot.card_owner = "Enemy"
		else:
			slot.card_owner = "Player"
		token_grid.add_child(slot)

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	if find_first_slot() and not disabled:
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
		unit.token.current_job = job
		update_currency_preview(unit.token, true)
	else:
		unit.current_job = job
		update_currency_preview(unit, true)

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
	token.current_job = null
	move_tokens_up()
	bldg.empty_capacity_slot()
	update_currency_preview(token, false)
	
func show_highlight(value: bool):
	highlight.visible = value

func update_currency_preview(unit: Unit, is_adding: bool):
	if not job or not job.effects:
		return
	for effect in job.effects:
		if effect.function == "change_bus_var" and effect.bus_var in ["gold", "wood", "stone", "food"]:
			var amt = effect.bus_var_change.get_value(unit, bldg, unit, {"trigger_card": bldg})
			var var_name = effect.bus_var + "_change"
			if is_adding:
				Bus.set(var_name, Bus.get(var_name) + amt)
			else:
				Bus.set(var_name, Bus.get(var_name) - amt)

func get_occupants() -> Array[CardToken]:
	var units: Array[CardToken]
	for slot: TokenSlot in token_grid.get_children():
		if slot.occupied_unit:
			units.append(slot.occupied_unit)
	return(units)

func on_night_fall():
	if job.requirements.size() > 0:
		for requirement in job.requirements:
			for slot: TokenSlot in token_grid.get_children():
				if slot.occupied_unit:
					var unit: CardToken = slot.occupied_unit
					for skill: UnitSkill in unit.card_resource.skills:
						if skill.skill_type == requirement.skill:
							requirement.progress += skill.amount * (10.0 - unit.card_resource.fatigue) / 10
		while job.check_if_done():
			for requirement in job.requirements:
				requirement.progress -= requirement.amount
			for effect in job.effects:
				effect.apply_effect({"trigger_card": bldg})
	for token in get_occupants():
		token.card_resource.fatigue += 5
