extends Control

func _ready() -> void:
	if not R.initial_loaded:
		R.resources_loaded.connect(start_game)
		R.load_resources_non_threaded()
	else:
		await get_tree().process_frame
		start_game()
	$Menu/New.pressed.connect(start_game)
	$Menu/Settings.pressed.connect(show_settings)
	$Menu/Quit.pressed.connect(quit)
	
func start_game():
	Bus.player = Player.new()
	Bus.deck = Bus.player.deck.dupe()
	var town: TownResource = load("uid://bmwj3jl3o8tm4").dupe()
	Bus.player.town = town
	#kf.load_scene("uid://dvld0lyuo33oq")
	kf.load_scene("uid://djtcf3x2wg721")

func show_settings():
	$Settings.visible = true

func quit():
	get_tree().quit()
