class_name CardToken
extends Unit

var card: Unit
var current_job: Job
var discarded: bool = false
var effect_buffs: Array = []
var combat_modifiers: Array[CombatModifier] = []
var current_bonus_damage: int = 0 # Real Bonus Pool
var remaining_bonus_damage: int = 0 # Sim Bonus Pool
var remaining_base_damage: int = 0: # Sim Base Pool
	set(val):
		remaining_base_damage = val
		update_damage_preview()
var remaining_life: int = 0:
	set(val):
		remaining_life = val
		update_damage_preview()
## used to track preview damage
var poison: int = 0:
	set(val):
		if tags.has(kf.Tag.Undead):
			poison = 0
		else:
			poison = val
			poison_effect.damage_amt.number = poison
		update_damage_preview()
var poison_effect: Effect
var poison_popup: Control
var vulnerable_effect: CombatModifier
var vulnerable_popup: Control
var vulnerable: int = 0:
	set(val):
		vulnerable = val
		vulnerable_effect.value.number = vulnerable
		update_damage_preview()
var feeble_effect: CombatModifier
var feeble_popup: Control
var feeble: int = 0:
	set(val):
		feeble = val
		feeble_effect.value.number = -feeble
		update_damage_preview()
var snapshot_poison: int
var snapshot_vulnerable: int
var snapshot_feeble: int
var attacked_this_turn: bool = false
var recalculating_stats: bool = false
var _cached_damage_taken: int = -1
var _cached_shield_damage_taken: int = -1
var assigned_breach_damage: int = 0

func set_fatigue(val):
	current_fatigue = clamp(val, 0, 10)
	if card:
		card.current_fatigue = current_fatigue
	card_resource.fatigue = current_fatigue
	compare_stat("Fatigue", current_fatigue, current_fatigue)

func type_only_setup():
	add_to_group("Tokens")
	reset_remaining()
	Bus.effects_finished.connect(on_effects_finished)
	for curse in card_resource.curses:
		# need deferred so card ready doesn't override stats
		curse.call_deferred("register", self)
	poison_effect = load("uid://bbrcqb4snqdfe").dupe()
	vulnerable_effect = load("uid://0gbxtn83ia3d").duplicate(true)
	feeble_effect = load("uid://d28pv07bwhpva").duplicate(true)
	for modifier in card_resource.combat_modifiers:
		combat_modifiers.append(modifier)
	combat_modifiers.append(vulnerable_effect)
	combat_modifiers.append(feeble_effect)
	effects.append(poison_effect)
	add_animation()
	for effect in effects:
		effect.connect_signal(self)
	
func set_art(override: String = ""):
	card_art = card_name
	if override != "":
		card_art = override
	elif card_resource.card_art_path:
		card_art = card_resource.card_art_path
	elif Settings:
		if Settings.card_art.has(card_name):
			card_art = Settings.card_art[card_name]
	var art_path = "res://assets/CardArt/" + card_name + "/" + card_art + ".png"
	
	%CardArt.texture = load(art_path)
	if card:
		card.set_art(card_art)
		
func add_animation():
	var path
	if animation_path:
		path = animation_path
	elif Settings:
		if Settings.animations.has(card_name):
			var anim_name = Settings.animations[card_name]
			path = "res://src/Animations/Attack/" + anim_name + ".tscn"
		else:
			path = "res://src/Animations/Attack/%s.tscn"%card_resource.default_animation
	else:
		path = "res://src/Animations/Attack/%s.tscn"%card_resource.default_animation
	var anim = load(path).instantiate()
	add_child(anim)
	
func add_tag_popup(tag: kf.Tag):
	card.add_tag_popup(tag)

func update_bg_color():
	var bg_color = get_bg_color()
	var frame = "res://assets/Card/Tokens/CardToken_%s.png"%bg_color
	%Frame.texture = load(frame)
		
func _process(_delta):
	#z_index = 0
	if kf.dragging == self:
		z_index = 10
		rotation = 0
		global_position = get_global_mouse_position() - size/2
	elif kf.dragging:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP
		
func on_turn_start(_turn_num: int, turn_owner: String):
	if not current_slot or current_health <= 0: return
	if card_owner == turn_owner:
		set_act(true)
	if max_shield > 0:
		current_shield = max_shield
	remaining_base_damage = current_damage
	attacked_this_turn = false
	
