@tool # so tools can use
extends Node

#var lab_butt = preload("uid://cskytl426eobe")
var lab_butt

## add buttons for player to choose any label in deck
## type is string that can be Unit, Item, Spell to filter or anything else for all
func add_deck_buttons(type: String = "Unit") -> Array[Button]:
	var buttons: Array[Button] = []
	for label in Bus.PlayerDeck.cards.get_children():
		if label.card_resource is not UnitResource and type == "Unit":
			continue
		elif label.card_resource is not ItemResource and type == "Item":
			continue
		elif label.card_resource is not SpellResource and type == "Spell":
			continue
		elif label.card_resource is not BurdenResource and type == "Burden":
			continue
		var button = add_deck_button(label)
		buttons.append(button)
	return(buttons)
		
func add_deck_button(label: CardLabel) -> Button:
	var butt = lab_butt.instantiate()
	butt.mouse_entered.connect(label._on_mouse_enter)
	butt.mouse_exited.connect(label._on_mouse_exit)
	label.add_child(butt)
	return(butt)

func safe_divide(numerator: float, denominator: float) -> float:
	if denominator == 0 and numerator == 0:
		return(0)
	if denominator == 0:
		return(INF)
	return(numerator / denominator)

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

func strip_bold(txt: String) -> String:
	return(txt.replace("[b]", "").replace("[/b]", ""))
