extends Control

@onready var progress_bar = $ProgressBar

var target_scene_path: String = ""

# 1. Initialization: Called by the SceneTransition Singleton to begin the load
func start_loading(path: String) -> void:
	target_scene_path = path
	# Request the resource to be loaded in a separate thread
	var error = ResourceLoader.load_threaded_request(target_scene_path, "", true)
	if error != OK:
		push_error("Failed to start threaded load for path: ", target_scene_path)
		# Handle immediate cleanup in case of an error
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/FallbackScene.tscn") # Change to a safe, default scene
		queue_free()
		return
	
	# Start updating the screen
	set_process(true)
	progress_bar.value = 0
	
# --- Core Logic ---

func _process(_delta):
	# Poll the status of the threaded loading process
	var status = ResourceLoader.load_threaded_get_status(target_scene_path)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Update the progress bar
			var progress_array = []
			ResourceLoader.load_threaded_get_status(target_scene_path, progress_array)
			if progress_array.size() > 0:
				progress_bar.value = progress_array[0] * 100.0
		
		ResourceLoader.THREAD_LOAD_LOADED:
			# Loading is complete, finalize the scene switch
			set_process(false)
			var new_scene_resource = ResourceLoader.load_threaded_get(target_scene_path)
			
			if new_scene_resource is PackedScene:
				# Call the dedicated transition function on the Singleton
				kf.finish_transition(new_scene_resource)
			else:
				push_error("Loaded resource is not a PackedScene: ", target_scene_path)
				
			# Finally, remove the loading screen
			queue_free()

		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			push_error("Threaded scene loading failed for path: ", target_scene_path)
			# Fallback to a safe scene on failure
			#get_tree().call_deferred("change_scene_to_file", "res://Scenes/FallbackScene.tscn")
			queue_free()
