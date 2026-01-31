class_name Card
extends Control

@onready var targeting_arrow: TargetingArrow = $TargetLine
@onready var frame_rect: TextureRect = %Frame

@export var card_resource: CardResource
var token: CardToken
var label: CardLabel

var pop: VBoxContainer
var popup_hover_time := 1.0
var animation_path := ""
var card_art: String
var tween: Tween
var effects: Array[Effect] = []
#var delayed_effects: Array[DelayedEffect] = []
var targeting := false
var disabled := false
var highlighted := false

@export_enum("Player", "Enemy") var card_owner := "Player"
var card_type: String
var card_name: String

var can_act := true:
	set(val):
		can_act = val
		update_bg_color()
var act_disabled := false
var tags := []
#var attachments: Dictionary[CardLabel, VBoxContainer] = {} # not working
var attachments: Dictionary = {}
var effect_length: int

var snapshot_can_act: bool = true
var snapshot_act_disabled: bool = false
var snapshot_parent: Control
var snapshot_visible: bool
var snapshot_disabled: bool

func _ready():
	if card_resource:
		setup_card()
	
###########################################################
########################## SETUP ##########################
###########################################################
# setup card text based on data from definition script
func setup_card():
	common_setup()
	type_only_setup()
	class_setup()
	update_bg_color()
	custom_card_setup()
	
func common_setup():
	card_name = card_resource.card_name
	if card_name:
		name = card_name
	%Name.text = card_name
	%Shadow.text = card_name
	kf.fit_font_size(%Name)
	kf.fit_font_size(%Shadow)
	set_art()
	for tag in card_resource.tags:
		tags.append(tag)
	card_type = card_resource.card_type
	for effect in card_resource.effects:
		effects.append(effect.dupe())
	Bus.trigger_occurred.connect(on_trigger_occurred)
	ee.start_turn.connect(on_turn_start)
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)
	Bus.take_snapshot.connect(take_snapshot)
	Bus.restart_turn.connect(revert_to_snapshot)
	
func on_turn_start(_turn_num: int):
	set_act(true)
	
func on_currency_change(currency: String, _old_amt: int, _change: int):
	if currency == "spell_power":
		set_card_text()
		
## different for Card vs CardToken
func type_only_setup():
	%ActivationText.text = str(card_resource.activation)
	set_card_text()
	if "[+sp]" in card_resource.text:
		add_to_group("SpellPowerCards")
	pop = %PopupContainer
	add_tag_icons()
	fit_text()
	create_token()
	pop.create_popups()
	Bus.new_scene_loaded.connect(move_popups)
	
func custom_card_setup():
	if card_resource.custom_startup_script:
		if card_resource.custom_startup_script.has_method("setup"):
			card_resource.custom_startup_script.setup(self)
	
	# move it to current scene to prevent clipping from containers
	# and to avoid having to add and drop child
func move_popups():
	pop.get_parent().remove_child(pop)
	get_tree().current_scene.call_deferred("add_child", pop)
	
func set_card_text():
	var sp_text = ""
	if Bus.spell_power > 0:
		sp_text = " (+%s)"%Bus.spell_power
	# might not have loaded yet
	if has_node("%CardText"):
		%CardText.text = card_resource.text.replace("[+sp]", sp_text)

func add_tag_icons():
	%Tags.add_tags()

## placeholder for additional class specific setup
func class_setup():
	pass
	
func create_token():
	if self is not Unit or disabled:
		return
	token = kf.create_token(card_resource, card_owner)
	token.visible = false
	token.card = self
	token.z_index = 2
	token.label = label
	add_child(token)
	
func set_art(override: String = ""):
	card_art = card_name
	if override != "":
		card_art = override
	elif card_resource.card_art_path:
		card_art = card_resource.card_art_path
	#elif Settings:
		#if Settings.card_art.has(card_name):
			#card_art = Settings.card_art[card_name]
	var art_path = "res://assets/CardArt/" + card_name + "/" + card_art + ".png"
	%CardArt.texture = load(art_path)
		
