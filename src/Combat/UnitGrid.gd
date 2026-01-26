class_name UnitGrid
extends GridContainer

@onready var slot_scene: PackedScene = preload("uid://cshkmwknv7s5g")

@export var num_files: int = 5
@export var num_enemy_slots: int = 2
@export var num_neutral_slots: int = 2
@export var num_player_slots: int = 2

func _ready() -> void:
	for row in num_enemy_slots:
		for col in num_files:
			add_slot("Enemy")
	for row in num_neutral_slots:
		for col in num_files:
			add_slot("Neutral")
	for row in num_player_slots:
		for col in num_files:
			add_slot("Player")

func add_slot(slot_owner: String):
	var slot = slot_scene.instantiate()
	slot.card_owner = slot_owner
	add_child(slot)
