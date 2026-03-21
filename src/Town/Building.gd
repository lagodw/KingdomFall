class_name Building
extends Control

@onready var capacity_panel = preload("uid://ctc1gy8wqgc02")
@onready var job_container = preload("uid://bvkv7nfap7j1t")
@onready var highlight: ReferenceRect = $Button/Highlight
@onready var popup: TextureRect = $Popup
@onready var jobs_box: VBoxContainer = %JobsBox
@onready var capacity_grid: GridContainer = %CapacityGrid

@export var resource: BuildingResource

var capacity: int
var under_construction: bool = false
var job_containers: Array[JobContainer]

func _ready() -> void:
	popup = $Popup
	$Button.pressed.connect(toggle_popup)
	%Demolish.pressed.connect(demolish)
	mouse_exited.connect(_on_mouse_exit)
	Bus.new_scene_loaded.connect(setup)
	add_to_group("Buildings")
		
func setup():
	if get_tree().current_scene is not Town:
		return
	for job in resource.jobs:
		if job.description == "Construction":
			under_construction = true
			var requirement = job.requirements[0]
			job.capacity = requirement.amount - requirement.progress
			capacity = job.capacity
			$Button/UnderConstruction.visible = true
		var container: JobContainer = job_container.instantiate()
		container.job = job
		container.bldg = self
		if under_construction and job.description != "Construction":
			container.disabled = true
		jobs_box.add_child(container)
		job_containers.append(container)
	if not under_construction:
		for job in resource.jobs:
			capacity += job.capacity
	jobs_box.move_child($Popup/JobsBox/BuildOptions, -1)
	remove_child(popup)
	get_tree().current_scene.call_deferred("add_child", popup)
	set_popup_position()
	set_art()
	setup_capacity_panels()
	
func _on_mouse_exit():
	show_highlight(false)
	
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	for container in job_containers:
		if container._can_drop_data(_at_position, _data):
			show_highlight(true)
			return(true)
	return(false)

func _drop_data(_at_position: Vector2, data: Variant):
	kf.dragging = null
	for container in job_containers:
		if container._can_drop_data(_at_position, data):
			container._drop_data(_at_position, data)
			return
	
func show_highlight(value: bool):
	highlight.visible = value

func set_art():
	var texture: Texture = R.building_art.get_matching_resource(
			["**%s.png"%resource.building_name])[0]
	$Button/Art.texture = texture
		
func fill_capacity_slot(token: CardToken):
	for panel in capacity_grid.get_children():
		if not panel.occupant:
			panel.fill_panel(token, under_construction)
			return

func empty_capacity_slot(token: CardToken):
	var slots: Array = capacity_grid.get_children()
	# add from front but remove from rear
	slots.reverse()
	for panel in slots:
		if panel.occupant:
			if panel.occupant == token:
				panel.empty_panel()
				return

func show_popup(value: bool):
	set_popup_position()
	popup.visible = value

func toggle_popup():
	set_popup_position()
	popup.visible = not popup.visible

func set_popup_position():
	popup.size = jobs_box.size + Vector2(20, 20)
	if global_position.x + size.x >= get_viewport_rect().size.x - popup.size.x:
		popup.global_position.x = global_position.x - popup.size.x - 10
	else:
		popup.global_position.x = global_position.x + size.x + 10
	popup.global_position.y = min(global_position.y,
		get_viewport_rect().size.y - popup.size.y)

func get_occupants() -> Array[CardToken]:
	var units: Array[CardToken]
	for container in job_containers:
		units.append_array(container.get_occupants())
	return(units)
	
func get_worker_count() -> int:
	return(get_occupants().size())

func setup_capacity_panels():
	for job in job_containers:
		if job.disabled:
			continue
		for i in job.job.capacity:
			var cap = capacity_panel.instantiate()
			capacity_grid.add_child(cap)
			cap.set_panel(false, under_construction)

func demolish():
	for token in get_occupants():
		Bus.town.reset_token(token)
	Bus.player.town.buildings.erase(resource)
	popup.queue_free()
	queue_free()
