class_name CombatModifier
extends Resource

@export_enum("Attack", "Block") var affect_when: String = "Attack"
@export_enum("Attacker", "Defender") var affect_whos_damage: String = "Attacker"
@export var require_opponent_tag: Array[kf.Tag] = []
@export var require_opponent_attack_type: Array[kf.AttackType] = []
@export var require_opponent_armor_type: Array[kf.ArmorType] = []
@export var require_slot_types: Array[TokenSlot.SlotType] = [
	TokenSlot.SlotType.Vanguard, TokenSlot.SlotType.Assault, TokenSlot.SlotType.Support]
@export var require_target_face: bool = false
## for now can only be used on attackers
@export var unit_comparison: StatComparison
@export var value: EffectValue = EffectValue.new()

## returns [attacker_change, defender_change]
func get_modified_combat(attacker: CardToken, defender: CardToken, is_attacker: bool) -> Array[int]:
	var attacker_change: int = 0
	var defender_change: int = 0
	
	if is_attacker and affect_when == "Block" or not is_attacker and affect_when == "Attack":
		return([0, 0])
	var opponent: CardToken = defender
	var effect_owner: CardToken = attacker
	if not is_attacker:
		opponent = attacker
		effect_owner = defender
	if require_opponent_tag:
		if not opponent.tags.has(require_opponent_tag):
			return([0, 0])
	if require_opponent_attack_type:
		if not opponent.card_resource.attack_type in require_opponent_attack_type:
			return([0, 0])
	if require_opponent_armor_type:
		if not opponent.card_resource.armor_type in require_opponent_armor_type:
			return([0, 0])
	if not effect_owner.current_slot:
		return([0, 0])
	if not require_slot_types.has(effect_owner.current_slot.slot_type):
		return([0, 0])
	if require_target_face and defender is not Face:
		return([0, 0])
	if unit_comparison:
		if not unit_comparison.compare_units(attacker, defender):
			# then comparison has failed so don't apply
			return([0, 0])
	# order of attacker/defender only matter if value is stat
	# if it is a stat the order of application would matter so that's bad idea
	if affect_whos_damage == "Attacker":
		attacker_change = int(round(value.get_value(attacker, effect_owner, effect_owner)))
	else:
		defender_change = int(round(value.get_value(defender, effect_owner, effect_owner)))
	
	return([attacker_change, defender_change])
