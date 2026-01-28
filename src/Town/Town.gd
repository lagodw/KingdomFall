class_name Town
extends Control

@onready var building_scene = preload("uid://2e28fvpdufxt")
@onready var building_grid: GridContainer = $Buildings/ScrollContainer/GridContainer

func _ready() -> void:
	for building in Bus.player.town.buildings:
		add_building(building)
	$Bottom/UnitPanel.load_units(Bus.deck.cards)
	$Bottom/EndTurn.pressed.connect(night_fall)
	var construction = load("uid://df7bb45nih6i8").instantiate()
	$Buildings/ScrollContainer/GridContainer.add_child(construction)
	
func night_fall():
	get_tree().call_group("Buildings", "end_day")
	kf.load_scene("uid://dvld0lyuo33oq")

func add_building(resource: BuildingResource):
	var building = building_scene.instantiate()
	building.resource = resource
	building_grid.add_child(building)
	# Move before construction
	building_grid.move_child(building, building_grid.get_child_count() - 2)
	building.setup()
