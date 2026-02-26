extends Control

@onready var highlight: ReferenceRect = $Highlight
@onready var box: HBoxContainer = $%CardsBox

func _ready() -> void:
	mouse_exited.connect(show_highlight.bind(false))

func load_units(resources: Array[CardResource]):
	for res in resources:
		if res is UnitResource:
			var card = kf.create_card(res)
			box.add_child(card)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if (data is CardToken and get_tree().current_scene is Town) or (
			data is Unit and get_tree().current_scene is Combat):
		show_highlight(true)
		return(true)
	return(false)

func _drop_data(_at_position: Vector2, data: Variant):
	kf.dragging = null
	if data is CardToken:
		add_token(data)
	elif data is Card:
		add_card(data)
	show_highlight(false)
	
func show_highlight(value: bool):
	highlight.visible = value
	
func add_token(token: CardToken):
	var card = token.turn_to_card()
	if card.get_parent():
		card.get_parent().remove_child(card)
	box.add_child(card)
	token.current_slot.job.release_unit(token)
	token.current_slot = null

func add_card(card: Unit):
	card.visible = true
	card.move_to(box, false)

## Returns all of the Unit Cards
func get_units() -> Array[Unit]:
	var units: Array[Unit]
	for unit in box.get_children():
		units.append(unit)
	return(units)
