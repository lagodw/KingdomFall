class_name UpgradeRequirement
extends Resource

@export var skill: UnitSkill.Skill
## TODO: could just use the amount from skill
@export var amount: float
@export var progress: float = 0.0

func dupe() -> UpgradeRequirement:
	var duped: UpgradeRequirement = self.duplicate(true)
	return(duped)
