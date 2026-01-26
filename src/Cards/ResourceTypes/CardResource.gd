class_name CardResource
extends Resource

@export var card_name: String
@export_enum("Unit", "Spell", "Item", "Burden", "Face", "Consume") var card_type: String
@export var activation: int = 1
@export var tags: Array[kf.Tag] = []
@export var text: String = ""
@export var effects: Array[Effect] = []
@export var custom_startup_script: Script
@export var card_art_path: String

func _init():
	resource_local_to_scene = true

func dupe() -> Resource:
	var new = self.duplicate(true)
	var new_effects: Array[Effect] = []
	for effect in effects:
		new_effects.append(effect.dupe())
	new.effects = new_effects
	return(new)
