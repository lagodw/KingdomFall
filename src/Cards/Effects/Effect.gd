@tool
class_name Effect
extends Resource


## functions will be pulled automatically
@export var function_script: Script = load("uid://bx1wbh0860dbc"):
	set(script):
		function_script = script
		notify_property_list_changed()
## callable needs instance instead of script
var script_instance: Resource
## will be assigned when played
## trigger card could also be combat node
var trigger_card: Control
var calling_card: Control
var function: String:
	set(the_function):
		function = the_function
		notify_property_list_changed()
## trigger is what causes the effect to be registered
var trigger_signal: String:
	set(val):
		trigger_signal = val
		notify_property_list_changed()
var subject: String = "target":
	set(val):
		subject = val
		notify_property_list_changed()
var unit_lookup: UnitLookup
## calling conditions will be checked when effect is registered
## and rechecked at every application
var conditions_calling: EffectConditionCalling = EffectConditionCalling.new()
var conditions_trigger: EffectConditionSubject = EffectConditionSubject.new()
var conditions_subject: EffectConditionSubject = EffectConditionSubject.new()
var if_calling_card: EffectIf = EffectIf.new()
var if_subject: EffectIf = EffectIf.new()
# TODO: could this be automatically assigned based on function or subject?
var animation: String = "none"
var persistent_effect: bool

var num_slots: int = 0
var temporary_slot: bool = true
var tag: kf.Tag = kf.Tag.Creature
var turns: int = 0
var damage_amt: EffectValue = EffectValue.new()
var blocked_by_shield: bool = true
var buff_health: EffectValue = EffectValue.new()
var buff_damage: EffectValue = EffectValue.new()
var buff_shield: EffectValue = EffectValue.new()
var buff_activation: EffectValue = EffectValue.new()
var affect_max: bool = true
#var delayed_effects: DelayedEffect
var act_disabled: bool = true
var can_act: bool = true
var set_health: EffectValue = EffectValue.new()
var set_damage: EffectValue = EffectValue.new()
var set_shield: EffectValue = EffectValue.new()
var set_activation: EffectValue = EffectValue.new()
var new_art: String
var debuff: String
var debuff_amount: EffectValue = EffectValue.new()
var bus_var: String
var bus_var_change: EffectValue = EffectValue.new()
var card_name: String
var card_owner: String = "Allied"
var card_location: String = "Deck"
var perm_damage: EffectValue = EffectValue.new()
var perm_health: EffectValue = EffectValue.new()
var perm_shield: EffectValue = EffectValue.new()
var perm_activation: EffectValue = EffectValue.new()
var target_type: String = "Unit"
var cost_change: EffectValue = EffectValue.new()
var max_activation_change: EffectValue = EffectValue.new()
var unit_upgrade: UnitUpgrade = UnitUpgrade.new()

var host_card: CardToken
var effect_dict: Dictionary = {}

func connect_signal(call_card: Control = null):
	script_instance = function_script.new()
	if call_card:
		calling_card = call_card
	var on_signal = Callable.create(self, "on_%s"%trigger_signal)
	if not ee.is_connected(trigger_signal, on_signal):
		ee.connect(trigger_signal, on_signal)
	
