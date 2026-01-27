extends Node

var card_art: Dictionary = {}
var animations: Dictionary = {}

var steam_id: int = 0
var steam_username: String = ""
var steam_api: Object = null # Dynamic reference to the Steam singleton

var tutorial_progress: Dictionary = {}

var settings: Dictionary = {}

var default_settings: Dictionary = {
	"hide_tutorial": false,
	"master_volume": 1.0,
	"music_volume": 0.5,
	"sfx_volume": 0.5,
	"window_mode": DisplayServer.WINDOW_MODE_FULLSCREEN,
	"resolution": Vector2i(1280, 720),
	"animation_speed": 0.5,
	"collect_data": true,
}

const BUS_OFFSETS = {
	"Master": 0.0,
	"Music": -15.0, 
	"SFX": 0.0
}

func _ready() -> void:
	# Safely fetch the Steam singleton if it exists
	if Engine.has_singleton("Steam"):
		steam_api = Engine.get_singleton("Steam")
	
	if steam_api:
		initialize_steam()
		
	if OS.has_feature("web"):
		default_settings.window_mode = DisplayServer.WINDOW_MODE_MAXIMIZED
	settings = default_settings.duplicate(true)
		
	load_settings()
	apply_volumes()
	apply_video_settings()
	
func restore_default_settings() -> void:
	settings = default_settings.duplicate(true)
	apply_all_settings()
	save_settings()
	
func initialize_steam() -> void:
	OS.set_environment("SteamAppId", str(2874650))
	OS.set_environment("SteamGameId", str(2874650))
	
	var initialize_response: Dictionary = steam_api.steamInitEx(true)
	if initialize_response['status'] > 0:
		push_warning("Failed to initialize Steam. %s" % initialize_response.verbal)
	else:
		steam_id = steam_api.getSteamID()
		steam_username = steam_api.getPersonaName()
	
func load_settings() -> void:
	find_dict("settings", "UserSettings/Settings")
	find_dict("card_art", "UserSettings/CardArt")
	find_dict("animations", "UserSettings/Animations")
	find_dict("tutorial_progress", "UserSettings/Tutorial")
	
func save_settings() -> void:
	save_dict(settings, "UserSettings/Settings")
	save_dict(card_art, "UserSettings/CardArt")
	save_dict(animations, "UserSettings/Animations")
	save_dict(tutorial_progress, "UserSettings/Tutorial")

func get_dict_steam(file_name: String):
	if not steam_api:
		return {}
		
	var size = steam_api.getFileSize(file_name)
	var data = steam_api.fileRead(file_name, size)
	var pba : PackedByteArray = data.buf
	return(str_to_var(pba.get_string_from_utf8()))

func get_dict(file_name: String):
	if not FileAccess.file_exists("user://" + file_name):
		return({})
	var file = FileAccess.open("user://" + file_name, FileAccess.READ)
	return(str_to_var(file.get_as_text()))
	
func save_dict(dict, path: String) -> void:
	var string_data = var_to_str(dict)
	
	# Only attempt Steam Cloud save if the API is available
	if steam_api:
		steam_api.fileWriteAsync(path, string_data.to_utf8_buffer())
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("UserSettings"):
		dir.make_dir("UserSettings")
		
	var file = FileAccess.open("user://%s"%path, FileAccess.WRITE)
	file.store_string(string_data)

## checks if file exists on Steam, if not check for local file
func find_dict(dict_string: String, path: String) -> void:
	var loaded_data
	
	# Check steam_api instead of OS feature for better reliability
	if steam_api:
		if steam_api.fileExists(path):
			loaded_data = get_dict_steam(path)
			
	if not loaded_data:
		if FileAccess.file_exists("user://" + path):
			loaded_data = get_dict(path)
	
	if loaded_data != null:
		var current_val = get(dict_string)
		if current_val is Dictionary:
			# true ensures that if a key exists in both, the loaded value wins.
			current_val.merge(loaded_data, true)
		else:
			set(dict_string, loaded_data)
			
func reset_tutorial_progress() -> void:
	settings.hide_tutorial = false
	tutorial_progress = {}

func apply_all_settings() -> void:
	apply_volumes()
	apply_video_settings()
	
func apply_volumes() -> void:
	set_bus_volume("Master", settings.master_volume)
	set_bus_volume("Music", settings.music_volume)
	set_bus_volume("SFX", settings.sfx_volume)

func set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var base_db = linear_to_db(linear_value)
		var offset = BUS_OFFSETS.get(bus_name, 0.0)
		var final_db = base_db + offset
		AudioServer.set_bus_volume_db(bus_index, final_db)
		settings[bus_name.to_lower() + "_volume"] = linear_value

func apply_video_settings() -> void:
	DisplayServer.window_set_mode(settings.window_mode)
	
	if settings.window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(settings.resolution)
		var screen_id = DisplayServer.window_get_current_screen()
		var screen_size = DisplayServer.screen_get_size(screen_id)
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position(screen_size / 2 - window_size / 2)
	save_settings()
