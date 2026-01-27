extends CanvasLayer

@onready var timer: Timer = $AudioTimer
var audio_cooldown: bool = false

func _ready() -> void:
	$Control/Panel/VBoxContainer/MainMenu.pressed.connect(main_menu)
	$Control/Panel/VBoxContainer/Quit.pressed.connect(quit)
	
	for button: Button in $Control/Panel/VBoxContainer.get_children():
		button.mouse_entered.connect(play_audio)
	$AudioTimer.timeout.connect(reset_audio_cd)
	
func appear():
	visible = true
	get_tree().paused = true
	
func main_menu():
	Bus.map = null
	Bus.player = null
	get_tree().paused = false
	Bus.reset_vars()
	kf.load_scene("uid://dyai8rsp8py54")
	
# TODO: confirm no save
func quit():
	get_tree().quit()

func play_audio():
	if audio_cooldown:
		return
	audio_cooldown = true
	timer.wait_time = 0.25
	timer.start()
	Audio.play_sfx("CardFlick")
	
func reset_audio_cd():
	audio_cooldown = false
