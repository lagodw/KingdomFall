extends VBoxContainer

var label: CardLabel

# TODO: change stat string to icon when card ready
func _ready() -> void:
	$Title/HBoxContainer/Background/Icon.texture = label.preview_card.get_node("%CardArt").texture
	$Title/HBoxContainer/TitleText.text = label.card_resource.card_name
	var text = label.card_resource.text
	$Description/DescriptionText.text = text
	$Description.visible = (text != "")
	# determine size of popup box based on length of text
	var panel = get_node("Description/DescriptionText")
	var font = panel.get_theme_font("font")
	var font_size = panel.get_theme_font_size("font_size")
	var text_size = font.get_multiline_string_size(panel.text, 1, 
		panel.custom_minimum_size.x, font_size, -1, 2, 0, 0, 0)
	get_node("Description").custom_minimum_size.y = text_size.y + 7
	panel.custom_minimum_size.y = text_size.y
	if label.card_resource is ItemResource:
		for stat in ["Damage", "Shield", "Health"]:
			if label.card_resource.get(stat.to_lower()) != 0:
				get_node("%" + stat).visible = true
				get_node("%" + stat + "Text").text = str(label.card_resource.get(stat.to_lower()))
				$Stats.visible = true
