class_name CardLabel
extends Control

@export var card_resource: CardResource
var activated: bool = false
var drawn: bool = false
var disabled: bool = false
var base_activation: int = 2:
	set(val):
		base_activation = max(0, val)
var max_activation: int = 2
var current_activation: int = 2
var activation_progress: int = 0
var card_type: String = "Unit"
var card_owner: String = "Player"
var preview_card: Card
var card_name: String
var tags: Array[kf.Tag] = []
var snapshot_activation: int
var snapshot_visible: bool
var snapshot_activated: bool
var snapshot_parent: Control

var base_cost: int = 0
var current_cost: int = 0:
	set(val):
		current_cost = max(0, val)
		update_cost_display()

var cost_modifiers: Array[int] = []
var activation_modifiers: Array[int] = []

func _ready():
	if card_resource:
		setup_card()
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)
	
	Bus.turn_starting.connect(on_start_turn)
	Bus.effects_finished.connect(on_effects_finished)
	Bus.take_snapshot.connect(take_snapshot)
	Bus.restart_turn.connect(revert_to_snapshot)
	
func setup_card():
	card_name = card_resource.card_name
	if card_name:
		name = card_name
	%Name.text = card_name
	%Shadow.text = card_name
	kf.fit_font_single_line(%Name, 20)
	kf.fit_font_single_line(%Shadow, 20)
	%ActivationText.text = str(card_resource.activation)
	base_activation = card_resource.activation
	max_activation = base_activation
	current_activation = base_activation
	card_type = card_resource.card_type
	tags = card_resource.tags
	update_bg_color()
	update_bg_color()
	if card_resource is UnitResource:
		%Cost.texture = load("uid://dbr0f8hb1g31b")
		base_cost = card_resource.fatigue
		current_cost = base_cost
	elif card_resource is SpellResource:
		%Cost.texture = load("uid://bithkfa0yaj55")
		base_cost = card_resource.mana_cost
		current_cost = base_cost
	elif card_resource is ItemResource:
		%Cost.texture = load("uid://dkteqdm5uvadh")
		if card_resource.tags.has(kf.Tag.Indestructible):
			%CostText.text = ""
		else:
			base_cost = card_resource.current_durability
			current_cost = base_cost
	elif card_resource is BurdenResource or card_resource is ConsumeResource:
		%Cost.visible = false
	
	if not preview_card:
		create_preview_card()
	set_preview_location()
	preview_card.visible = false
	
func create_preview_card():
	preview_card = kf.create_card(card_resource)
	preview_card.card_owner = card_owner
	preview_card.label = self
	preview_card.z_index = 11
	add_child(preview_card)
	
func flip_card():
	$Front.visible = not $Front.visible
	$Back.visible = not $Back.visible
	preview_card.flip_card()
	preview_card.visible = not $Back.visible
	$Highlight.visible = preview_card.visible
	
func set_flip_card(value: bool):
	$Front.visible = value
	$Back.visible = not value
	preview_card.set_flip_card(value)

func set_highlight(status: bool):
	$Highlight.visible = status

## make sure card doesn't go off screen
func set_preview_location():
	preview_card.global_position = global_position + Vector2(Bus.label_size.x + 10, 0)
	preview_card.rotation = 0
	# if the preview card will extend beyond the right side of screen, show on left instead
	if global_position.x >= get_viewport_rect().size.x - 2*Bus.card_size.x - 10:
		preview_card.global_position = global_position + Vector2(-Bus.card_size.x - 10, 0)
	# if preview card will go below bottom of screen, set to end of screen
	if preview_card.global_position.y + Bus.card_size.y + 10 > get_viewport_rect().size.y:
		preview_card.global_position.y = get_viewport_rect().size.y - Bus.card_size.y - 10
	
func _on_mouse_enter():
	if kf.dragging:
		return
	set_highlight(true)
	show_preview_card(true)
		
func _on_mouse_exit():
	set_highlight(false)
	show_preview_card(false)
		
func show_preview_card(value: bool = true):
	preview_card.top_level = value
	preview_card.visible = value
	set_preview_location()
	var left_side: bool = false
	if preview_card.global_position.x < global_position.x:
		left_side = true
	preview_card.show_popups(value, left_side)

func _input(event):
	if card_owner == "Enemy" or drawn or disabled: 
		return
	if not $Highlight.visible or kf.mouse_disabled or not get_parent():
		return
	if event is InputEventMouseButton and event.is_pressed() and event.get_button_index() == 1:
		if get_parent().name == "Cards":
			if not activated:
				await(activate())
			else:
				await(deactivate())

## target is the node it will join
func move_to(target: Control, animation: bool = true):
	if animation:
		# move to scene so it doesn't get cut off while in scroll box
		var scene = get_tree().current_scene
		var old_pos = global_position
		get_parent().remove_child(self)
		scene.add_child(self)
		global_position = old_pos
		var tween = create_tween()
		tween.tween_property(self, "global_position", target.global_position, kf.tween_time)
		await tween.finished
	get_parent().remove_child(self)
	target.add_child(self)
	position = Vector2(0, 0)
	