func set_percent(percentage: float) -> void:
	%CardArt.material.set_shader_parameter('percentage', percentage)
	
func turn_to_label() -> CardLabel:
	var old_pos = global_position
	label = card.turn_to_label()
	label.global_position = old_pos
	return(label)
	
func turn_to_card() -> Unit:
	if current_slot:
		current_slot.clear_unit()
		current_slot = null
	var parent = get_parent()
	if card.get_parent():
		card.get_parent().remove_child(card)
	if get_parent():
		get_parent().remove_child(self)
	card.visible = true
	card.disabled = false
	visible = false
	card.add_child(self)
	position = Vector2.ZERO
	parent.add_child(card)
	return(card)
	
func discard():
	discarded = true
	if current_slot:
		if current_slot.occupied_unit == self:
			current_slot.clear_unit()
		current_slot = null
	Audio.play_sfx("Death")
	ee.emit_signal("discard", self)
	# prevent arrow from targeting as card is being discarded
	disabled = true
	turn_to_card()
	if card_owner == "Enemy":
		Bus.get("%sGraveyard"%card_owner).add_card(card)
	else:
		current_health = max_health
		current_fatigue += 5
		Bus.discard.add_card(card)
	
func take_damage(dmg = 0, damaging_card: Card = null, blocked_by_shield: bool = true):
	if disabled:
		return
	var shield_dmg = min(dmg, current_shield)
	if not blocked_by_shield:
		shield_dmg = 0
	current_shield -= shield_dmg
	var remaining_dmg = dmg - shield_dmg
	current_health -= remaining_dmg
	if remaining_dmg > 0:
		ee.emit_signal("damage_taken", self, remaining_dmg)
	if current_health <= 0:
		current_health = 0
		refresh_stats_labels()
		ee.emit_signal("unit_killed", self, damaging_card)
		ee.emit_signal("killing_blow", damaging_card, self)
		ee.discard_card(self)
	else:
		refresh_stats_labels()

func show_popups(value: bool = true, _left_side: bool = false):
	if card:
		card.global_position = global_position + Vector2(Bus.token_size.x + 10, 
				-(Bus.card_size.y - Bus.token_size.y) / 2) # center wrt token
		
		card.global_position.y = min(card.global_position.y, get_viewport_rect().size.y - card.size.y)
		card.global_position.y = max(card.global_position.y, Bus.ui.size.y)
		
		card.z_index = 3
		card.visible = value
		card.show_popups(value)
	
func _gui_input(event):
	if disabled: 
		return
	if event is InputEventMouseButton:
		if card_owner == "Enemy" and event.is_pressed() and event.get_button_index() == MOUSE_BUTTON_LEFT:
			if Bus.Board.is_breached and Bus.Board.current_phase == Combat.TurnPhase.BREACH_CONFIRM:
				if remaining_life <= 0 and assigned_breach_damage > 0:
					_remove_breach_damage()
				elif remaining_life > 0:
					_assign_breach_damage()
			return
		if event.is_pressed() and event.get_button_index() == 2 and highlighted and can_act:
			var target_effects = get_trigger_effects("target")
			if target_effects:
				targeting_arrow.initiate_targeting(target_effects)
		elif not event.is_pressed() and event.get_button_index() == 2:
			if $TargetLine.is_targeting:
				targeting_arrow.complete_targeting()

func play_token(_target: TokenSlot, _animation: bool = true):
	pass

func set_highlight_color(_color: Color) -> void:
	$Highlight.default_color = Color.GOLD

func move_to(target: Control, animation: bool = true, mouse_pos: bool = false):
	visible = true
	var start_position: Vector2 = global_position
	target.add_token(self)
	if animation:
		if mouse_pos:
			start_position = get_global_mouse_position() - size / 2 
		global_position = start_position
		await get_tree().process_frame
		reset_tween()
		tween.tween_property(self, "global_position", target.global_position, kf.tween_time)
		await tween.finished
	ee.emit_signal("move", self)
	position = Vector2.ZERO
	
