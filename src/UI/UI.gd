class_name UI
extends TextureRect

#@onready var boon_tooltip = preload("uid://cffwny47g72jv")

@onready var gold = %goldAmt
@onready var mana = %manaAmt
@onready var food = %foodAmt
@onready var spell_power = %spell_powerAmt
@onready var population = %PopulationAmt

func _ready() -> void:
	Bus.ui = self
	Bus.currency_changed.connect(update_currency)
	Bus.board_loaded.connect(on_combat)
	Bus.update_amounts.connect(update_amounts)
	update_amounts()
	#add_boons()
	setup_tooltips()
	
func update_amounts():
	set_gold_text(Bus.gold)
	set_mana_text(Bus.mana)
	set_spell_power_text(Bus.spell_power)
	set_food_text(Bus.food)
	
func update_currency(currency: String, new_amt: int, change: int) -> void:
	if change == 0:
		return
	var tween = create_tween()
	var color_dict := {"gold": {"up": Color.GOLD, "down": Color.FIREBRICK},
					"mana": {"up": Color.BLUE, "down": Color.FIREBRICK},
					"food": {"up": Color.SADDLE_BROWN, "down": Color.FIREBRICK},
					"spell_power": {"up": Color.FIREBRICK, "down": Color.YELLOW}}
	var direction: String = "up"
	if change < 0:
		direction = "down"
	var color: Color = color_dict[currency][direction]
	get(currency).set("theme_override_colors/font_color", color)
	var callable = Callable.create(self, "set_%s_text" % currency)
	tween.tween_method(callable, new_amt - change, new_amt, .5)
	await tween.finished
	get(currency).set("theme_override_colors/font_color", Color.WHITE)
	
func set_gold_text(value: int) -> void:
	gold.text = str(value)

func set_mana_text(_value: int) -> void:
	mana.text = "%s / %s"%[Bus.mana, Bus.player.max_mana]
	
func set_spell_power_text(value: int) -> void:
	spell_power.text = str(value)
	
func set_food_text(value: int) -> void:
	food.text = str(value)
	
func update_population():
	population.text = str(Bus.player.deck.get_units().size())
	
func on_combat() -> void:
	#$DropButton.visible = false
	pass

#func add_boons() -> void:
	#for boon in Bus.player.boons:
		#var tooltip = boon_tooltip.instantiate()
		#tooltip.boon = boon
		#$Boons/HBoxContainer.add_child(tooltip)

func toggle_deck():
	var deck_visible = Bus.PlayerDeck.visible
	Bus.PlayerDeck.visible = not deck_visible
	$ToggleDeck/Deck/EyeOpen.visible = deck_visible
	$ToggleDeck/Deck/EyeClosed.visible = not deck_visible

func setup_tooltips():
	for stat in ["Mana", "Power", "Gold"]:
		get_node("Tooltips/%sArea"%stat).mouse_entered.connect(show_tooltip.bind(stat))
		get_node("Tooltips/%sArea"%stat).mouse_exited.connect(hide_tooltip.bind(stat))
		get_node("Tooltips/%s_tip"%stat).setup()
		
func show_tooltip(stat: String):
	get_node("Tooltips/%s_tip"%stat).visible = true
	
func hide_tooltip(stat: String):
	get_node("Tooltips/%s_tip"%stat).visible = false
