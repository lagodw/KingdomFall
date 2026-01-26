extends Node

var card_art: Dictionary = {}
var animations: Dictionary = {}
var portrait: String

var steam_id: int = 0
var steam_username: String = ""

var tutorial_progress: Dictionary = {}

var settings: Dictionary = {
	"hide_tutorial": false
}

func _ready() -> void:
	initialize_steam()
	load_settings()
	if portrait == null:
		get_default_portrait()
	save_settings()
	
func initialize_steam() -> void:
	OS.set_environment("SteamAppId", str(2874650))
	OS.set_environment("SteamGameId", str(2874650))
	var initialize_response: Dictionary = Steam.steamInitEx(true)
	if initialize_response['status'] > 0:
		push_warning("Failed to initialize Steam. %s" % initialize_response.verbal)
	else:
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()
	
func get_default_portrait() -> void:
	portrait = "King.png"
	
func load_settings() -> void:
	find_dict("settings", "UserSettings/Settings")
	find_dict("card_art", "UserSettings/CardArt")
	find_dict("animations", "UserSettings/Animations")
	find_dict("portrait", "UserSettings/Portrait")
	find_dict("tutorial_progress", "UserSettings/Tutorial")
	
func save_settings() -> void:
	save_dict(settings, "UserSettings/Settings")
	save_dict(card_art, "UserSettings/CardArt")
	save_dict(animations, "UserSettings/Animations")
	save_dict(portrait, "UserSettings/Portrait")
	save_dict(tutorial_progress, "UserSettings/Tutorial")

func get_dict_steam(file_name: String):
	var size = Steam.getFileSize(file_name)
	var data = Steam.fileRead(file_name, size)
	var pba : PackedByteArray = data.buf
	var dict = JSON.parse_string(pba.get_string_from_utf8())
	return(dict)

func get_dict(file_name: String):
	if not FileAccess.file_exists("user://" + file_name):
		return({})
	var file = FileAccess.open("user://" + file_name, FileAccess.READ)
	var pba : PackedByteArray = file.get_buffer(file.get_length())
	var dict = JSON.parse_string(pba.get_string_from_utf8())
	return(dict)
	
func save_dict(dict, path: String) -> void:
	var string_data = JSON.stringify(dict)
	Steam.fileWriteAsync(path, string_data.to_utf8_buffer())
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("UserSettings"):
		dir.make_dir("UserSettings")
	var file = FileAccess.open("user://%s"%path, FileAccess.WRITE)
	file.store_buffer(string_data.to_utf8_buffer())

## checks if file exists on Steam, if not check for local file
func find_dict(dict_string: String, path: String) -> void:
	if Steam.fileExists(path):
		set(dict_string, get_dict_steam(path))
	elif FileAccess.file_exists("user://" + path):
		set(dict_string, get_dict(path))

func reset_tutorial_progress() -> void:
	tutorial_progress = {}
