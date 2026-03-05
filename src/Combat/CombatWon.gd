extends CanvasLayer

@onready var button_scene: PackedScene = load("uid://7iyrp623m11p")
@onready var currency_button: PackedScene = load("uid://dq3csefpupvgr")
@onready var card_grid: HBoxContainer = $Control/CardChoices

var choices: Array[UnitResource]
var card_option_selected: Button

func setup() -> void:
	create_cards()
	$Control/Confirm.pressed.connect(confirm)
	for currency in ["gold", "wood", "stone"]:
		var button = currency_button.instantiate()
		button.currency_type = currency
		button.amt = Bus.map.current_location.get("%s_amt"%currency)
		button.pressed.connect(choose_currency.bind(currency))
		button.setup()
		%CurrencyChoices.add_child(button)
	
func confirm():
	visible = false
	get_tree().paused = false
	Bus.deck.add_card(card_option_selected.card.card_resource)
	kf.load_scene("uid://djtcf3x2wg721")

func create_cards() -> void:
	for option in choices:
		var button = button_scene.instantiate()
		var card = kf.create_card(option)
		card_grid.add_child(card)
		card.disabled = true
		card.add_child(button)
		button.card = card
		button.pressed.connect(option_pressed.bind(button))

func option_pressed(option: Button) -> void:
	if card_option_selected:
		card_option_selected.selected = false
		card_option_selected.show_highlight(false)
	card_option_selected = option
	card_option_selected.show_highlight(true)
	card_option_selected.selected = true

func choose_currency(currency_type: String):
	match currency_type:
		"gold":
			Bus.gold += Bus.map.current_location.gold_amt
		"wood":
			Bus.wood += Bus.map.current_location.wood_amt
		"stone":
			Bus.stone += Bus.map.current_location.stone_amt
	%CurrencyChoices.visible = false
