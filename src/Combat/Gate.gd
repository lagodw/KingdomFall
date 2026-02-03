class_name Gate
extends CardToken

func _ready() -> void:
	card_resource = Bus.player.gate
	super._ready()
	Bus.gate = self

func set_art(_override: String = ""):
	pass
	
func update_bg_color():
	pass
	
func discard():
	Bus.Board.game_over()
