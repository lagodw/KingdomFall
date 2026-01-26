class_name SpellResource
extends CardResource

@export var mana_cost: int = 1
@export_category("Enemy Behavior")
@export_enum("none_needed", "enemy", "ally", "activation_label") var target: String = "none_needed"
