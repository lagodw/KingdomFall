class_name Event
extends Resource

@export var icon_path: String = "res://assets/Map/EventMarkers/Campfire.png"
@export var scene_path: String
@export var event_name: String
@export var signpost_description: String
@export var num_reward_options: int = 0
@export var num_reward_choices: int = 0
@export var music: String = "Hearthsong at the Oakwood Inn"

@export_category("Internal")
@export var spot: Vector2
@export var enemy: EnemyResource
@export var recruit_options: Array[UnitResource]
@export var spell_options: Array[SpellResource]
@export var item_options: Array[ItemResource]
@export var building_options: Array[BuildingResource]
@export var gold_amt: int
@export var wood_amt: int
@export var stone_amt: int
## true is good outcome
@export var bool_outcome: bool

func generate_unit_options(num_options: int):
	for i in num_options:
		var options = R.card_resources.get_matching_resource(
				["Units/**"])
		var option = options.pick_random()
		recruit_options.append(option.dupe())
	
func generate_spell_options(num_options: int):
	# don't duplicate until after to check for repeats
	var tmp_options: Array[SpellResource] = []
	for i in num_options:
		var options = R.card_resources.get_matching_resource(
				["Spells/**"])
		for option in tmp_options:
			if options.has(option):
				options.erase(option)
		if options.size() == 0:
			continue
		var option = options.pick_random()
		tmp_options.append(option)
	for option in tmp_options:
		spell_options.append(option.dupe())
	
func generate_item_options(num_options: int):
	# don't duplicate until after to check for repeats
	var tmp_options: Array[ItemResource] = []
	for i in num_options:
		var options = R.card_resources.get_matching_resource(
				["Items/**"])
		for option in tmp_options:
			if options.has(option):
				options.erase(option)
		if options.size() == 0:
			continue
		var option = options.pick_random()
		tmp_options.append(option)
	for option in tmp_options:
		item_options.append(option.dupe())
		
func setup() -> void:
	var callable = Callable.create(self, "setup_%s"%event_name)
	callable.call()
	
func setup_Combat():
	if not enemy:
		var tier: float = spot.x + abs(spot.y) / 10
		var enemies = R.enemies.get_matching_resource(["Tier%s/**.tres"%tier])
		enemy = enemies.pick_random().duplicate(true)
	enemy.add_cards()
	gold_amt = randi_range(12, 20)
	generate_unit_options(3)
	
func setup_Recruit():
	generate_unit_options(num_reward_options)
