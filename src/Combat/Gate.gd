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

func _get_drag_data(_at_position: Vector2) -> Variant:
	return(null)
	
func _on_mouse_enter():
	pass
