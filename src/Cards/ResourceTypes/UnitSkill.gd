class_name UnitSkill
extends Resource

enum Skill {
	TRAINING,
	EDUCATION,
	PRODUCTIVITY,
}

@export var skill_type: Skill
@export var amount: int = 1
## only need to populate if not straight int, 
## otherwise uses amount
@export var effect_value: EffectValue
