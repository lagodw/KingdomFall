extends Button

@onready var choice_scene = preload("uid://ky4h0wpdmvoj")
@onready var panel: TextureRect = $ConstructionPanel

func _ready() -> void:
	var choices: Array = R.buildings.get_matching_resource([])
	setup_choices(choices)
	pressed.connect(show_panel)
	$ConstructionPanel/Cancel.pressed.connect(cancel)
	Bus.new_scene_loaded.connect(move_panel)
	
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
	var duped = building.duplicate(true)
	get_tree().current_scene.add_building(duped)
	Bus.player.town.buildings.append(duped)
	panel.visible = false
	
func cancel():
	panel.visible = false

func show_panel():
	panel.visible = true
