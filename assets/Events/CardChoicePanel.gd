class_name CardChoice
extends Control

@onready var scroll: ScrollContainer = %ScrollContainer
@onready var grid: GridContainer = %GridContainer
@export var row_size: int = 5
var button_scene: PackedScene = load("uid://7iyrp623m11p")
var card_options: Array
var num_choices: int
var option_selected: Control
var options_selected: Array[Control]

# options is array but could be different card resource types
func setup(options: Array, number_choices: int, _type: String = "Units") -> void:
	num_choices = number_choices
	#var cols = min(row_size, options.size())
	#var rows = min(ceili(float(options.size()) / row_size), 2)
	#scroll.size.x = cols * Bus.card_size.x + (
			#cols) * grid.get_theme_constant("h_separation")
	#scroll.size.y = rows * Bus.card_size.y + (
			#rows) * grid.get_theme_constant("v_separation")
	#if rows > 1:
		#size.y += Bus.card_size.y / 2
	#if cols < 5:
		#size.x -= Bus.card_size.x * (5 - cols - 1)
	#position = get_parent().size / 2 - size / 2
	#scroll.position = size / 2 - scroll.size / 2
	for option in options:
		card_options.append(option)
	card_options.sort_custom(kf.sort_resources)
	$Buttons/Leave.pressed.connect(leave)
	$Buttons/Confirm.pressed.connect(confirm)
	#%ChooseText.text = tr("KEY_CARD_CHOICE")%[num_choices, type]
	create_cards()

func create_cards() -> void:
	for option in card_options:
		var button = button_scene.instantiate()
		var card = kf.create_card(option)
		grid.add_child(card)
		card.disabled = true
		card.add_child(button)
		button.card = card
		button.pressed.connect(option_pressed.bind(button))
		
func option_pressed(option: Button) -> void:
	if options_selected.has(option):
		options_selected.erase(option)
		option.selected = false
		return
	if not num_choices:
		num_choices = Bus.map.current_location.num_reward_choices
	elif options_selected.size() < num_choices:
		options_selected.append(option)
		option.show_highlight(true)
		option.selected = true

func confirm():
	visible = false
	for option in options_selected:
		var card: Card = option.card
		Bus.deck.add_card(card.card_resource)
	leave()
	
func leave():
	kf.load_map()
