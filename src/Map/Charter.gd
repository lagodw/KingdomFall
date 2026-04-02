extends Control

@export var card_resource: CardResource
@onready var button: Button = %Choose

func setup():
	var card = kf.create_card(card_resource)
	card.disabled = true
	%CardSpot.add_child(card)
	await get_tree().process_frame
	set_requirements()
	
func set_requirements():
	if card_resource is UnitResource:
		for skill_type in UnitSkill.Skill.values():
			for requirement in card_resource.upgrade_requirements:
				var required_skill: UnitSkill.Skill = requirement.skill
				if required_skill != skill_type:
					continue
				for i in requirement.amount:
					# TODO: use resourcegroup
					var skill_name: String = UnitSkill.Skill.keys()[required_skill]
					var path = "res://assets/Card/Icons/%s.png"%skill_name
					add_icon(load(path))
			var space: Control = Control.new()
			space.custom_minimum_size.x = 40
			space.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(space)
		
func add_icon(texture: Texture):
	var rect = TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture = texture
	%Requirements.add_child(rect)
