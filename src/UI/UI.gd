class_name UI
extends Control

#@onready var boon_tooltip = preload("uid://cffwny47g72jv")

@onready var gold = %goldAmt
@onready var wood = %woodAmt
@onready var stone = %stoneAmt
@onready var food = %foodAmt
@onready var mana = %manaAmt
@onready var spell_power = %spell_powerAmt
@onready var population = %PopulationAmt

@onready var gold_chg = %goldChange
@onready var wood_chg = %woodChange
@onready var stone_chg = %stoneChange
@onready var food_chg = %foodChange

var gold_change: int:
	set(val):
		gold_change = val
		if val >= 0:
			gold_chg.text = "(+%s)"%val
			set_font_color(gold_chg, color_dict["gold"]["up"])
		else:
			gold_chg.text = "(%s)"%val
			set_font_color(gold_chg, color_dict["gold"]["down"])
		gold_chg.visible = val != 0
var wood_change: int:
	set(val):
		wood_change = val
		if val >= 0:
			wood_chg.text = "(+%s)"%val
			set_font_color(wood_chg, color_dict["wood"]["up"])
		else:
			wood_chg.text = "(%s)"%val
			set_font_color(wood_chg, color_dict["wood"]["down"])
		wood_chg.visible = val != 0
var stone_change: int:
	set(val):
		stone_change = val
		if val >= 0:
			stone_chg.text = "(+%s)"%val
			set_font_color(stone_chg, color_dict["stone"]["up"])
		else:
			stone_chg.text = "(%s)"%val
			set_font_color(stone_chg, color_dict["stone"]["down"])
		stone_chg.visible = val != 0
var food_change: int:
	set(val):
		food_change = val
		if val >= 0:
			food_chg.text = "(+%s)"%val
			set_font_color(food_chg, color_dict["food"]["up"])
		else:
			food_chg.text = "(%s)"%val
			set_font_color(food_chg, color_dict["food"]["down"])
		food_chg.visible = val != 0

@onready var color_dict := {"gold": {"up": Color.GOLD, "down": Color.FIREBRICK},
					"wood": {"up": Color.SADDLE_BROWN, "down": Color.FIREBRICK},
					"stone": {"up": Color.WEB_GRAY, "down": Color.FIREBRICK},
					"mana": {"up": Color.BLUE, "down": Color.FIREBRICK},
					"food": {"up": Color.SADDLE_BROWN, "down": Color.FIREBRICK},
					"spell_power": {"up": Color.FIREBRICK, "down": Color.YELLOW}}

func _ready() -> void:
	Bus.ui = self
	Bus.currency_changed.connect(update_currency)
	Bus.board_loaded.connect(on_combat)
	Bus.update_amounts.connect(update_amounts)
	ee.card_added_to_deck.connect(update_population)
	%DayCount.text = str(Bus.map.day_counter)
	update_amounts()
	#add_boons()
	setup_tooltips()
	
func update_amounts():
	set_gold_text(Bus.gold)
	set_mana_text(Bus.mana)
	set_wood_text(Bus.wood)
	set_stone_text(Bus.stone)
	set_spell_power_text(Bus.spell_power)
	set_food_text(Bus.food)
	update_population()
	
func update_currency(currency: String, new_amt: int, change: int) -> void:
	if change == 0:
		return
	var tween = create_tween()
	var direction: String = "up"
	if change < 0:
		direction = "down"
	var color: Color = color_dict[currency][direction]
	set_font_color(get(currency), color)
	var callable = Callable.create(self, "set_%s_text" % currency)
	tween.tween_method(callable, new_amt - change, new_amt, .5)
	await tween.finished
	set_font_color(get(currency), Color.WHITE)
	
func set_gold_text(value: int) -> void:
	gold.text = str(value)
	
func set_wood_text(value: int) -> void:
	wood.text = str(value)
	
func set_stone_text(value: int) -> void:
	stone.text = str(value)
	
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
	for stat in ["Mana", "Power", "Gold", "Wood", "Stone", "Food", "Population"]:
		get_node("Tooltips/%sArea"%stat).mouse_entered.connect(show_tooltip.bind(stat))
		get_node("Tooltips/%sArea"%stat).mouse_exited.connect(hide_tooltip.bind(stat))
		get_node("Tooltips/%s_tip"%stat).setup()
		
func show_tooltip(stat: String):
	get_node("Tooltips/%s_tip"%stat).visible = true
	
func hide_tooltip(stat: String):
	get_node("Tooltips/%s_tip"%stat).visible = false

func set_font_color(node: Control, color: Color):
	node.set("theme_override_colors/font_color", color)
