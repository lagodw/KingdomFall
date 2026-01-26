extends VBoxContainer

var key: String
var text: String
var icon_path: String = ""
	
func _ready() -> void:
	update_text()
	
func update_text():
	get_node("Title/H/TitleText").text = " " + key
	var panel = get_node("Description/DescriptionText")
	panel.text = text
	# determine size of popup box based on length of text
	var font = panel.get_theme_font("font")
	var font_size = panel.get_theme_font_size("font_size")
	var text_size = font.get_multiline_string_size(panel.text, 1, 
		panel.custom_minimum_size.x, font_size, -1, 2, 0, 0, 0)
	get_node("Description").custom_minimum_size.y = text_size.y + 7
	panel.custom_minimum_size.y = text_size.y
	
	if icon_path != "":
		var icon = load(icon_path)
		$Title/H/Icon.texture = icon
		$Title/H/Icon.visible = true
	else:
		$Title/H/Icon.visible = false
