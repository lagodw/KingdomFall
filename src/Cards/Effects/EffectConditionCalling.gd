class_name EffectConditionCalling
extends Resource

@export var require_trigger: bool = true
@export_enum("Any", "Frontline", "Backline") var require_line: String = "Any"
@export var require_building_name: String
@export var require_job_name: String = ""
@export var require_act: bool = false
@export var minimum_damage: int = 0
## remaining_life > 0
@export var require_alive: bool = false
@export_enum("Either", "Player", "Enemy") var require_owner: String = "Either"
@export var require_turn: int = -1