## card sets stats to max value, token to current value
func compare_stat(property: String, current_value: int, max_value: int):
	# don't update in the middle of recalculating stats
	if recalculating_stats:
		return
	tween_text(property, current_value)
	# Face doesn't have card
	if card:
		card.set("max_%s"%property.to_lower(), max_value)
	
func on_effects_finished():
	#if current_health <= 0: return
	# don't want stats to get reset when a unit is discarded during combat
	if Bus.Board:
		if Bus.Board.combat_happening:
			return
	recalculating_stats = true
	
	var damage_taken = max_health - current_health
	var shield_damage_taken = max_shield - current_shield
	
	if _cached_damage_taken != -1:
		damage_taken = _cached_damage_taken
		_cached_damage_taken = -1
	if _cached_shield_damage_taken != -1:
		shield_damage_taken = _cached_shield_damage_taken
		_cached_shield_damage_taken = -1
		
	var base_stats = {"health": base_health,
					"damage": base_damage,
					"shield": base_shield,
					"activation": base_activation}
	# TODO: for now this doesn't consider affect_max so everything does
	# All persistent effects for now also affect max
	for effect in effect_buffs:
		if effect['function'] == "buff_stats":
			for stat in effect['stats']:
				base_stats[stat] += effect['stats'][stat]

	max_health = base_stats['health']
	max_damage = base_stats['damage']
	max_shield = base_stats['shield']
	
	current_health = max_health - damage_taken
	if max_health < damage_taken:
		_cached_damage_taken = damage_taken
	current_shield = max_shield - shield_damage_taken
	if max_shield < shield_damage_taken:
		_cached_shield_damage_taken = shield_damage_taken
		
	current_damage = adjust_for_fatigue(max_damage)
	max_activation = base_stats['activation']
	current_activation = base_stats['activation']
	
	effect_buffs = []
	recalculating_stats = false
	call_deferred("refresh_stats_labels")
	
func reset_effects():
	effect_buffs.clear()
	
func calculate_max_bonus() -> int:
	var total_bonus = 0
	# Iterate through all combat modifiers to find potential attack bonuses
	for modifier in combat_modifiers:
		if modifier.affect_when == "Attack" and modifier.affect_whos_damage == "Attacker":
			# Calculate value assuming self is the context.
			# Only positive values add to the Bonus Pool.
			var val = modifier.value.get_value(self, self, self)
			if val > 0:
				total_bonus += val
	return total_bonus
	
func reset_remaining():
	current_bonus_damage = adjust_for_fatigue(calculate_max_bonus())
	remaining_bonus_damage = current_bonus_damage
	remaining_base_damage = current_damage
	remaining_life = current_health
	
func update_damage_preview() -> void:
	var incoming_damage = current_health - remaining_life
	var health_damage = incoming_damage + poison
	%HealthPreviewText.text = "-%s"%health_damage
	%HealthPreview.visible = (health_damage > 0 and remaining_life - poison > 0)
	
	if health_damage >= current_health:
		%Skull.visible = true
		if remaining_life > 0 and remaining_life - poison <= 0:
			%Skull.self_modulate = Color.GREEN
		else:
			%Skull.self_modulate = Color.WHITE
	else:
		%Skull.visible = false
			
	for debuff: String in ["Poison", "Vulnerable", "Feeble"]:
		if get(debuff.to_lower()) > 0:
			get_node("%" + "%sPreviewText"%debuff).text = str(get(debuff.to_lower()))
			get_node("%" + "%sPreview"%debuff).visible = true
		else:
			get_node("%" + "%sPreview"%debuff).visible = false
		update_popup(debuff)
	
