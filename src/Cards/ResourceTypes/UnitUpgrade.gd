class_name UnitUpgrade
extends Resource

enum Upgrade {
	TRAINING,
	EDUCATION,
	PRODUCTIVITY,
}

@export var upgrade_type: Upgrade
@export var amount: int = 1
## only need to populate if not straight int, 
## otherwise uses amount
@export var effect_value: EffectValue
