extends Control

@export var card_resource: UnitResource
@onready var button: Button = %Choose
var card: Card

func setup():
	var token: CardToken = kf.create_token(card_resource)
	token.disabled = true
	%TokenSpot.add_child(token)
	await get_tree().process_frame
	token.remaining_life = token.current_health
	set_description()
	set_requirements()
	card = kf.create_card(card_resource)
	card.disabled = true
	$CardSpot.add_child(card)
	$Choose.mouse_entered.connect(show_card.bind(true))
	$Choose.mouse_exited.connect(show_card.bind(false))
	
func set_description():
	var sp_text = ""
	if Bus.spell_power > 0:
		sp_text = " (+%s)"%Bus.spell_power
	var skill_text = kf.replace_text_icons(card_resource.text, 16)
	%Description.text = skill_text.replace("[+sp]", sp_text)

func set_requirements():
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
		space.custom_minimum_size.x = 20
		space.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(space)
		
func add_icon(texture: Texture):
	var rect = TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture = texture
	%Requirements.add_child(rect)

func show_card(to_show: bool):
	$CardSpot.visible = to_show
	card.show_popups(to_show)
