class_name Curse
extends Resource

@export var icon_uid: String = "uid://ban02t7qxy1nf"
## -1 means permanent
@export var combats_left: int = -1
# could make this subclass but ATM not enough difference
@export var is_blessing: bool = false
var owner_card: UnitResource

## don't allow curses that wouldn't do anything
func check_eligibility(card: UnitResource) -> bool:
	for stat in ["damage", "shield", 
		"health", "activation"]:
		# stat value after including this and other curses
		var after_value: int = card.get(stat) + get(stat)
		for curse in card.curses:
			# don't count blessings since they're temporary
			# not sure if they should be though
			if not curse.is_blessing:
				after_value += curse.get(stat)
		var lowest_allowed: int = 0
		if stat in ["health", "activation"]:
			lowest_allowed = 1
		if after_value < lowest_allowed:
			return(false)
	return(true)
	
func assign(card: UnitResource) -> void:
	card.curses.append(self)
	owner_card = card
	if not Bus.turn_starting.is_connected(increment_turns):
		Bus.turn_starting.connect(increment_turns)
	
func increment_turns() -> void:
	combats_left -= 1
	if combats_left == 0:
		owner_card.curses.erase(self)
		
func create_effect() -> Effect:
	var effect = load("uid://oa67icmovt8g").dupe()
	for stat in ["damage", "health", "shield", "activation"]:
		var val = EffectValue.new()
		val.number = get(stat)
		effect.set("buff_%s"%stat, val)
	return(effect)
		
func register(token: CardToken) -> void:
	var effect = create_effect()
	effect.calling_card = token
	effect.trigger_card = token
	effect.apply_effect({})
	ee.apply_effects()
