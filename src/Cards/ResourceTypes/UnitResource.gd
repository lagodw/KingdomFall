class_name UnitResource
extends CardResource

@export var fatigue: int = 0:
	set(val):
		fatigue = clamp(val, 0, 10)
@export var damage: int = 1
@export var health: int = 1
@export var shield: int = 0

@export var attack_range: int = 1

@export var speed: int = 5
@export var attack_type: kf.AttackType = kf.AttackType.Melee
@export var armor_type: kf.ArmorType = kf.ArmorType.Light
@export var has_support: bool = false
@export var combat_modifiers: Array[CombatModifier]
@export var default_animation: String = "sword"
@export var curses: Array[Curse]
@export var skills: Array[UnitSkill]
## requirements to upgrade to this unit
@export var upgrade_requirements: Array[UpgradeRequirement]
@export var upgrade_options: Array[UnitResource]

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
	var new_requirements: Array[UpgradeRequirement]
	for requirement in upgrade_requirements:
		new_requirements.append(requirement)
	var new_skills: Array[UnitSkill]
	# populate new units with base requirements
	# so I don't have to do it manually in inspector
	if skills.size() == 0:
		var has_productivity: bool = false
		for requirement in upgrade_requirements:
			var new_skill = UnitSkill.new()
			new_skill.skill = requirement.skill
			new_skill.amount = requirement.amount
			new_skills.append(new_skill)
			if requirement.skill == UnitSkill.Skill.Productivity:
				has_productivity = true
		if not has_productivity:
			var new_skill = UnitSkill.new()
			new_skill.skill = UnitSkill.Skill.Productivity
			new_skill.amount = 1
			new_skills.append(new_skill)
	else:
		for skill in skills:
			new_skills.append(skill.dupe())
	var new_upgrades: Array[UnitResource]
	if upgrade_options.size() == 0:
		new_upgrades = []
	else:
		for upgrade in upgrade_options:
			new_upgrades.append(upgrade.dupe())
	duped.effects = new_effects
	duped.upgrade_requirements = new_requirements
	duped.skills = new_skills
	duped.upgrade_options = new_upgrades
	return(duped)

func get_skill_count(check_skill: UnitSkill.Skill) -> int:
	var count: int = 0
	for skill in skills:
		if skill.skill == check_skill:
			count += 1
	return(count)

func check_upgrade_requirements(upgrade: UnitResource) -> bool:
	if not upgrade.card_name in Bus.player.charters:
		return(false)
	for requirement in upgrade.upgrade_requirements:
		if get_skill_count(requirement.skill) < requirement.amount:
			return(false)
	return(true)
	
func get_eligible_upgrades() -> Array[UnitResource]:
	var eligible: Array[UnitResource]
	for upgrade in upgrade_options:
		if check_upgrade_requirements(upgrade):
			eligible.append(upgrade)
	return(eligible)
