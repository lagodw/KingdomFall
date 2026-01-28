class_name Combat
extends Control

@onready var draw_pile: Pile = $Draw
@onready var discard_pile: Pile = $Discard
@onready var energy_txt: Label = $Energy/EnergyText

var turn_counter: int = 0
var combat_happening: bool = false
var combat_over: bool = false
var army: Array[CardResource]

func _ready() -> void:
	Bus.Board = self
	Bus.draw = draw_pile
	Bus.discard = discard_pile
	$ArmyChoice/RestPanel.load_units(Bus.deck.cards)
	$EndTurn.pressed.connect(end_turn)
	Bus.energy_changed.connect(update_energy)
	Bus.energy = 3
	$%ConfirmArmy.pressed.connect(start_combat)
	get_tree().paused = true
	$ArmyChoice.visible = true

func end_turn():
	await Bus.Grid.start_combat()
	$Enemy.on_turn_start(turn_counter)
	await Bus.hand.discard()
	draw_pile.draw_cards(5)
	Bus.energy = 3
	update_energy()
	ee.emit_signal("start_turn", turn_counter)
	turn_counter += 1

func update_energy():
	energy_txt.text = str(Bus.energy)

func game_over():
	combat_over = true
	$GameOver.appear()

func start_combat():
	for card: Card in $ArmyChoice/FightPanel.box.get_children():
		army.append(card.card_resource)
		var old_pos: Vector2 = card.global_position
		card.get_parent().remove_child(card)
		add_child(card)
		card.global_position = old_pos
		card.move_to(draw_pile.cards)
	
	$ArmyChoice.visible = false
	get_tree().paused = false
		
	await get_tree().create_timer(kf.tween_time * 1.5).timeout
	draw_pile.shuffle()
	end_turn()
