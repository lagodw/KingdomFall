class_name Job
extends Resource

@export var description: String
@export var capacity: int = 1
@export var effects: Array[Effect]
@export var requirements: Array[UpgradeRequirement]
@export var progress: Array[UpgradeRequirement]


func dupe() -> Job:
	var duped: Job = duplicate(true)
	var duped_effects: Array[Effect]
	for effect in effects:
		duped_effects.append(effect.dupe())
	duped.effects = duped_effects
	var duped_requirements: Array[UpgradeRequirement]
	for requirement in requirements:
		duped_requirements.append(requirement.dupe())
	duped.requirements = duped_requirements
	var duped_progress: Array[UpgradeRequirement]
	for current_progress in progress:
		duped_progress.append(current_progress.dupe())
	duped.progress = duped_progress
	return(duped)
