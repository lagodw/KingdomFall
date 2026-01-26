extends Node

# use two players to facilitate crossfading
var music_players: Array[AudioStreamPlayer] = []
var active_player_index: int = 0
var fade_tween: Tween

#@onready var music_player = AudioStreamPlayer.new()
@onready var sfx_pool = Node.new()

func _ready() -> void:
# 1. Initialize two music players (A and B)
	for i in 2:
		var p = AudioStreamPlayer.new()
		p.bus = "Music"
		add_child(p)
		music_players.append(p)
		
	## Setup Music Player
	#add_child(music_player)
	#music_player.bus = "Music"
	
	# Setup SFX Pool container
	sfx_pool.name = "SFXPool"
	add_child(sfx_pool)
	
	# Connect to existing SignalBus signals
	Bus.new_scene_loaded.connect(_on_new_scene_loaded)

func _on_new_scene_loaded() -> void:
	if Bus.map:
		var event_data = Bus.map.current_location
		var event_scene_path = event_data.scene_path
		
		# 1. Resolve UID string to a standard 'res://' path for comparison
		if event_scene_path.begins_with("uid://"):
			# Convert the "uid://..." string to an integer ID, then to a path
			var uid_id = ResourceUID.text_to_id(event_scene_path)
			event_scene_path = ResourceUID.get_id_path(uid_id)
		
		# 2. Compare the resolved path with the current scene file path
		if get_tree().current_scene.scene_file_path == event_scene_path:
			# allow some events to skip music to play within script (combat)
			if event_data.music == "":
				return
			play_music(event_data.music)

func play_music(track_name: String, fade_time: float = 1.0) -> void:
	var stream = R.music.get_matching_resource(["%s.**"%track_name])[0]
	
	var current_player = music_players[active_player_index]
	var next_player = music_players[(active_player_index + 1) % 2]
	
	# Don't restart if the same track is already playing
	if current_player.stream == stream and current_player.playing:
		return
		
	# Update index for the new active player
	active_player_index = (active_player_index + 1) % 2
	
	# Prepare the next player
	next_player.stream = stream
	next_player.volume_db = -80 # Start silent
	next_player.play()
	
	# 2. Parallel Crossfade Logic
	if fade_tween:
		fade_tween.kill() # Stop any ongoing transition to prevent volume conflicts
	
	fade_tween = create_tween().set_parallel(true)
	
	# Fade out the current player and fade in the next one simultaneously
	# Using TRANS_SINE makes the volume change feel more natural than a linear fade
	fade_tween.tween_property(current_player, "volume_db", -80, fade_time).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_property(next_player, "volume_db", 0, fade_time).set_trans(Tween.TRANS_SINE)
	
	# Stop the old player once the fade is complete
	fade_tween.chain().tween_callback(current_player.stop)

func play_sfx(sfx_name: String, pitch_range: float = 0.1) -> void:
	var stream = R.sfx.get_matching_resource(["%s.**"%sfx_name])[0]
	if not stream:
		return

	# Use an available player from a pool or create a temporary one
	var player = AudioStreamPlayer.new()
	sfx_pool.add_child(player)
	player.stream = stream
	player.bus = "SFX"
	
	# Add slight pitch variation for more natural sound
	player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	
	player.play()
	player.finished.connect(player.queue_free)
