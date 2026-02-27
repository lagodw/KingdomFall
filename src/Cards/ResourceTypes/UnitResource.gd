class_name UnitResource
extends CardResource

@export var fatigue: int = 0:
	set(val):
		fatigue = clamp(val, 0, 10)
@export var damage: int = 1
@export var health: int = 1
@export var shield: int = 0
@export var attack_type: kf.AttackType = kf.AttackType.Melee
@export var armor_type: kf.ArmorType = kf.ArmorType.Light
@export var has_support: bool = false
@export var combat_modifiers: Array[CombatModifier] = []
@export var default_animation: String = "sword"
@export var curses: Array[Curse]
@export var skills: Array[UnitSkill]
@export var upgrade_options: Array[UnitUpgrade]

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

func get_skill_count(check_skill: UnitSkill.Skill) -> int:
	var count: int = 0
	for skill in skills:
		if skill.skill_type == check_skill:
			count += 1
	return(count)

func check_upgrade_requirements(upgrade: UnitUpgrade) -> bool:
	for requirement in upgrade.requirements:
		if get_skill_count(requirement.skill) < requirement.amount:
			return(false)
	return(true)
	
func get_eligible_upgrades() -> Array[UnitUpgrade]:
	var eligible: Array[UnitUpgrade]
	for upgrade in upgrade_options:
		if check_upgrade_requirements(upgrade):
			eligible.append(upgrade)
	return(eligible)
