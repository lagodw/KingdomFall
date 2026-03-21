extends Panel

var occupant: CardToken

func fill_panel(token: CardToken, under_construction: bool = false):
	occupant = token
	$TextureRect.texture = token.get_node("%CardArt").texture
	$TextureRect.visible = true
	var color: Color = Color("004f86")
	if under_construction:
		color = Color.GRAY
	var box: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	box.border_color = color
	add_theme_stylebox_override("panel", box)

func empty_panel():
	occupant = null
	$TextureRect.visible = false

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not occupant:
		return(null)
	
	return(occupant._get_drag_data(_at_position))
