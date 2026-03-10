@tool
class_name EffectValue
extends Resource

@export_enum("number", "stat", "skill", "count", "effect_value") var value_type: String = "number":
	set(val):
		value_type = val
		notify_property_list_changed()
@export var affected_by_spell_power: bool = false
var number: int
var what_stat: String = "damage"
var what_skill: UnitSkill.Skill
var whos_stat: String = "subject"
var negative: bool = false
var count_what: String = "units":
	set(val):
		count_what = val
		notify_property_list_changed()
var count_whos: Array[String] = ["Owner"]
var which_card: String = "trigger"
var count_where: String = "Units"
var count_boxes: Array[String] = ["Front", "Back"]
var log_turn: String = "current_turn"
var log_event: String = "play"
var count_filter: String = "any":
	set(val):
		count_filter = val
		notify_property_list_changed()
var filter_tag: kf.Tag
var filter_card_name: String
var filter_attack_type: kf.AttackType
var filter_armor_type: kf.ArmorType
var effect_val: String

var chain_value: bool = false:
	set(val):
		chain_value = val
		notify_property_list_changed()
# can't have .new() here or it will cause infinite loop creating them
var next_value: EffectValue
var mult_next_value: bool = false

func get_value(subject: Control, trigger_card: Control, calling_card: Control,
				effect_dict: Dictionary = {}) -> int:
	var callable = Callable.create(self, "get_%s"%value_type)
	var card: Control = trigger_card
	if which_card == "calling":
		card = calling_card
	var value: int = callable.call(subject, card, effect_dict)
	if affected_by_spell_power:
		value += Bus.spell_power
		
	if chain_value:
		var next_val = next_value.get_value(subject, trigger_card, calling_card, effect_dict)
		if mult_next_value:
			value *= next_val
		else:
			value += next_val
	return(value)
	
func get_number(_subject: Control, _card: Control, _effect_dict: Dictionary) -> float:
	return(number)
	
func get_stat(subject: Control, card: Control, _effect_dict: Dictionary) -> float:
	var stat_owner: Unit = get_stat_owner(subject, card)
	var stat: int = stat_owner.get("current_%s"%what_stat)
	if negative:
		return(-stat)
	else:
		return(stat)

func get_count(_subject: Control, card: Control, _effect_dict: Dictionary) -> float:
	match count_what:
		"units":
			var units: Array[Unit] = get_count_units(card)
			var filtered_units: Array[Unit] 
			if count_filter == "any":
				filtered_units = units
			else:
				var filter = Callable.create(self, "apply_filter_%s"%count_filter)
				filtered_units = filter.call(units)
			return(filtered_units.size())
		"log":
			return(get_count_log(card))
	return(0)

func get_stat_owner(subject: Control, card: Control) -> Unit:
	match whos_stat:
		'subject':
			return(subject)
		'trigger':
			return(card)
		'target':
			return(card.targeting_arrow.target_object)
	return(null)

func get_count_units(trigger_card: Control) -> Array[Unit]:
	var units: Array[Unit] = []
	for person in count_whos:
		var player: String = trigger_card.card_owner
		if person == "Opponent":
			player = kf.invert_owner(player)
		match count_where:
			"Hand":
				var cards = Bus.get("%sHand"%player).get_children()
				for card in cards:
					if card is Unit:
						units.append(card)
			"Discard":
				var labels = Bus.get("%sDiscard"%player).get_labels()
				for label in labels:
					if label.preview_card is Unit:
						units.append(label.preview_card)
			"Units":
				for box in count_boxes:
					var box_name = "%s_%s" % [player.to_lower(), box.to_lower()]
					for unit in Bus.Grid.get(box_name).get_units():
						units.append(unit)
	return(units)
	
func get_count_log(trigger_card: Card) -> float:
	var count: float = 0.0
	var current_turn = Bus.Board.turn_counter
	
	var target_turn: int
	match log_turn:
		"current_turn":
			target_turn = current_turn
		"last_turn":
			target_turn = current_turn - 1
		
	var combat_log = Bus.Board.combat_log
	if combat_log == null:
		return 0
		
	for event in combat_log.events:
		if event.turn == target_turn:
			if event.action == log_event:
				if event.who == trigger_card.card_owner and count_whos.has("Owner"):
					count += 1
				elif event.who != trigger_card.card_owner and count_whos.has("Opponent"):
					count += 1
	return(count)
	
func get_skill(subject: Control, card: Control, _effect_dict: Dictionary) -> float:
	var skill_owner: Unit = get_stat_owner(subject, card)
	var amount: float = 0.0
	for skill: UnitSkill in skill_owner.card_resource.skills:
		if skill.skill == what_skill:
			amount += skill.amount * (10.0 - skill_owner.card_resource.fatigue) / 10.0
	if negative:
		return(-amount)
	else:
		return(amount)
	
func apply_filter_tag(units: Array[Unit]) -> Array[Unit]:
	var filtered_units: Array[Unit] = []
	for unit in units:
		if unit.tags.has(filter_tag):
			filtered_units.append(unit)
	return(filtered_units)
	