func attack(target: CardToken, real: bool = true):
	# 1. Calculate Modifiers
	var self_attack_mod = 0
	var target_attack_mod = 0
	var defender_damage = 0 

	for modifier in combat_modifiers:
		var changes = modifier.get_modified_combat(self, target, true)
		self_attack_mod += changes[0]
		defender_damage += changes[1]
	for modifier in target.combat_modifiers:
		var changes = modifier.get_modified_combat(self, target, false)
		target_attack_mod += changes[0]
		defender_damage += changes[1]

	# 2. Determine Pools based on 'real'
	var pool_bonus = current_bonus_damage if real else remaining_bonus_damage
	var pool_base = current_damage if real else remaining_base_damage

	# 3. Logic
	var eligible_bonus = max(0, self_attack_mod)
	var self_penalty = min(0, self_attack_mod)
	var available_bonus = min(eligible_bonus, pool_bonus)

	var attacker_output = pool_base + available_bonus + self_penalty
	attacker_output = max(0, attacker_output)
	var total_potential = max(0, attacker_output + target_attack_mod)

	# 4. Action (Animation)
	if real:
		await attack_animation(target)

	# 5. Apply Damage
	# In Sim, remaining_life tracks health+shield combined
	var damage_dealt_cap = target.current_health + target.current_shield
	if not real:
		damage_dealt_cap = target.remaining_life
		
	var damage_dealt = min(damage_dealt_cap, total_potential)

	if real:
		target.take_damage(damage_dealt, self)
	else:
		target.remaining_life -= damage_dealt

	# 6. Consume Damage Pools
	var attacker_cost = max(0, damage_dealt - target_attack_mod)
	var bonus_used = min(attacker_cost, available_bonus)
	var base_used = attacker_cost - bonus_used

	if real:
		current_bonus_damage -= bonus_used
		current_damage -= base_used
		# Sync sim vars to real vars so previews stay accurate during animations
		remaining_bonus_damage -= bonus_used
		remaining_base_damage -= base_used
	else:
		remaining_bonus_damage -= bonus_used
		remaining_base_damage -= base_used
		# Apply Recoil in Sim
		remaining_life = max(0, remaining_life - defender_damage)

	# 7. Real Combat Signals
	if real:
		take_damage(defender_damage, target)
		if not attacked_this_turn:
			ee.emit_signal("unit_first_attack", self)
			attacked_this_turn = true
		ee.emit_signal("unit_attacked", self, target)
		ee.emit_signal("unit_defended", target, self)
	
func attack_animation(target: CardToken) -> void:
	var player: AnimationPlayer = get_node("Animation/AnimationPlayer")
	z_index = 10
	$Animation.visible = true
	var orig_position = global_position
	var direction = "W"
	if card_owner == "Enemy":
		direction = "E"
	var track = "attack_%s"%direction
	var anim : Animation = player.get_animation(track)
	var length = anim.length
	var speed = length / (kf.tween_time * 4)
	player.speed_scale = speed
	player.play(track)
	var target_position = target.global_position.move_toward(global_position, Bus.token_size.x + 5)
	reset_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "global_position", target_position, kf.tween_time)
	await tween.finished
	await get_tree().create_timer(kf.tween_time * 2).timeout
	reset_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "global_position", orig_position, kf.tween_time)
	await tween.finished
	player.stop()
	$Animation.visible = false
	z_index = 0
	player.speed_scale = 1.0

func set_act(status: bool):
	if act_disabled:
		can_act = false
	else:
		can_act = status
	if card:
		card.can_act = can_act

func update_popup(debuff: String):
	if not card: return
	if get("%s_popup"%debuff.to_lower()):
		get("%s_popup"%debuff.to_lower()).queue_free()
	if get(debuff.to_lower()) > 0:
		var popup = card.add_keyword_popup(debuff, get(debuff.to_lower()))
		set("%s_popup"%debuff.to_lower(), popup)

func show_previews():
	$Frame/Previews.visible = true
	
func hide_previews():
	$Frame/Previews.visible = false
	%Skull.visible = false

func move_card():
	if card.get_parent():
		card.get_parent().remove_child(card)
	get_tree().current_scene.call_deferred("add_child", card)

func adjust_for_fatigue(num: int) -> int:
	return(int((20.0 - current_fatigue) / 20.0 * num))

func _assign_breach_damage():
	if remaining_life <= 0 or Bus.Board.breach_amount <= 0: 
		return
		
	var amount_to_assign = min(Bus.Board.breach_amount, remaining_life)
	
	assigned_breach_damage += amount_to_assign
	Bus.Board.breach_amount -= amount_to_assign
	remaining_life -= amount_to_assign 

# New function to undo damage assignment
func _remove_breach_damage():
	if assigned_breach_damage <= 0:
		return
		
	Bus.Board.breach_amount += assigned_breach_damage
	remaining_life += assigned_breach_damage 
	assigned_breach_damage = 0
