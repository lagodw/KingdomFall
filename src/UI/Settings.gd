extends CanvasLayer

@onready var master_slider = $Panel/Volume/MasterVolume
@onready var music_slider = $Panel/Volume/MusicVolume
@onready var sfx_slider = $Panel/Volume/SfxVolume
@onready var anim_slider = $Panel/Anim/AnimationSpeed

@onready var window_mode_button: OptionButton = $Panel/Window/WindowMode
@onready var resolution_button = $Panel/Window/Resolution

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

func _ready() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	window_mode_button.add_item("Fullscreen", DisplayServer.WINDOW_MODE_FULLSCREEN)
	window_mode_button.add_item("Windowed", DisplayServer.WINDOW_MODE_WINDOWED)
	window_mode_button.add_item("Maximized", DisplayServer.WINDOW_MODE_MAXIMIZED)
			
	# Initialize Resolution Options
	for res in RESOLUTIONS:
		resolution_button.add_item("%dx%d" % [res.x, res.y])
			
	window_mode_button.item_selected.connect(_on_window_mode_selected)
	resolution_button.item_selected.connect(_on_resolution_selected)
	
	anim_slider.value_changed.connect(_on_anim_changed)
	
	$Panel/Data.pressed.connect(update_data_collection)
	$Panel/Data.mouse_entered.connect(toggle_data_tooltip.bind(true))
	$Panel/Data.mouse_exited.connect(toggle_data_tooltip.bind(false))
	
	$Panel/Default.pressed.connect(restore_defaults)
	
	$Panel/Tutorial.pressed.connect(reset_tutorials)
	$Panel/HideTutorial.pressed.connect(hide_tutorials)
	
	$Panel/Close.pressed.connect(close)
	
	update_menu()

func update_menu():
	master_slider.value = Settings.settings.master_volume
	music_slider.value = Settings.settings.music_volume
	sfx_slider.value = Settings.settings.sfx_volume
	
	for i in window_mode_button.item_count:
		if window_mode_button.get_item_id(i) == Settings.settings.window_mode:
			window_mode_button.selected = i
			_on_window_mode_selected(i)
	
	var current_res = Settings.settings.resolution
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i] == current_res:
			resolution_button.selected = i
	anim_slider.value = Settings.settings.animation_speed
	_on_anim_changed(Settings.settings.animation_speed)
	
	$Panel/Data.button_pressed = Settings.settings.collect_data
	$Panel/HideTutorial.button_pressed = Settings.settings.hide_tutorial
			
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			close()
			
func close():
	Settings.save_settings()
	visible = false

func _on_master_changed(value: float) -> void:
	Settings.set_bus_volume("Master", value)

func _on_music_changed(value: float) -> void:
	Settings.set_bus_volume("Music", value)

func _on_sfx_changed(value: float) -> void:
	Settings.set_bus_volume("SFX", value)

func _on_window_mode_selected(index: int) -> void:
	var mode = window_mode_button.get_item_id(index)
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		$Panel/Window/Resolution.visible = true
		$Panel/Window/ResolutionTxt.visible = true
	else:
		$Panel/Window/Resolution.visible = false
		$Panel/Window/ResolutionTxt.visible = false
	Settings.settings.window_mode = mode
	Settings.apply_video_settings()

func _on_resolution_selected(index: int) -> void:
	var res = RESOLUTIONS[index]
	Settings.settings.resolution = res
	Settings.apply_video_settings()

func _on_anim_changed(value: float) -> void:
	# 0.5 on slider is baseline (=0.25s)
	kf.tween_time = 0.25 * (2 - value * 2)
	Settings.settings['animation_speed'] = value
	Settings.save_settings()

func toggle_data_tooltip(to_show: bool):
	$Panel/Data/DataTooltip.visible = to_show

func reset_tutorials():
	Settings.reset_tutorial_progress()
	Settings.settings.hide_tutorial = false
	update_menu()

func hide_tutorials():
	Settings.settings.hide_tutorial = $Panel/HideTutorial.button_pressed

func update_data_collection():
	Settings.settings.collect_data = $Panel/Data.button_pressed
	Settings.save_settings()

func restore_defaults():
	Settings.restore_default_settings()
	update_menu()
