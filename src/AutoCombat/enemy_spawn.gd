@tool
class_name EnemySpawn
extends Node2D

@export var unit_resource: Resource:
	set(val):
		unit_resource = val
		queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		# Draw a threatening crimson ring for the enemy locators
		draw_circle(Vector2.ZERO, 50.0, Color(1.0, 0.2, 0.2, 0.8))
		draw_circle(Vector2.ZERO, 10.0, Color(0.8, 0.0, 0.0, 0.9))
		
		# Overlay the name of the unit if assigned
		if unit_resource and "card_name" in unit_resource:
			var font = ThemeDB.fallback_font
			var font_size = 14
			draw_string(font, Vector2(-40, -20), unit_resource.card_name, HORIZONTAL_ALIGNMENT_CENTER, 80, font_size, Color.WHITE)
