extends HBoxContainer

var tag_folder = "res://assets/Card/Icons/"
	
func add_tags():
	for child in get_children():
		child.queue_free()
	if owner is Unit:
		for skill: UnitSkill in owner.card_resource.skills:
			# TODO: use resourcegroup
			var skill_name: String = UnitSkill.Skill.keys()[skill.skill_type]
			var path = tag_folder + "%s.png"%skill_name
			add_icon(load(path))

func add_icon(texture: Texture):
	var rect = TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	rect.texture = texture
	add_child(rect)
