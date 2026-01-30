extends HBoxContainer

var skill: UnitSkill.Skill
var progress: int
var required: int

func _ready() -> void:
	$Label.text = "%s / %s"%[progress, required]
	var icon_path = "res://assets/Card/Icons/%s.png"%UnitSkill.Skill.keys()[skill]
	$Icon.texture = load(icon_path)
