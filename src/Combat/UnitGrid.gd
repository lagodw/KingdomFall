class_name UnitGrid
extends VBoxContainer

@onready var file_scene: PackedScene = preload("uid://bsp0fgo7c1qcn")

@export var num_files: int = 5
@export var num_enemy_slots: int = 2
@export var num_neutral_slots: int = 2
@export var num_player_slots: int = 2

func _ready() -> void:
	Bus.Grid = self
	for i in num_files:
		add_file()
	Bus.trigger_occurred.connect(on_trigger)

func on_trigger(trigger: String, _trigger_card: Control):
	if trigger in ['target', 'cast', 'discard', 'attach', 'move', 'consume_used']:
		update_previews()
		
func add_file():
	var file: UnitFile = file_scene.instantiate()
	add_child(file)
	file.create_slots(num_player_slots, num_neutral_slots, 
			num_enemy_slots)

func deploy_enemy_rank(rank: EnemyRank):
	var lane_num: int = 0
	for res in rank.units:
		var unit: Unit = kf.create_card(res, "Enemy")
		Bus.Board.get_node("Enemy").add_child(unit)
		await get_tree().create_timer(2).timeout
		get_child(lane_num).add_enemy_unit(unit)
		await get_tree().process_frame
		lane_num += 1
	
func calculate_slot_distance(slot1: TokenSlot, slot2: TokenSlot) -> int:
	if slot1.file == slot2.file:
		return(abs(slot1.get_index() - slot2.get_index()))
	else:
		return(abs(slot1.file.get_index() - slot2.file.get_index()))

func start_combat():
	for file: UnitFile in get_children():
		await file.start_attacks()

func reset_previews() -> void:
	get_tree().call_group("Tokens", "reset_remaining")
	
func update_previews() -> void:
	reset_previews()
	await get_tree().process_frame
	for file: UnitFile in get_children():
		file.update_previews()
