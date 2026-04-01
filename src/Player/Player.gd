class_name Player
extends UnitResource

@export var deck: Deck = load("uid://daukdeewyd6ke")
@export var day_deck: Array[CardResource]
@export var charters: Dictionary[String, UnitResource]
@export var manuscripts: Dictionary[String, ConsumeResource]
@export var town: TownResource = load("uid://bmwj3jl3o8tm4")
@export var gate: UnitResource = load("uid://cnr0bb4lxr83a")
@export var gold: int = 0
@export var wood: int = 10
@export var stone: int = 10
@export var food: int = 20
@export var current_health: int = 80:
	set(val):
		current_health = clamp(val, 0, health)
		if Bus.ui:
			Bus.ui.set_health_text()
@export var max_mana: int = 10
@export var spell_power: int = 0
#@export var boons: Array[Boon]

## hopefully temporary workaround
## https://github.com/godotengine/godot/issues/74918
func dupe() -> Player:
	var duped: Player = self.duplicate(true)
	duped.deck = deck.dupe()
	duped.town = town.dupe()
	duped.gate = gate.dupe()
	var duped_charters: Dictionary[String, UnitResource]
	for charter in charters.keys():
		duped_charters[charter] = charters[charter].dupe()
	duped.charters = duped_charters
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

func add_charter(card: UnitResource):
	charters[card.card_name] = card
