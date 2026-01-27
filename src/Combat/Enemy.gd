class_name Enemy
extends Control

@export var res: EnemyResource

#func _ready() -> void:
	#ee.start_turn.connect(on_turn_start)

func on_turn_start(_turn_num: int):
	await move_units_forward()
	if res.ranks.size() == 0:
		return
	var next_rank: EnemyRank = res.ranks.pop_front()
	Bus.Grid.deploy_enemy_rank(next_rank)

func move_units_forward():
	for file: UnitFile in Bus.Grid.get_children():
		var slots: Array = file.box.get_children()
		# reverse otherwise it will move same unit forward again
		slots.reverse()
		for slot: TokenSlot in slots:
			if slot.occupied_unit:
				var unit: CardToken = slot.occupied_unit
				if unit.card_owner == "Enemy":
					move_unit_forward(unit)

func move_unit_forward(token: CardToken):
	var idx = token.current_slot.get_index()
	if idx >= token.current_slot.file.box.get_child_count() - 1:
		return
	var next_slot: TokenSlot = token.current_slot.file.box.get_child(idx + 1)
	if next_slot.occupied_unit:
		return
	token.move_to(next_slot)
