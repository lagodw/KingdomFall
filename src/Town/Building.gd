class_name Building
extends Control

@onready var slot_scene = preload("uid://cshkmwknv7s5g")
@onready var highlight: ReferenceRect = $Button/Highlight
@onready var token_grid: GridContainer = %TokenGrid
@onready var popup: TextureRect = $Popup

@export var resource: BuildingResource

var capacity: int

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
		capacity = construction_left
		$Button/UnderConstruction.visible = true
	%Description.text = resource.description
	remove_child(popup)
	get_tree().current_scene.call_deferred("add_child", popup)
	set_popup_position()
	set_art()
	setup_slots()
	
func _on_mouse_exit():
	show_highlight(false)
	
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	print('drop?')
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
		var slot = slot_scene.instantiate()
		slot.building = self
		token_grid.add_child(slot)
	if capacity > 3:
		popup.size.y += Bus.token_size.y + 5
	if capacity > 6:
		popup.size.x += 15

func find_first_slot() -> TokenSlot:
	print(token_grid.get_children())
	for slot: TokenSlot in token_grid.get_children():
		print(slot.occupied_unit)
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

func get_worker_count() -> int:
	var num_workers: int = 0
	for slot: TokenSlot in token_grid.get_children():
		if slot.occupied_unit:
			num_workers += 1
	return(num_workers)
