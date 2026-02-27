class_name Unit
extends Card

var current_slot: TokenSlot
var has_support: bool = false
# base values are used as the starting point when applying effects
var base_health: int
var base_damage: int
var base_shield: int
var base_activation: int
var current_health: int:
	set(val):
		current_health = clamp(val, 0, max_health)
		compare_stat("Health", current_health, max_health)
var max_health: int:
	set(val):
		max_health = max(0, val)
		compare_stat("Health", current_health, max_health)
var current_damage: int:
	set(val):
		current_damage = clamp(val, 0, max_damage)
		compare_stat("Damage", current_damage, max_damage)
var max_damage: int:
	set(val):
		max_damage = max(0, val)
		compare_stat("Damage", current_damage, max_damage)
var current_shield: int:
	set(val):
		current_shield = clamp(val, 0, max_shield)
		if current_shield <= 0:
			max_shield = 0
		compare_stat("Shield", current_shield, max_shield)
var max_shield: int:
	set(val):
		max_shield = max(0, val)
		compare_stat("Shield", current_shield, max_shield)
var current_activation: int:
	set(val):
		current_activation = clamp(val, 0, max_activation)
		compare_stat("Activation", current_activation, max_activation)
var max_activation: int:
	set(val):
		max_activation = max(0, val)
		compare_stat("Activation", current_activation, max_activation)
		if label:
			label.max_activation = max_activation
var current_fatigue: int:
	set(val):
		current_fatigue = clamp(val, 0, 10)
		compare_stat("Fatigue", current_fatigue, current_fatigue)
var items: Array[Item]
var snapshot_max_damage: int
var snapshot_current_damage: int
var snapshot_max_health: int
var snapshot_current_health: int
var snapshot_max_shield: int
var snapshot_current_shield: int
var setup_complete: bool = false

func class_setup():
	add_to_group("Units")
	setup_stats()
	has_support = card_resource.has_support
	if self is not CardToken:
		%SkillBox.add_tags()

func setup_stats():
	for stat in ['health', 'damage', 'shield', 'activation']:
		set("base_%s"%stat, card_resource.get(stat))
		set("max_%s"%stat, card_resource.get(stat))
		set("current_%s"%stat, card_resource.get(stat))
	current_fatigue = card_resource.fatigue
	refresh_stats_labels()
	if current_shield > 0 and pop:
		pop.create_keyword_popup("Shield")
	setup_complete = true
	
func move_to(target: Control, animation: bool = true):
	if target is TokenSlot:
		await play_token(target, animation)
	else:
		await super.move_to(target, animation)

func play_token(target: TokenSlot, animation: bool = true):
	if card_owner == "Enemy":
		if tween:
			tween.kill()
	if card_owner == "Player":
		if (current_activation > Bus.energy and get_tree().current_scene is Combat):
			return
		Audio.play_sfx("TrumpetCall")
		Bus.energy -= current_activation
	set_flip_card(true)
	scale = Vector2.ONE
	var old_pos: Vector2 = global_position
	token.reset_remaining()
	if token.get_parent():
		if token.get_parent() == self:
			remove_child(token)
	get_parent().remove_child(self)
	token.add_child(self)
	token.global_position = old_pos
	visible = false
	var mouse_position: bool = (card_owner == "Player")
	token.move_to(target, animation, mouse_position)
	ee.emit_signal("play", token)
	disabled = true
	$Area2D/CollisionShape2D.disabled = true
	rotation = 0
	z_index = 15
	position = Vector2(Bus.token_size.x + 10, -(Bus.card_size.y - Bus.token_size.y) / 2)
	if label:
		label.global_position = token.global_position
	
## card sets stats to max value, token to current value
func compare_stat(property: String, _current_value: int, max_value: int):
	tween_text(property, max_value)
	
