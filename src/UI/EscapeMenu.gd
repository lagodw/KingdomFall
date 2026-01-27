extends CanvasLayer

@onready var timer: Timer = $AudioTimer
var audio_cooldown: bool = false

func _ready() -> void:
	$Control/Panel/VBoxContainer/Resume.pressed.connect(resume)
	$Control/Panel/VBoxContainer/Save.pressed.connect(save)
	$Control/Panel/VBoxContainer/MainMenu.pressed.connect(main_menu)
	$Control/Panel/VBoxContainer/Quit.pressed.connect(quit)
	$Control/Panel/VBoxContainer/Settings.pressed.connect(settings)
	
	for button: Button in $Control/Panel/VBoxContainer.get_children():
		button.mouse_entered.connect(play_audio)
	$AudioTimer.timeout.connect(reset_audio_cd)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			visible = not visible
			get_tree().paused = not get_tree().paused
		
func resume():
	get_tree().paused = false
	visible = false
		
func save():
	kf.save_game()
	get_tree().paused = false
	kf.load_scene("uid://dyai8rsp8py54")
	
func main_menu():
	Bus.map = null
	Bus.player = null
	Bus.reset_vars()
	get_tree().paused = false
	close_tutorials()
	Bus.reset_vars()
	kf.load_scene("uid://dyai8rsp8py54")
	
func settings():
	$Settings.show()
	
# TODO: confirm no save
func quit():
	get_tree().quit()

func close_tutorials():
	pass
	#for child in get_tree().root.get_children():
		#if child is TutorialHint:
			#child.queue_free()

func play_audio():
	if audio_cooldown:
		return
	audio_cooldown = true
	timer.wait_time = 0.25
	timer.start()
	Audio.play_sfx("CardFlick")
	
func reset_audio_cd():
	audio_cooldown = false
