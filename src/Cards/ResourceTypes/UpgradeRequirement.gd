class_name UpgradeRequirement
extends Resource

@export var skill: UnitSkill.Skill
@export var amount: int
@export var progress: int = 0

func dupe() -> UpgradeRequirement:
	var duped: UpgradeRequirement = self.duplicate(true)
	return(duped)