func apply_effect(new_dict: Dictionary):
	#printt('starting effect', function)
	# Ensure the script instance exists before trying to use it.
	# This handles cases where apply_effect is called manually (like in Curse.gd)
	if not script_instance:
		script_instance = function_script.new()
	# not sure if this is needed. Causes error with boons
	#if calling_card.disabled or trigger_card.disabled:
		#return
	# instant boons won't have calling or trigger
	if calling_card and trigger_card:
		if not ee.check_conditions_calling(calling_card, trigger_card, conditions_calling):
			return
		if not ee.check_conditions_subject(trigger_card, calling_card, conditions_trigger):
			return
	
	effect_dict = new_dict
	
	var getsubject = EffectSubjects.new()
	var methods = getsubject.get_script().get_script_method_list()
	var subject_args: Array[String]
	for method in methods:
		if method["name"] == subject:
			for arg in method["args"]:
				subject_args.append(arg["name"])
	var args: Array = []
	for arg in subject_args:
		if arg in effect_dict:
			args.append(effect_dict[arg])
		else:
			args.append(get(arg))
	var subject_callable = Callable.create(getsubject, subject)
	var subjects = subject_callable.callv(args)
	var filtered_subjects: Array[Control] = []
	for a_subject in subjects:
		if ee.check_conditions_subject(a_subject, calling_card, conditions_subject):
			filtered_subjects.append(a_subject)
	effect_dict['subjects'] = filtered_subjects
	#print("effect passed conditions: %s for function %s with args %s"%[
			#calling_card.card_name, function, effect_dict])
	
	var func_methods = function_script.get_script_method_list()
	var func_args: Array[String]
	for method in func_methods:
		if method["name"] == function:
			for arg in method["args"]:
				func_args.append(arg["name"])
	var actual_args: Array = []
	for arg in func_args:
		if arg in effect_dict:
			actual_args.append(effect_dict[arg])
		else:
			actual_args.append(get(arg))
	
	#printt("applying effect, calling:", calling_card, "function: ", 
			#function, "args: ", actual_args)
	#print(effect_dict)
	var func_callable = Callable.create(script_instance, function)
	func_callable.callv(actual_args)
	
	# Post effect actions
	if trigger_signal == "target" and calling_card.card_type == "Unit":
		calling_card.set_act(false)
	# allow spells to have secondary effect aside from target (i.e. sacrifice)
	elif trigger_signal == "target" and calling_card.card_type == "Spell":
		ee.emit_signal("cast", calling_card, calling_card.mana_cost)
		
	if animation != "none":
		match animation:
			'PlayerEffects', 'EnemyEffects':
				var dest = Bus.get(animation)
				calling_card.board_effect(dest)
			'cast':
				calling_card.set_scale(Vector2(1, 1))
				calling_card.discard()
	
	if persistent_effect and not ee.effect_list.has(self):
		ee.effect_list.append(self)
		ee.apply_effects()
	
func on_target(triggering_card: Control, the_target: Control):
	trigger_card = triggering_card
	apply_effect({"the_target": the_target})
func on_cast(triggering_card: Control, mana_cost: int):
	trigger_card = triggering_card
	apply_effect({
		"mana_cost": mana_cost
	})
func on_draw(triggering_card: Control):
	trigger_card = triggering_card
	apply_effect({})
func on_discard(triggering_card: Control):
	trigger_card = triggering_card
	apply_effect({})
func on_attach(triggering_card: Control, card_host: CardToken):
	trigger_card = triggering_card
	var dict = {
		"host": card_host
	}
	apply_effect(dict)
func on_activate(triggering_card: Control):
	trigger_card = triggering_card
	apply_effect({})
func on_move(triggering_card: Control):
	trigger_card = triggering_card
	apply_effect({})
func on_start_turn(turn_num: int):
	apply_effect({
		"turn_num": turn_num
	})
func on_combat_start():
	trigger_card = Bus.Board
	apply_effect({})
func on_combat_end():
	trigger_card = Bus.Board
	apply_effect({})
func on_damage_taken(triggering_card: Control, damage_taken: int):
	trigger_card = triggering_card
	var dict = {
		"damage_taken": damage_taken
	}
	apply_effect(dict)
func on_unit_attacked(triggering_card: Control, defender: Control):
	trigger_card = triggering_card
	var dict = {
		"defender": defender
	}
	apply_effect(dict)
func on_unit_first_attack(attacking_card: CardToken):
	trigger_card = attacking_card
	apply_effect({})
func on_unit_defended(triggering_card: Control, attacker: Control):
	trigger_card = triggering_card
	var dict = {
		"attacker": attacker
	}
	apply_effect(dict)
func on_killing_blow(triggering_card: Control, killed_card: Control):
	trigger_card = triggering_card
	var dict = {
		"killed_card": killed_card
	}
	apply_effect(dict)
func on_unit_killed(killed_card: CardToken, killing_card: Card):
	trigger_card = killed_card
	var dict = {
		"killing_card": killing_card
	}
	apply_effect(dict)
func on_play(triggering_card: Control):
	trigger_card = triggering_card
	apply_effect({})
