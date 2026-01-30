class_name Building
extends Control

@onready var slot_scene = preload("uid://cshkmwknv7s5g")
@onready var progress_scene = preload("uid://bpxp4s2o7n5ef")
@onready var highlight: ReferenceRect = $Button/Highlight
@onready var token_grid: GridContainer = %TokenGrid
@onready var popup: TextureRect = $Popup
@onready var popup_v: VBoxContainer = $Popup/V

@export var resource: BuildingResource

var capacity: int
var under_construction: bool = false

func _ready() -> void:
	popup = $Popup
	$Button.pressed.connect(toggle_popup)
	mouse_exited.connect(_on_mouse_exit)
	Bus.new_scene_loaded.connect(setup)
	add_to_group("Buildings")
		
func setup():
	if get_tree().current_scene is not Town:
		return
	var construction_left: int = resource.construction_cost - resource.current_construction
	if construction_left <= 0:
		capacity = resource.capacity
	else:
		under_construction = true
		capacity = construction_left
		$Button/UnderConstruction.visible = true
		$Button/UnderConstruction/ConstructionAmt.text = str(construction_left)
	update_progress()
	%Description.text = kf.replace_skill_icons(resource.description)
	remove_child(popup)
	get_tree().current_scene.call_deferred("add_child", popup)
	set_popup_position()
	set_art()
	setup_slots()
	for effect in resource.effects:
		effect.connect_signal(self)
	
func _on_mouse_exit():
	show_highlight(false)
	
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	if find_first_slot():
		show_highlight(true)
		return(true)
	return(false)

func _drop_data(_at_position: Vector2, data: Variant):
	kf.dragging = null
	add_unit(data)
	
func show_highlight(value: bool):
	highlight.visible = value

func set_art():
	var texture: Texture = R.building_art.get_matching_resource(
			["**%s.png"%resource.building_name])[0]
	$Button/Art.texture = texture
	
func setup_slots():
	for child in token_grid.get_children():
		child.queue_free()
	for i in capacity:
		var slot: TokenSlot = slot_scene.instantiate()
		slot.building = self
		if under_construction:
			slot.slot_type = TokenSlot.SlotType.Neutral
		token_grid.add_child(slot)

func find_first_slot() -> TokenSlot:
	for slot: TokenSlot in token_grid.get_children():
		if not slot.occupied_unit:
			return(slot)
	return(null)

func add_unit(unit: Unit):
	var slot = find_first_slot()
	unit.move_to(slot, false)
	if unit is not CardToken:
		await get_tree().process_frame
		unit.token.move_card()

func show_popup(value: bool):
	set_popup_position()
	popup.visible = value

func toggle_popup():
	popup.visible = not popup.visible
	set_popup_position()

func set_popup_position():
	popup.size = popup_v.size + Vector2(20, 20)
	if popup.global_position.x >= get_viewport_rect().size.x - popup.size.x:
		popup.global_position.x = global_position.x - popup.size.x - 10
	else:
		popup.global_position.x = global_position.x + size.x + 10
	popup.global_position.y = min(global_position.y,
		get_viewport_rect().size.y - popup.size.y)

func release_unit(token: CardToken):
	token.current_slot.occupied_unit = null
	move_tokens_up()

func move_tokens_up():
	for i in range(token_grid.get_child_count() - 1):
		var slot: TokenSlot = token_grid.get_child(i)
		if slot.occupied_unit:
			continue
		var next_slot: TokenSlot = token_grid.get_child(i + 1)
		if next_slot.occupied_unit:
			next_slot.occupied_unit.move_to(slot, false)

func end_day():
	for slot: TokenSlot in token_grid.get_children():
		if slot.occupied_unit:
			slot.occupied_unit.card_resource.fatigue += 5
	if resource.current_construction < resource.construction_cost:
		resource.current_construction += get_worker_count()

func get_occupants() -> Array[CardToken]:
	var units: Array[CardToken]
	for slot: TokenSlot in token_grid.get_children():
		if slot.occupied_unit:
			units.append(slot.occupied_unit)
	return(units)
	
func get_worker_count() -> int:
	return(get_occupants().size())

func update_progress():
	if resource.requirements.size() == 0 or under_construction:
		%Requirements.visible = false
		return
	else:
		%Requirements.visible = true
	for requirement in resource.requirements:
		var skill: UnitSkill.Skill = requirement.skill
		var current_progress: int = 0
		for progress in resource.progress:
			if skill == progress.skill:
				current_progress += progress.amount
		var scene = progress_scene.instantiate()
		scene.skill = skill
		scene.progress = current_progress
		scene.required = requirement.amount
		%Requirements.add_child(scene)