func activate() -> bool:
	if not Bus.Board:
		return(false)
	if activated:
		return(false)
	if max_activation == 0:
		draw_card()
		return(true)
	var target = Bus.get(card_owner + "ActivatedCards").get_next_free_slot()
	if target:
		target.occupying_card = self
		activated = true
		await move_to(target)
		ee.emit_signal("activate", self)
		return(true)
	return(false)
	
func deactivate():
	#if current_activation < max_activation and not ignore_warning and Settings.warn_deactivate_progress:
		#Bus.Board.get_node("Warnings/DeactivateWarning").warn(self)
		#return
	get_parent().occupying_card = null
	var target = Bus.get(card_owner + 'Deck').cards
	activated = false
	move_to(target, false)
	current_activation = max_activation
	activation_progress = 0
	await get_tree().process_frame
	Bus.get(card_owner + "ActivatedCards").sort_labels()
	
func on_start_turn():
	if not activated or drawn:
		return
	advance_activation(1)

func advance_activation(turns: int):
	if drawn: return
	activation_progress = max(0, activation_progress + turns)
	calculate_current_activation()

func get_bg_color() -> String:
	return(kf.color_map[card_type])

func update_bg_color():
	var bg_color = get_bg_color()
	var frame = "res://assets/Card/Labels/CardLabel_%s.png"%bg_color
	%Frame.texture = load(frame)

func update_activation_text():
	%ActivationText.text = str(current_activation)
	if preview_card:
		preview_card.get_node("%ActivationText").text = str(max_activation)
		
func draw_card():
	drawn = true
	preview_card.position = Vector2(0, 0)
	current_activation = max_activation
	activation_progress = 0
	update_activation_text()
	if card_resource is BurdenResource or Bus.get(card_owner + "Hand").get_child_count() >= 10:
		ee.discard_card(preview_card)
	elif Bus.get(card_owner + "Hand").get_child_count() < 10:
		turn_to_card()
		Bus.get(card_owner + "Hand").draw_card(preview_card)
		ee.emit_signal("draw", preview_card)
	
func turn_to_card() -> void:
	var old_pos = global_position
	preview_card.visible = true
	if not preview_card:
		create_preview_card()
	remove_child(preview_card)
	if get_parent():
		var parent = get_parent()
		parent.remove_child(self)
		parent.add_child(preview_card)
	preview_card.global_position = old_pos
	preview_card.add_child(self)
	preview_card.z_index = 1
	visible = false
	preview_card.visible = true
	position = Vector2(0, 0)
	
func discard(animation: bool = true):
	visible = true
	activated = false
	drawn = false
	disabled = true
	# in case attached to token
	custom_minimum_size.x = Bus.label_size.x - 4
	set_flip_card(true)
	preview_card.visible = false
	set_highlight(false)
	await move_to(Bus.get(card_owner + "Discard"), animation)
	current_activation = max_activation
	update_activation_text()

func on_effects_finished():
	# Activation modifiers
	max_activation = base_activation
	for mod in activation_modifiers:
		max_activation += mod
	activation_modifiers.clear()

	# Cost Modifiers
	if card_resource is ItemResource:
		# Items are permanent changes so base cost is always current durability
		base_cost = card_resource.current_durability
	current_cost = base_cost
	for mod in cost_modifiers:
		current_cost += mod
	current_cost = max(0, current_cost)
	cost_modifiers.clear()
	
	calculate_current_activation()
	
func calculate_current_activation():
	if drawn:
		return
	current_activation = max_activation - activation_progress
	
	if current_activation <= 0 and activated and not drawn:
		draw_card()
	elif current_activation > max_activation:
		current_activation = max_activation
	update_activation_text()

func take_snapshot():
	snapshot_activation = current_activation
	snapshot_visible = visible
	snapshot_activated = activated
	snapshot_parent = get_parent()
	
func revert_to_snapshot():
	current_activation = snapshot_activation
	visible = snapshot_visible
	activated = snapshot_activated
	if snapshot_parent != get_parent():
		get_parent().remove_child(self)
		snapshot_parent.add_child(self)

func tween_to_deck():
	move_to(Bus.PlayerDeck.cards)

func register_activation_modifier(amount: int):
	activation_modifiers.append(amount)

func register_cost_modifier(amount: int):
	cost_modifiers.append(amount)

func update_cost_display():
	if card_resource is UnitResource:
		%CostText.text = str(current_cost)
	elif card_resource is SpellResource:
		%CostText.text = str(current_cost)
	elif card_resource is ItemResource:
		if card_resource.tags.has(kf.Tag.Indestructible):
			%CostText.text = ""
		else:
			%CostText.text = str(current_cost)
	if preview_card:
		preview_card.get_node("%CostText").text = %CostText.text