func on_consume_used(consume: Control):
	trigger_card = consume
	apply_effect({})
func on_card_added_to_deck(card: CardResource):
	var dict = {
		"card": card
	}
	apply_effect(dict)
func on_end_day():
	apply_effect({})
	
func _get_property_list() -> Array:
	#print(get_script().get_script_property_list())
	var list := []
	if Engine.is_editor_hint():
		if not function_script:
			return(list)

		var props: Dictionary
		for property in get_script().get_script_property_list():
			props[property.name] = property.hint_string

		var func_methods = function_script.get_script_method_list()
		var functions: Array[String] = []
		for method in func_methods:
			functions.append(method["name"])
		var function_string = ",".join(functions)
		list.append(string_enum_hint("function", function_string))
		
		var signals: Array[String] = []
		for signal_dict in ee.get_signal_list():
			if signal_dict["name"] == "BREAK_HERE":
				break
			signals.append(signal_dict["name"])
		var signal_string = ",".join(signals)
		list.append(string_enum_hint("trigger_signal", signal_string))
		if trigger_signal == "target":
			list.append(string_enum_hint("target_type", "Unit,CardLabel,Rank,File"))
		
		var subjects = EffectSubjects.new()
		var subject_methods = subjects.get_script().get_script_method_list()
		var possible_subjects: Array[String] = []
		for method in subject_methods:
			possible_subjects.append(method["name"])
		var subject_string = ",".join(possible_subjects)
		list.append(string_enum_hint("subject", subject_string))
		if subject == "lookup":
			list.append(resource_hint("unit_lookup", "UnitLookup"))
		
		list.append(resource_hint("conditions_calling", "EffectConditionCalling"))
		list.append(resource_hint("conditions_trigger", "EffectConditionSubject"))
		list.append(resource_hint("conditions_subject", "EffectConditionSubject"))
		list.append(resource_hint("if_calling_card", "EffectIf"))
		list.append(resource_hint("if_subject", "EffectIf"))
		
		list.append(string_enum_hint("animation", "none,cast,PlayerEffects,EnemyEffects"))
		
		match function:
			'add_activation_slots':
				list.append(type_hint("num_slots", TYPE_INT))
				list.append(type_hint("temporary_slot", TYPE_BOOL))
				list.append(type_hint("persistent_effect", TYPE_BOOL))
				subject = "ActivationBoxes"
			'add_card':
				list.append(type_hint("card_name", TYPE_STRING))
				list.append(type_hint("card_owner", TYPE_STRING, PROPERTY_HINT_ENUM,
						"Allied,Opponent,Player,Enemy"))
				list.append(type_hint("card_location", TYPE_STRING, PROPERTY_HINT_ENUM,
						"Deck,Hand"))
			'add_tag':
				list.append(tag_hint("tag"))
			'advance_activation':
				list.append(type_hint("turns", TYPE_INT))
			'attach':
				subject = "target"
			'attack':
				subject = "target"
			'block':
				persistent_effect = false
			'buff_stats':
				list.append(resource_hint("buff_damage", "EffectValue"))
				list.append(resource_hint("buff_health", "EffectValue"))
				list.append(resource_hint("buff_shield", "EffectValue"))
				list.append(resource_hint("buff_activation", "EffectValue"))
				list.append(type_hint("affect_max", TYPE_BOOL))
				list.append(type_hint("persistent_effect", TYPE_BOOL))
			'damage':
				list.append(resource_hint("damage_amt", "EffectValue"))
				list.append(type_hint("blocked_by_shield", TYPE_BOOL))
			'delayed_effect':
				list.append(resource_hint("delayed_effects", "DelayedEffect"))
			'disable_act':
				list.append(type_hint("act_disabled", TYPE_BOOL))
				list.append(type_hint("persistent_effect", TYPE_BOOL))
			'discard':
				pass
			'remove_tag':
				list.append(tag_hint("tag"))
			'set_act':
				list.append(type_hint("can_act", TYPE_BOOL))
			'set_stats':
				list.append(resource_hint("set_damage", "EffectValue"))
				list.append(resource_hint("set_health", "EffectValue"))
				list.append(resource_hint("set_shield", "EffectValue"))
				list.append(resource_hint("set_activation", "EffectValue"))
				list.append(type_hint("affect_max", TYPE_BOOL))
				list.append(type_hint("persistent_effect", TYPE_BOOL))
			'change_art':
				list.append(type_hint("new_art", TYPE_STRING))
			'add_debuff':
				list.append(type_hint("debuff", TYPE_STRING, PROPERTY_HINT_ENUM,
						"poison,vulnerable,feeble"))
				list.append(resource_hint("debuff_amount", "EffectValue"))
			'change_bus_var':
				list.append(type_hint("bus_var", TYPE_STRING, PROPERTY_HINT_ENUM,
						"mana,gold,spell_power,food"))
				list.append(resource_hint("bus_var_change", "EffectValue"))
			'permanent_buff':
				list.append(resource_hint("perm_damage", "EffectValue"))
				list.append(resource_hint("perm_health", "EffectValue"))
				list.append(resource_hint("perm_shield", "EffectValue"))
				list.append(resource_hint("perm_activation", "EffectValue"))
			'modify_cost':
				list.append(resource_hint("cost_change", "EffectValue"))
				list.append(type_hint("persistent_effect", TYPE_BOOL))
			'change_max_activation':
				list.append(resource_hint("max_activation_change", "EffectValue"))
				list.append(type_hint("persistent_effect", TYPE_BOOL))
			'upgrade_unit':
				list.append(resource_hint("unit_upgrade", "UnitUpgrade"))
			
		if trigger_signal == "consume_used":
			animation = "cast"
	else:
		match function:
			# these functions are always instantaneous
			# others are set via export
			'add_card_to_deck', 'add_tag',\
					'attach', 'attack', 'block', 'damage', 'delayed_event',\
					'discard', 'remove_tag', 'set_act', 'new_art', 'add_debuff',\
					'change_bus_var', 'add_card', 'advance_activation':
				persistent_effect = false
	return(list)

