extends Control

@onready var charter_scene: PackedScene = preload("uid://dowba0pffhlkj")
@export var num_choices: int = 3

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
	#var candidates: Array[UnitResource]
	var candidates: Dictionary[String, UnitResource]
	var existing_names: Array
	for unit: UnitResource in Bus.player.charters.values():
		existing_names.append(unit.card_name)
	for unit: UnitResource in Bus.player.charters.values():
		for upgrade in unit.upgrade_options:
			if upgrade.card_name in candidates:
				continue
			if upgrade.card_name in existing_names:
				continue
			candidates[upgrade.card_name] = upgrade
	var names = candidates.keys()
	names.shuffle()
	for i in num_choices:
		if names.size() <= 0:
			return
		var unit_name = names.pop_front()
		charters.append(candidates[unit_name])

func choose_charter(unit: UnitResource):
	Bus.player.add_charter(unit)
	leave()
	
#func leave():
	#kf.load_map()

func leave():
	visible = false
	get_tree().paused = false
	if Bus.map.current_location.enemy.is_night_enemy:
		Bus.map.current_location = null
		kf.load_scene("uid://djtcf3x2wg721")
	else:
		Bus.map.current_location = null
		kf.load_map()
