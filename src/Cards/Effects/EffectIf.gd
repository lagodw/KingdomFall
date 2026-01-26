@tool
class_name EffectIf
extends Resource

@export_enum("now", "this_turn", "last_turn") var time_frame: String = "now"
@export_enum("Owner", "Opponent") var who: String = "Owner"
@export_enum("value", "log") var what: String = "value":
	set(val):
		what = val
		notify_property_list_changed()
@export var minimum: int = 0
@export var maximum: int = 999

var value: EffectValue = EffectValue.new()
var event: String # attack, damage taken, spell cast, unit played

func check_if_true(subject: Control, calling_card: Control, trigger_card: Control) -> bool:
	var callable = Callable.create(self, what)
	var result: bool = callable.call(subject, calling_card, trigger_card)
	return(result)
	
func check_value(subject: Control, calling_card: Control,trigger_card: Control) -> bool:
	var val = value.get_value(subject, trigger_card, calling_card)
	if val >= minimum and val <= maximum:
		return(true)
	return(false)

func _get_property_list() -> Array:
	var list := []
	if Engine.is_editor_hint():
		if what == "value":
			list.append(Utils.resource_hint("value", "EffectValue"))
	return(list)
	
func dupe() -> EffectIf:
	var new: EffectIf = self.duplicate(true)
	if value:
		new.value = value.dupe()
	return new
