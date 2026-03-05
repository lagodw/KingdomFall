class_name Town
extends Control

@onready var building_scene = preload("uid://2e28fvpdufxt")
@onready var upgrade_button = preload("uid://7iyrp623m11p")
@onready var building_grid: GridContainer = $Buildings/BuildingGrid
@onready var upgrade_option_box: HBoxContainer = %UpgradeOptions

var upgrade_buttons: Array[Button]
var selected_upgrade_button: Button

func _ready() -> void:
	Bus.map.day_counter += 1
	for building in Bus.player.town.buildings:
		add_building(building)
	$Bottom/UnitPanel.load_units(Bus.deck.cards)
	$Bottom/EndTurn.pressed.connect(explore)
	if Bus.player.town.buildings.size() < Bus.player.town.building_spots:
		var construction = load("uid://df7bb45nih6i8").instantiate()
		building_grid.add_child(construction)
	$UnitUpgrades/Done.pressed.connect(leave)
	Bus.town = self
	Bus.mana = Bus.max_mana
	
func explore():
	for building in building_grid.get_children():
		# exclude construction
		if building is Building:
			building.show_popup(false)
	ee.emit_signal("night_fall")
	await get_tree().create_timer(0.1).timeout
	var population: int = Bus.deck.get_units().size()
	Bus.food -= population
	for unit in $Bottom/UnitPanel.get_units():
		unit.card_resource.fatigue -= 5
	if not check_for_upgrades():
		leave()

func leave():
	kf.load_map()

func add_building(resource: BuildingResource):
	var building = building_scene.instantiate()
	building.resource = resource
	building_grid.add_child(building)
	# Move before construction
	building_grid.move_child(building, building_grid.get_child_count() - 2)
	building.setup()

func check_for_upgrades() -> bool:
	var has_upgrade: bool = false
	for unit in Bus.deck.get_units():
		if unit.get_eligible_upgrades().size() > 0:
			var card = kf.create_card(unit)
			card.disabled = true
			var button: Button = upgrade_button.instantiate()
			button.add_child(card)
			button.card = card
			$UnitUpgrades/UnitPanel.box.add_child(button)
			button.pressed.connect(select_upgrade_unit.bind(button))
			upgrade_buttons.append(button)
			has_upgrade = true
	if has_upgrade:
		$UnitUpgrades.visible = true
	return(has_upgrade)

func select_upgrade_unit(chosen_button: Button):
	if selected_upgrade_button:
		selected_upgrade_button.selected = false
	for button in upgrade_buttons:
		button.show_highlight(false)
	chosen_button.select()
	selected_upgrade_button = chosen_button
	for unit in upgrade_option_box.get_children():
		unit.queue_free()
	var resource: UnitResource = chosen_button.card.card_resource
	for upgrade: UnitUpgrade in resource.get_eligible_upgrades():
		var new_resource: UnitResource = upgrade.unit.dupe()
		new_resource.skills = resource.skills
		new_resource.fatigue = resource.fatigue
		new_resource.curses = resource.curses
		var card = kf.create_card(upgrade.unit)
		var button = upgrade_button.instantiate()
		button.card = card
		button.add_child(card)
		button.pressed.connect(upgrade_unit.bind(chosen_button.card, card))
		upgrade_option_box.add_child(button)

func upgrade_unit(unit: Unit, upgrade: Unit):
	Bus.deck.remove_card(unit.card_resource)
	var new_card: UnitResource = upgrade.card_resource.dupe()
	Bus.deck.add_card(new_card)
	# parent is button
	upgrade_buttons.erase(unit.get_parent())
	unit.get_parent().queue_free()
	for button in upgrade_option_box.get_children():
		button.queue_free()

func reset_token(token: CardToken):
	$Bottom/UnitPanel.add_token(token)
