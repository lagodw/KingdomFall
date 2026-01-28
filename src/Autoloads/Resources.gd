extends Node

signal resources_loaded

var initial_loaded: bool = false:
	set(val):
		initial_loaded = val
		if initial_loaded:
			emit_signal("resources_loaded")
var loading_requests = {} # { path: { "name": "card", "status": 0 } }

##### RESOURCE GROUPS #####
var card_resources: ResourceGroup
var buildings: ResourceGroup
var building_art: ResourceGroup
var enemies: ResourceGroup
var events: ResourceGroup
var curses: ResourceGroup
var blessings: ResourceGroup
var trainings: ResourceGroup
var boons: ResourceGroup
var consumes: ResourceGroup
var heroes: ResourceGroup
var cardart: ResourceGroup
var twists: ResourceGroup
var art: ResourceGroup
var burdens: ResourceGroup
var music: ResourceGroup
var sfx: ResourceGroup

##### CARDS #####
var card_label: PackedScene
var card: PackedScene
var unit: PackedScene
var spell: PackedScene
var item: PackedScene
var burden: PackedScene
var token: PackedScene
var equip_item: Effect
var consume: PackedScene

##### SCENES #####
var loading_scene: PackedScene
var tooltip: PackedScene

const RESOURCE_MAP = {
	###### resource groups #####
	"card_resources": "uid://bjdqhsddp1rxj",
	"buildings": "uid://6uwynbbqo5fm",
	"building_art": "uid://vioxwkbn4m3u",
	#"enemies": "uid://byhybgpfms51e",
	#"events": "uid://d4kf5b3g5m4gm",
	#"curses": "uid://drd4qppsgxfuh",
	#"blessings": "uid://7ajnftyruss2",
	#"trainings": "uid://6vwte3glk8nb",
	#"boons": "uid://bxkx5dxoask0p",
	#"consumes": "uid://cbmjhucbf6udl",
	#"heroes": "uid://bl4vd2euf10ko",
	#"cardart": "uid://cgflxsexqxciv",
	#"twists": "uid://cqka11cda5an6",
	#"art": "uid://bwleajy1yq78g",
	#"burdens": "uid://b0clwu8e66uyx",
	"music": "uid://bqbk7cku2sx87",
	"sfx": "uid://cngvxc5tp7l8r",
	#
	#"card_label": "uid://bfbt12injyh4a",
	"card": "uid://cd28vo6umqhig",
	"unit": "uid://cpnsgrt8hjbre",
	"spell": "uid://wkvlkif84nj3",
	"item": "uid://snfirkvlfltv",
	#"burden": "uid://bldvkx4hqe5yh",
	"token": "uid://64ksoqa1gi7w",
	#"equip_item": "uid://bvghc6u3bwmci",
	"consume": "uid://cs22w1p7m5pn3",

	"loading_scene": "uid://bfoyg5g1vd7mh",
	"tooltip": "uid://2gd3eej6fvla"
}

func _ready() -> void:
	set_process(false)
	
func load_resources_non_threaded():
	for resource_name in RESOURCE_MAP:
		set(resource_name, load(RESOURCE_MAP[resource_name]))
	await get_tree().process_frame
	initial_loaded = true
	
func load_resources_threaded():
	if loading_requests.size() > 0:
		push_error("Threaded resource loading is already active.")
		return

	loading_requests.clear()
	
	# Configure threading based on available cores
	#var processor_count = OS.get_processor_count()
	#var use_sub_threads = processor_count > 1
	var use_sub_threads = false
	
	# Prepare and start loading requests
	for resource_name in RESOURCE_MAP:
		var path = RESOURCE_MAP[resource_name]
		
		# Add a request entry
		loading_requests[path] = { 
			"name": resource_name, 
			"status": ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
		}

		# Start the threaded load request
		var error = ResourceLoader.load_threaded_request(path, "", use_sub_threads)
		if error != OK:
			push_error("Failed to start threaded load for resource: %s (Error: %d)" % [path, error])
			loading_requests.erase(path) # Remove failed resource
	
	if loading_requests.size() > 0:
		set_process(true)

func _process(_delta: float) -> void:
	if loading_requests.size() == 0:
		return

	# Array for progress update (passed by reference)
	var current_progress_array = [0.0] 

	# Iterate over a copy of keys to safely modify the dictionary if a load fails
	for path in loading_requests.keys().duplicate(): 
		var request = loading_requests[path]
		
		# Check current status and update granular progress
		var status = ResourceLoader.load_threaded_get_status(path, current_progress_array)
		request.status = status
		loading_requests[path] = request
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var loaded_resource = ResourceLoader.load_threaded_get(path)
			set(request.name, loaded_resource)
			loading_requests.erase(path)
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Threaded load failed for resource: %s. Resource will be missing." % path)
			loading_requests.erase(path)
	
	if loading_requests.size() == 0:
		initial_loaded = true
		set_process(false)
		load_resource_groups()

func load_resource_groups() -> void:
	card_resources.load_paths()
	#enemies.load_paths()
	#events.load_paths()
	#curses.load_paths()
	#blessings.load_paths()
	#trainings.load_paths()
	#cardart.load_paths()
	#twists.load_paths()
	#boons.load_paths()
	#consumes.load_paths()
	#heroes.load_paths()
