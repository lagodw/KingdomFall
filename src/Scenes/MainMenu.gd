extends Control

func _ready() -> void:
	R.resources_loaded.connect(start_game)
	R.load_resources_non_threaded()
	
func start_game():
	Bus.player = Player.new()
	#var deck = Bus.player.deck.dupe()
	Bus.deck = Bus.player.deck
	#kf.load_scene("uid://dvld0lyuo33oq")
	kf.load_scene("uid://djtcf3x2wg721")