func apply_filter_card_name(units: Array[Unit]) -> Array[Unit]:
	var filtered_units: Array[Unit] = []
	for unit in units:
		if unit.card_name == filter_card_name:
			filtered_units.append(unit)
	return(filtered_units)
	
func apply_filter_attack_type(units: Array[Unit]) -> Array[Unit]:
	var filtered_units: Array[Unit] = []
	for unit in units:
		if unit.card_resource.attack_type == filter_attack_type:
			filtered_units.append(unit)
	return(filtered_units)
	
func apply_filter_armor_type(units: Array[Unit]) -> Array[Unit]:
	var filtered_units: Array[Unit] = []
	for unit in units:
		if unit.card_resource.armor_type == filter_armor_type:
			filtered_units.append(unit)
	return(filtered_units)

func get_effect_value(_subject: Control, _card: Control, effect_dict: Dictionary):
	return(effect_dict[effect_val])

func _get_property_list() -> Array:
	#print(get_script().get_script_property_list())
	var list := []
	if Engine.is_editor_hint():
		match value_type:
			'number':
				list.append(type_hint("number", TYPE_INT))
			
			'stat':
				list.append(string_enum_hint("which_card", "trigger,calling"))
				list.append(string_enum_hint("what_stat", "damage,health,shield,fatigue"))
				list.append(string_enum_hint("whos_stat", "subject,trigger,target"))
				list.append(type_hint("negative", TYPE_BOOL))
			
			'skill':
				list.append(string_enum_hint("which_card", "trigger,calling"))
				list.append(skill_hint("what_skill"))
				list.append(string_enum_hint("whos_stat", "subject,trigger,target"))
				list.append(type_hint("negative", TYPE_BOOL))
			
			'count':
				list.append(string_enum_hint("count_what", "units,log"))
				list.append(string_enum_hint("which_card", "trigger,calling"))
				list.append(string_array_hint("count_whos", "Owner,Opponent"))
				match count_what:
					"units":
						list.append(string_enum_hint("count_where", "Hand,Units,Discard"))
						if count_where == "Units":
							list.append(string_array_hint("count_boxes", "Front,Back"))
						list.append(string_enum_hint("count_filter", "any,tag,card_name,attack_type,armor_type"))
						match count_filter:
							'any':
								pass
							'tag':
								list.append(tag_hint("filter_tag"))
							'card_name':
								list.append(type_hint("filter_card_name", TYPE_STRING))
							'attack_type':
								list.append(attack_type_hint("filter_attack_type"))
							'armor_type':
								list.append(armor_type_hint("filter_armor_type"))
					"log":
						list.append(string_enum_hint("log_turn", "current_turn,last_turn"))
						list.append(string_enum_hint("log_event", "play,cast,target,damage,attack"))
			'effect_value':
				list.append(string_enum_hint("effect_val", "mana_cost,damage_amount"))
		list.append(type_hint("chain_value", TYPE_BOOL))
		if chain_value:
			list.append(resource_hint("next_value", "EffectValue"))
			list.append(type_hint("mult_next_value", TYPE_BOOL))
	return(list)

func type_hint(property_name: String, property_type: int) -> Dictionary:
	return({
		"name": property_name, 
		"class_name": &"", 
		"type": property_type,
		"usage": 4102
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

func tag_hint(property_name: String) -> Dictionary:
	return({
		"name": property_name, 
		"class_name": &"res://src/Autoloads/CardCraft.gd.Tag", 
		"type": TYPE_INT, 
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Creature:0,Taunt:1,Resistant:2,Magic:3,Stealth:4,Mounted:5,Flying:6,Physical:7",
		"usage": 69638
	})
	
func attack_type_hint(property_name: String) -> Dictionary:
	return({
		"name": property_name, 
		"class_name": &"res://src/Autoloads/CardCraft.gd.AttackType", 
		"type": TYPE_INT, 
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Melee:0,Ranged:1,Magic:2",
		"usage": 69638
	})

func armor_type_hint(property_name: String) -> Dictionary:
	return({
		"name": property_name, 
		"class_name": &"res://src/Autoloads/CardCraft.gd.ArmorType", 
		"type": TYPE_INT, 
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Light:0,Heavy:1",
		"usage": 69638
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
	
func skill_hint(property_name: String) -> Dictionary:
	return({
		"name": property_name, 
		"class_name": &"uid://bn2lsa6d725jx.Skill", 
		"type": TYPE_INT, 
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Training:0,Education:1,Productivity:2",
		"usage": 69638
	})
	
func dupe() -> EffectValue:
	var property_list = get_script().get_script_property_list()
	var properties: Array[String] = []
	for property in property_list:
		properties.append(property["name"])
	properties.erase("EffectValue.gd")
	var new: EffectValue = self.duplicate(true)
	## properties that aren't exported seem to not be copied correctly
	for property in properties:
		new.set(property, get(property))
	return(new)
