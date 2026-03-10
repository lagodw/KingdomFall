class_name EffectConditionSubject
extends Resource

@export var require_allied: bool = false
@export var require_enemies: bool = false
@export var exclude_trigger: bool = false
@export var require_act: bool = false
@export var exclude_act: bool = false
@export var require_act_disabled: bool = false
@export var exclude_act_disabled: bool = false
@export var exclude_faces: bool = true
@export var require_activated: bool = true
@export var require_same_file: bool = false
@export var require_same_rank: bool = false
@export var require_tags: Array[kf.Tag] = []
@export var exclude_tags: Array[kf.Tag] = []
@export var require_attack_type: Array[kf.AttackType] = [
	kf.AttackType.Melee, kf.AttackType.Ranged, kf.AttackType.Magic]
@export var require_armor_type: Array[kf.ArmorType] = [
	kf.ArmorType.Light, kf.ArmorType.Heavy]
@export var exclude_item_type_equipped: Array[kf.ItemType] = []
@export var required_slots: Array[TokenSlot.SlotType] = []
## empty array means no requirement
@export_enum("Unit", "Spell", "Item", "Burden", "Consume") var require_card_type: Array[String] = []
@export var minimum_damage: int = 0
@export var minimum_shield: int = 0
@export var require_missing_health := false
## remaining_life > 0
@export var require_alive: bool = false
@export_enum("Any", "Owner", "Opponent") var require_turn_phase: String = "Any"
@export var require_breach: bool = false
@export var require_no_breach: bool = false
@export var minimum_activation: int = 0
@export var maximum_activation: int = 99
@export var require_name: String = ""