func fit_text():
	kf.fit_font_size(%CardText)
	kf.fit_font_size(%Name)

func flip_card():
	$Front.visible = not $Front.visible
	$Back.visible = not $Back.visible
	
func set_flip_card(value: bool):
	$Front.visible = value
	$Back.visible = not value
	
func show_popups(value: bool = true, left_side: bool = false):
	if not $Front.visible:
		value = false
	pop.show_tooltips(value)
	
	# avoid error in get_viewport_rect()
	if not value or not is_inside_tree():
		return
	
	pop.global_position.x = global_position.x + 10 + Bus.card_size.x * scale.x
	# if popups are cut off of screen, move to left of card
	if pop.global_position.x + pop.size.x > 1920 or left_side:
		pop.global_position.x = global_position.x - 10 - pop.size.x
	pop.global_position.y = min(global_position.y, get_viewport_rect().size.y - pop.size.y - 10)
	
func move_to(target: Control, animation: bool = true):
	var old_pos: Vector2 = global_position
	if animation:
		global_position = old_pos
		reset_tween()
		tween.tween_property(self, "global_position", target.global_position, kf.tween_time)
		await tween.finished
	if get_parent():
		get_parent().remove_child(self)
	target.add_child(self)
	position = Vector2(0, 0)


func _on_mouse_enter():
	show_popups()
	# don't do anything is another card is targeting
	if ((kf.mouse_disabled and not $TargetLine.is_targeting) or (not visible)):
		return
	if get_parent() == Bus.hand and not kf.dragging:
		get_parent().set_card_focus(self, true)
	if not kf.dragging and card_owner == "Player":
		set_highlight(true)
	
func _on_mouse_exit():
	show_popups(false)
	
	if get_parent() == Bus.hand:
		get_parent().set_card_focus(self, false)
	
	if ((kf.mouse_disabled and not $TargetLine.is_targeting) or (
		not visible)):
		return
	
	set_highlight(false)

func set_highlight(status: bool):
	$Highlight.visible = status
	highlighted = status

## scale the card up but keep it centered in same spot
func focus_in_hand(value):
	var card_scale
	if value:
		card_scale = 1.5
	else:
		card_scale = 1.0
	
	pivot_offset = Vector2(size.x / 2, size.y)
	set_scale(Vector2(card_scale, card_scale))
	
## replace the card with a label but keep the original card hidden
## this is used in board effects and attachments and discard
func turn_to_label() -> CardLabel:
	var old_pos = global_position
	var scene = get_tree().current_scene
	scale = Vector2.ONE
	visible = false
	disabled = true
	label.visible = true
	label.get_parent().remove_child(label)
	if get_parent():
		get_parent().remove_child(self)
	if token:
		token.get_parent().remove_child(token)
		add_child(token)
		token.visible = false
	label.add_child(self)
	scene.add_child(label)
	label.global_position = old_pos
	return(label)

func tween_to_player_deck() -> void:
	var pos = global_position
	turn_to_label()
	label.global_position = pos
	reset_tween()
	tween.tween_property(label, "global_position", 
			Bus.PlayerDeck.global_position, kf.tween_time)
	await tween.finished
	label.get_parent().remove_child(label)
	Bus.PlayerDeck.cards.add_child(label)
	
func attach_to_card(target: CardToken):
	# Apply effects
	for effect in effects:
		if effect.trigger_signal != "attach":
			continue
		effect.host_card = target

		# Register UI tooltip on target
		target.card.register_attachment(effect, self)
	if self is Item:
		target.combat_modifiers.append_array(card_resource.combat_modifiers)
		target.items.append(self)
	discard()
	ee.emit_signal("attach", self, target)
	
func register_cost_modifier(amount: int):
	if label:
		label.register_cost_modifier(amount)
	
