extends Control

func _ready() -> void:
	R.resources_loaded.connect(start_game)
	R.load_resources_non_threaded()
	
func start_game():
	Bus.player = Player.new()
	Bus.deck = Bus.player.deck.dupe()
	var town: TownResource = load("uid://bmwj3jl3o8tm4").dupe()
	for building in town.buildings:
		building.current_construction = building.construction_cost
	Bus.player.town = town
	#kf.load_scene("uid://dvld0lyuo33oq")
	kf.load_scene("uid://djtcf3x2wg721")
