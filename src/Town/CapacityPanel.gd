extends Panel

var full: bool = false

func set_panel(filled: bool = false, under_construction: bool = false):
	var color: Color = Color("004f86")
	if under_construction:
		color = Color.GRAY
	var box: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	box.draw_center = filled
	box.bg_color = color
	box.border_color = color
	add_theme_stylebox_override("panel", box)
	full = filled