func register_attachment(effect: Effect, source_card: Card):
	var tool: Tooltip = R.tooltip.instantiate()
	tool.title = source_card.card_resource.card_name
	tool.description = source_card.card_resource.text
	if source_card is Item:
		tool.Damage = source_card.damage
		tool.Health = source_card.health
		tool.Shield = source_card.shield
	
	# We need to get the icon. If source_card has Art node with texture:
	var art_node = source_card.get_node_or_null("%CardArt")
	if art_node and art_node.texture:
		tool.icon_path = art_node.texture.resource_path
	elif source_card.card_resource.card_art_path:
		tool.icon_path = "res://assets/CardArt/" + source_card.card_resource.card_name + "/" + source_card.card_resource.card_art_path + ".png"
		
	pop.call_deferred("add_child", tool)
	attachments[effect] = tool

func add_keyword_popup(keyword: String, num: int = 0) -> Control:
	return(pop.create_keyword_popup(keyword, num))

func board_effect(dest):
	var slot = dest.get_next_free_slot()
	if not slot:
		dest.add_slots(1)
		slot = dest.get_next_free_slot()
	turn_to_label()
	label.set_flip_card(true)
	scale = Vector2(1, 1)
	# wait 1 frame so target position is set correctly
	await get_tree().process_frame
	label.move_to(slot)
	
func discard():
	# signal has to be here since effect could be tied to card
	ee.emit_signal("discard", self)
	# prevent arrow from targeting as card is being discarded
	disabled = true
	# could already be turned to label if board effect
	#if get_parent() != label:
		#turn_to_label()
	#label.discard()
	queue_free()
	
## reset a card's act ability
## used in spells to gray out non castable
func set_act(status: bool):
	if act_disabled:
		can_act = false
	else:
		can_act = status
	#update_bg_color()
	
func get_bg_color() -> String:
	var color_name: String
	if not can_act:
		color_name = "NoAct"
	else:
		if card_type == "Unit":
			if card_owner == "Player":
				return("Blue")
			else:
				return("Red")
		color_name = card_type
	return(kf.color_map[color_name])

func update_bg_color():
	var bg_color = get_bg_color()
	var frame = "res://assets/Card/Frames/CardFrame_%s.png"%bg_color
	frame_rect.texture = load(frame)
	if self is not CardToken:
		var box = "res://assets/Card/Frames/TagBox_%s.png"%bg_color
		%TagFrame.texture = load(box)

func disable_act(status):
	act_disabled = status
	if act_disabled:
		set_act(false)
		
############################################################
########################## EFFECTS #########################
############################################################
func get_trigger_effects(trigger: String) -> Array[Effect]:
	var valid_effects: Array[Effect] = []
	for effect in effects:
		if effect.trigger_signal != trigger:
			continue
		if ee.check_conditions_calling(self, self, effect.conditions_calling):
			valid_effects.append(effect)
	return(valid_effects)

func on_trigger_occurred(trigger: String, trigger_card: Control) -> void:
	# unit effects should only be done by tokens
	# probably a better way to do this but use hacky solution for now
	if self is Unit and self is not CardToken: 
		return
	if trigger == "discard":
		if trigger_card is Card:
			if attachments.has(trigger_card.label):
				attachments[trigger_card.label].queue_free()
				attachments.erase(trigger_card.label)

func take_snapshot() -> void:
	snapshot_can_act = can_act
	snapshot_act_disabled = act_disabled
	snapshot_parent = get_parent()
	snapshot_visible = visible
	snapshot_disabled = disabled

func revert_to_snapshot() -> void:
	can_act = snapshot_can_act
	act_disabled = snapshot_act_disabled
	visible = snapshot_visible
	disabled = snapshot_disabled
	if snapshot_parent != get_parent():
		get_parent().remove_child(self)
		snapshot_parent.add_child(self)

func reset_tween():
	if tween:
		tween.kill()
	tween = create_tween()

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return(false)
