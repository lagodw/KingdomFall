class_name Enemy
extends Control

var enemy_dupe: EnemyResource
var card_grid: Control

func _ready() -> void:
	var res: EnemyResource = Bus.map.current_location.enemy
	enemy_dupe = res.dupe()
	Bus.trigger_occurred.connect(on_trigger)
	Bus.board_loaded.connect(add_cards)
	ee.start_turn.connect(on_turn_start)
	
## add enemy units to a hidden grid on board
## units will be deployed from this grid
## 1 by 1 when space is available in each file
func add_cards():
	var num_files: int = Bus.Grid.files.size()
	card_grid = Bus.Board.get_node("EnemyCards")
	var ranks: Array[EnemyRank] = enemy_dupe.ranks
	ranks.reverse()
	for i in num_files:
		var box: HBoxContainer = HBoxContainer.new()
		card_grid.add_child(box)
		for rank in ranks:
			if rank.units.size() > 0:
				var unit = rank.units.pop_front()
				var card = kf.create_card(unit, "Enemy")
				box.add_child(card)
			else:
				var control = Control.new()
				control.custom_minimum_size = Bus.card_size
				box.add_child(control)

func on_turn_start(_turn_num: int):
	# don't play before CardToken or can_act will be true
	await get_tree().process_frame
	for i in Bus.Grid.files.size():
		deploy_units(i)

func deploy_units(file_num: int):
	var units: Array[Unit]
	var file: UnitFile = Bus.Grid.files[file_num]
	for unit in file.EnemyBox.get_units():
		units.append(unit)
	if units.size() < file.EnemyBox.box.get_child_count():
		var hbox: HBoxContainer = card_grid.get_children()[file_num]
		if hbox.get_child_count() == 0:
			return
		var deploy_unit: Control = hbox.get_children()[-1]
		if deploy_unit is Unit:
			units.append(deploy_unit)
		else:
			deploy_unit.queue_free()
	units.sort_custom(sort_by_attack_ratio)
	units.reverse()
	var slots: Array[TokenSlot] = Bus.Grid.files[file_num].EnemyBox.all_slots.duplicate(true)
	#slots.reverse()
	# lowest attack ratio unit to the front
	for slot in slots:
		if units.size() == 0:
			return
		var unit: Unit = units.pop_front()
		unit.move_to(slot)
		
func on_trigger(trigger: String, trigger_card: Control):
	# Check if no enemy units left
	if trigger == "discard":
		if trigger_card.card_owner == "Enemy":
			await get_tree().process_frame
			for unit: CardToken in Bus.Grid.get_units("Enemy"):
				if unit.card_owner == "Enemy":
					return
			for box: HBoxContainer in card_grid.get_children():
				for child in box.get_children():
					if child is Card:
						return
			Bus.Board.combat_won()

func sort_by_attack_ratio(unit1: Unit, unit2: Unit) -> bool:
	var get_ratio = func(u: Unit):
		var dmg = float(u.current_damage)
		if u.card_resource.box_priority == "Support":
			dmg = float(u.card_resource.equivalent_damage)
		return Utils.safe_divide(dmg, float(u.current_health + u.current_shield))
		
	var r1 = get_ratio.call(unit1)
	var r2 = get_ratio.call(unit2)
	
	if r1 > r2: return true
	if r1 == r2: return unit1.current_damage >= unit2.current_damage
	return false
