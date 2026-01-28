extends TextureRect

@onready var highlight: ReferenceRect = $Highlight
@onready var box: HBoxContainer = $%CardsBox

func _ready() -> void:
	load_units()
	mouse_exited.connect(show_highlight.bind(false))

func load_units():
	for res in Bus.deck.cards:
		if res is UnitResource:
			var card = kf.create_card(res)
			box.add_child(card)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is CardToken:
		show_highlight(true)
		return(true)
	return(false)

func _drop_data(_at_position: Vector2, data: Variant):
	kf.dragging = null
	add_unit(data)
	show_highlight(false)
	
func show_highlight(value: bool):
	highlight.visible = value
	
func add_unit(token: CardToken):
	var card = token.turn_to_card()
	box.add_child(card)
	token.current_slot.building.release_unit(token)
	token.current_slot = null
