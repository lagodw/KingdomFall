class_name Gate
extends CardToken

func _ready() -> void:
	base_health = 50
	max_health = 50
	current_health = 50
	remaining_life = 50
	Bus.gate = self
#
#func update_damage_preview() -> void:
	#var incoming_damage = current_health - remaining_life
	#var health_damage = incoming_damage
	#%HealthPreviewText.text = "-%s"%health_damage
	#%HealthPreview.visible = (health_damage > 0 and remaining_life > 0)

func discard():
	Bus.Board.game_over()
