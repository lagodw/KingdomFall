class_name Building
extends Button

@onready var slot_scene = preload("uid://cshkmwknv7s5g")
@onready var highlight: ReferenceRect = $Highlight
@onready var capacitytxt: Label = $Capacity
@onready var token_grid: GridContainer = %TokenGrid
@onready var popup: TextureRect = $Popup

@export var res: BuildingResource

var capacity: int
var current_workers: int = 0

func _ready() -> void:
	popup = $Popup
	pressed.connect(toggle_popup)
	mouse_exited.connect(_on_mouse_exit)
	Bus.new_scene_loaded.connect(setup)
		
func setup():
	capacity = res.capacity
	remove_child(popup)
	get_tree().current_scene.call_deferred("add_child", popup)
	set_popup_position()
	update_capacity()
	set_art()
	setup_slots()
	
func _on_mouse_exit():
	show_highlight(false)
	
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	if current_workers < capacity:
		show_highlight(true)
		return(true)
	return(false)

func _drop_data(_at_position: Vector2, data: Variant):
	kf.dragging = null
	current_workers += 1
	add_unit(data)
	update_capacity()
	
func show_highlight(value: bool):
	highlight.visible = value

func update_capacity():
	capacitytxt.text = str("%s/%s"%[current_workers, capacity])

func set_art():
	var texture: Texture = R.building_art.get_matching_resource(
			["**%s.png"%res.building_name])[0]
	$Art.texture = texture
	
func setup_slots():
	for child in token_grid.get_children():
		child.queue_free()
	for i in capacity:
		var slot = slot_scene.instantiate()
		token_grid.add_child(slot)

func find_first_slot() -> TokenSlot:
	for slot: TokenSlot in token_grid.get_children():
		if not slot.occupied_unit:
			return(slot)
	return(null)

func add_unit(unit: Unit):
	var slot = find_first_slot()
	unit.move_to(slot, false)

func show_popup(value: bool):
	set_popup_position()
	popup.visible = value

func toggle_popup():
	show_popup(not popup.visible)

func set_popup_position():
	if popup.global_position.x >= get_viewport_rect().size.x - popup.size.x:
		popup.global_position.x = global_position.x - popup.size.x - 10
	else:
		popup.global_position.x = global_position.x + size.x + 10
	popup.global_position.y = min(global_position.y,
		get_viewport_rect().size.y - popup.size.y)
