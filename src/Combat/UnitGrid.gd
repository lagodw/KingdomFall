class_name UnitGrid
extends VBoxContainer

@onready var file_scene: PackedScene = preload("uid://bsp0fgo7c1qcn")

@export var num_files: int = 5
@export var num_enemy_slots: int = 2
@export var num_neutral_slots: int = 2
@export var num_player_slots: int = 2

func _ready() -> void:
	var even: bool = false
	for i in num_files:
		add_file(even)
		even = not even

func add_file(even: bool):
	var file: UnitFile = file_scene.instantiate()
	add_child(file)
	file.create_slots(num_player_slots, num_neutral_slots, 
			num_enemy_slots, even)
