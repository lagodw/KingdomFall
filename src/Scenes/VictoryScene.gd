extends Control

func _ready() -> void:
	$Control/MainMenu.pressed.connect(main_menu)
	
func main_menu():
	kf.load_scene("uid://bw1l202axfrki")
