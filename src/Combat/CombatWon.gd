extends Control

func _ready() -> void:
	#add_card_choices()
	$Confirm.pressed.connect(confirm)

func add_card_choices():
	var choices: Array = R.card_resources.get_matching_resource([])
	for i in 3:
		var choice = choices.pick_random()
		var card = kf.create_card(choice)
		$Choices.add_child(card)
	
func confirm():
	get_tree().paused = false
	kf.load_scene("uid://djtcf3x2wg721")
