extends Button

@onready var highlight: Panel = $Highlight

var card: Unit
var selected: bool = false

func _ready() -> void:
	mouse_entered.connect(show_highlight.bind(true))
	mouse_exited.connect(show_highlight.bind(false))

func show_highlight(value: bool):
	highlight.visible = (value or selected)

func select():
	selected = true
	show_highlight(true)