func type_hint(property_name: String, type: int, 
				hint: int = PROPERTY_HINT_NONE, hintstring: String = "") -> Dictionary:
	return({
		"name": property_name, 
		"class_name": &"", 
		"type": type, 
		"hint": hint,
		"hint_string": hintstring,
		"usage": 4102
	})

func resource_hint(property_name: String, resource_type: String) -> Dictionary:
	return({
	"name": property_name,
	"class_name": &"DelayedEffect",
	"type": TYPE_OBJECT,
	"hint": PROPERTY_HINT_RESOURCE_TYPE,
	"hint_string": resource_type, 
	"usage": 4102
	})
	
func tag_hint(property_name: String) -> Dictionary:
	return({
		"name": property_name, 
		"class_name": &"res://src/Autoloads/CardCraft.gd.Tag", 
		"type": TYPE_INT, 
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Creature:0,Taunt:1,Resistant:2,Magic:3,Stealth:4,Mounted:5,Flying:6,Physical:7",
		"usage": 69638
	})

func string_enum_hint(property_name: String, string_enums: String) -> Dictionary:
	return({
		"name": property_name, 
		"class_name": &"", 
		"type": TYPE_STRING, 
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": string_enums,
		"usage": 4102
	})
	
func string_array_hint(property_name: String, string_enums: String) -> Dictionary:
	return({
		"name": property_name, 
		"class_name": &"", 
		"type": TYPE_ARRAY, 
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "4/2:%s"%string_enums,
		"usage": 4102
	})
	
func dupe() -> Effect:
	var property_list = get_script().get_script_property_list()
	var properties: Array[String] = []
	for property in property_list:
		properties.append(property["name"])
	properties.erase("Effect.gd")
	var new: Effect = self.duplicate(true)
	## properties that aren't exported seem to not be copied correctly
	for property in properties:
		if get(property) is EffectValue or get(property) is EffectIf:
			new.set(property, get(property).dupe())
		else:
			new.set(property, get(property))
	new.conditions_subject = conditions_subject.duplicate(true)
	new.conditions_calling = conditions_calling.duplicate(true)
	return(new)