func tween_text(property: String, new_amt: int):
	var text_label: Label = get_node("%" + "%sText"%property)
	if not setup_complete:
		text_label.text = str(new_amt)
		if property == "Fatigue" and self is not CardToken:
			text_label.set("theme_override_colors/font_color", Color.BLACK)
		else:
			text_label.set("theme_override_colors/font_color", Color.WHITE)
		return
	var start_amt = int(text_label.text)
	if start_amt == new_amt:
		return
	var color: Color = Color.FIREBRICK
	if start_amt < new_amt:
		color = Color.SEA_GREEN
	text_label.set("theme_override_colors/font_color", color)
	var callable = Callable.create(self, "set_%s_text" % property)
	var text_tween = create_tween()
	text_tween.tween_method(callable, start_amt, new_amt, kf.tween_time)
	await text_tween.finished
	if property == "Fatigue" and self is not CardToken:
		text_label.set("theme_override_colors/font_color", Color.BLACK)
	else:
		text_label.set("theme_override_colors/font_color", Color.WHITE)
	
func set_Health_text(value: int) -> void:
	%HealthText.text = str(value)
	
func set_Damage_text(value: int) -> void:
	%DamageText.text = str(value)
	
func set_Shield_text(value: int) -> void:
	%ShieldText.text = str(value)
	
func set_Activation_text(value: int) -> void:
	%ActivationText.text = str(value)
	
func set_Fatigue_text(value: int) -> void:
	%FatigueText.text = str(value)
	
func refresh_stats_labels():
	compare_stat("Health", current_health, max_health)
	compare_stat("Damage", current_damage, max_damage)
	compare_stat("Shield", current_shield, max_shield)
	compare_stat("Fatigue", current_fatigue, current_fatigue)

	compare_stat("Activation", current_activation, max_activation)
	check_act()
	
func check_act():
	return(can_act)

func set_highlight_color(_color: Color) -> void:
	pass
	
func revert_to_snapshot() -> void:
	can_act = snapshot_can_act
	visible = snapshot_visible
	disabled = snapshot_disabled
	if snapshot_parent != get_parent():
		get_parent().remove_child(self)
		snapshot_parent.add_child(self)
	max_damage = token.snapshot_max_damage
	current_damage = token.snapshot_current_damage
	max_health = token.snapshot_max_health
	current_health = token.snapshot_current_health
	max_shield = token.snapshot_max_shield
	current_shield = token.snapshot_current_shield

func _get_drag_data(_at_position: Vector2):
	if card_owner == "Enemy" or not can_act or disabled:
		return null
	if (get_tree().current_scene is Combat and current_activation > Bus.energy
			and self is not CardToken):
		return null
	if self is CardToken and not can_act:
		return null
	if Bus.Board:
		if Bus.Board.combat_over:
			return
	Audio.play_sfx("CardFlick")
	visible = false
	kf.dragging = self
	focus_in_hand(false)
	set_highlight(false)
	
	if current_slot:
		if current_slot.occupied_unit:
			if current_slot.occupied_unit == self:
				current_slot.occupied_unit = null

	var control = Control.new()
	var preview: Control
	if self is CardToken:
		preview = self.duplicate(false)
	else:
		preview = token.duplicate(false)
	preview.visible = true
	preview.get_node("Frame/Previews").visible = false
	preview.get_node("CardArt/Skull").visible = false
	control.add_child(preview)
	control.z_index = 999
	preview.position = -0.5 * preview.size
	set_drag_preview(control)
	return self

func _notification(notification_type):
	match notification_type:
		NOTIFICATION_DRAG_END:
			if kf.dragging:
				if kf.dragging == self:
					kf.dragging = null
					visible = true
					position = Vector2(0, 0)
					if current_slot:
						# If the slot thinks it's holding someone else (or no one),
						# and we haven't been successfully placed elsewhere (which would update current_slot),
						# then we need to force our way back in.
						if current_slot.occupied_unit != self:
							# Re-add ourselves to the slot officially
							current_slot.add_token(self)
