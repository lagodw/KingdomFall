class_name ItemResource
extends CardResource

@export var item_type: kf.ItemType
@export var attack_type: kf.AttackType = kf.AttackType.Melee
@export var armor_type: kf.ArmorType = kf.ArmorType.Light
@export var damage: int = 0
@export var health: int = 0
@export var shield: int = 0
@export var max_durability: int = 5
@export var current_durability: int = 5
@export var cost: int = 0
@export var combat_modifiers: Array[CombatModifier] = []
@export_enum("none_needed", "enemy", "ally", "activation_label") var target: String = "ally"
