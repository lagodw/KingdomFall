class_name UnitResource
extends CardResource

@export var fatigue: int = 0
@export var damage: int = 1
@export var health: int = 1
@export var shield: int = 0
@export var attack_range: int = 1
@export var speed: int = 5
@export var attack_type: kf.AttackType = kf.AttackType.Melee
@export var armor_type: kf.ArmorType = kf.ArmorType.Light
@export var has_support: bool = false
@export var combat_modifiers: Array[CombatModifier] = []
@export var default_animation: String = "sword"
@export var curses: Array[Curse]
@export var skills: Array[UnitSkill]

@export_category("Enemy Behavior")
@export_enum("Hybrid", "Attack", "Defend", "Support") var box_priority: String = "Hybrid"
# support target
@export_enum("none_needed", "any_enemy", "any_ally", "activation_label"
		) var target: String = "none_needed"
# if unit is support, estimate of value of the support to be used for sorting
@export var equivalent_damage: int = 0
@export var target_face: bool = false

## hopefully temporary workaround
## https://github.com/godotengine/godot/issues/74918
func dupe() -> Resource:
	var duped = self.duplicate(true)
	var new_effects: Array[Effect] = []
	for effect in effects:
		new_effects.append(effect.dupe())
	duped.effects = new_effects
	return(duped)
