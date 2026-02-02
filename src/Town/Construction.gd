extends Button

@onready var choice_scene = preload("uid://ky4h0wpdmvoj")
@onready var construction_job = preload("uid://cm852y2erusux")
@onready var panel: TextureRect = $ConstructionPanel

func _ready() -> void:
	var choices: Array = R.buildings.get_matching_resource([])
	choices.sort_custom(sort_by_construction)
	setup_choices(choices)
	pressed.connect(show_panel)
	$ConstructionPanel/Cancel.pressed.connect(cancel)
	Bus.new_scene_loaded.connect(move_panel)
	
func _input(event):
	if event is InputEventKey and panel.visible:
		if event.pressed and event.keycode == KEY_ESCAPE:
			panel.visible = false
			get_viewport().set_input_as_handled()
	
func move_panel():
	if get_tree().current_scene is not Town:
		return
	panel.visible = false
	remove_child(panel)
	panel.global_position = get_viewport_rect().size / 2 - panel.size / 2
	get_tree().current_scene.add_child(panel)
	
func setup_choices(choices: Array):
	for choice in choices:
		var button = choice_scene.instantiate()
		button.building = choice
		%Choices.add_child(button)
		button.pressed.connect(choose.bind(choice))
		
func choose(building: BuildingResource):
	var duped: BuildingResource = building.duplicate(true)
	var job: Job = construction_job.dupe()
	job.capacity = building.construction_cost
	job.requirements[0].amount = building.construction_cost
	duped.jobs.push_front(job)
	get_tree().current_scene.add_building(duped)
	Bus.player.town.buildings.append(duped)
	panel.visible = false
	if Bus.player.town.buildings.size() == Bus.player.town.building_spots:
		visible = false
	
func cancel():
	panel.visible = false

func show_panel():
	panel.visible = true

func sort_by_construction(building1: BuildingResource, 
		building2: BuildingResource) -> bool:
	if building1.construction_cost < building2.construction_cost:
		return(true)
	if building1.construction_cost == building2.construction_cost:
		return(building1.building_name <= building2.building_name)
	return(false)
