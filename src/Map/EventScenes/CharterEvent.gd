extends Control

@onready var charter_scene: PackedScene = preload("uid://dowba0pffhlkj")

var charters: Array[UnitResource]

func _ready() -> void:
	choose_units()
	for unit in charters:
		var charter = charter_scene.instantiate()
		charter.card_resource = unit
		%Choices.add_child(charter)
		charter.setup()
		charter.button.pressed.connect(choose_charter.bind(unit))

func choose_units():
	var candidates: Array[UnitResource]
	for unit: UnitResource in Bus.player.charters:
		for upgrade in unit.upgrade_options:
			if Bus.player.charters.has(upgrade) or candidates.has(upgrade):
				continue
			candidates.append(upgrade)
	candidates.shuffle()
	charters = candidates.slice(0, 3)

func choose_charter(unit: UnitResource):
	Bus.player.charters.append(unit)
	leave()
	
func leave():
	kf.load_map()
