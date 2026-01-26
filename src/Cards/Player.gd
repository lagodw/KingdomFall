class_name Player
extends UnitResource

@export var deck: Deck = load("uid://daukdeewyd6ke")
@export var gold: int = 25
@export var current_health: int = 80:
	set(val):
		current_health = clamp(val, 0, health)
		if Bus.ui:
			Bus.ui.set_health_text()
@export var max_mana: int = 5
@export var spell_power: int = 0
#@export var boons: Array[Boon]

## hopefully temporary workaround
## https://github.com/godotengine/godot/issues/74918
func dupe() -> Resource:
	var duped = self.duplicate(true)
	duped.deck = deck.dupe()
	# current_health is getting set to 1 for some reason
	duped.current_health = health
	#var new_boons: Array[Boon] = []
	#for boon in boons:
		#new_boons.append(boon.dupe())
	#duped.boons = new_boons
	var new_effects: Array[Effect] = []
	for effect in effects:
		new_effects.append(effect.dupe())
	duped.effects = new_effects
	return(duped)
