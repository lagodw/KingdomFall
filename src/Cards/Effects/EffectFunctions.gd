extends Resource

func add_activation_slots(subjects: Array, calling_card: Control,
		num_slots: int, temporary_slot: bool):
	for subject in subjects:
		if num_slots > 0:
			if temporary_slot:
				subject.add_slots(num_slots, calling_card)
			else:
				subject.add_slots(num_slots)
	
func add_card(calling_card: Control,
		card_name: String, card_owner: String, card_location: String):
	var resource = R.card_resources.get_matching_resource(["**/%s.tres"%card_name])[0]
	var label = kf.create_label(resource)
	match card_owner:
		"Allied":
			label.card_owner = calling_card.card_owner
		"Opponent":
			label.card_owner = kf.invert_owner(calling_card.card_owner)
		"Player", "Enemy":
			label.card_owner = card_owner
	if card_location == "Deck":
		Bus.get("%sDeck"%label.card_owner).add_card(label)
		return
	calling_card.get_tree().current_scene.add_child(label)
	await calling_card.get_tree().process_frame
	label.turn_to_card()
	var card = label.preview_card
	card.get_parent().remove_child(card)
	match card_location:
		"Hand":
			Bus.get("%sHand"%label.card_owner).add_child(card)
			
func change_bus_var(subjects: Array, calling_card: Control, trigger_card: Control,
		bus_var: String, bus_var_change: EffectValue, effect_dict: Dictionary):
	var subject
	if subjects.size() > 0:
		subject = subjects[0]
	else:
		return
	var val = bus_var_change.get_value(subject, trigger_card, calling_card, effect_dict)
	Bus.set(bus_var, Bus.get(bus_var) + val)
	
func add_debuff(subjects: Array, calling_card: Control, trigger_card: Control,
		debuff: String, debuff_amount: EffectValue, effect_dict: Dictionary):
	for subject in subjects:
		var val = debuff_amount.get_value(subject, trigger_card, calling_card, effect_dict)
		subject.set(debuff, subject.get(debuff) + val)
	
func add_tag(subjects: Array, tag: kf.Tag):
	for subject in subjects:
		if not tag in subject.tags:
			subject.tags.append(tag)
			subject.set_tag_text()

func advance_activation(subjects: Array, turns: int):
	for subject in subjects:
		subject.advance_activation(turns)

func change_max_activation(subjects: Array, calling_card: Control, trigger_card: Control,
		max_activation_change: EffectValue, persistent_effect: bool, effect_dict: Dictionary):
	for subject: CardLabel in subjects:
		var val = max_activation_change.get_value(subject, trigger_card, calling_card, effect_dict)
		if persistent_effect:
			subject.register_activation_modifier(val)
		else:
			subject.base_activation += int(val)

func attach(subjects: Array, calling_card: Control):
	if subjects.size() == 1:
		calling_card.attach_to_card(subjects[0])
	# for now only allow 1 card attaching, more than 1 should be board effect
	else:
		return(false)

func buff_stats(subjects: Array, calling_card: Control, trigger_card: Control,
		buff_damage: EffectValue, buff_health: EffectValue, 
		buff_shield: EffectValue, buff_activation: EffectValue,
		affect_max: bool, persistent_effect: bool, effect_dict: Dictionary):
	var buffs := {"damage": buff_damage, "health": buff_health, 
			"shield": buff_shield, "activation": buff_activation}
	for subject in subjects:
		var dict = {}
		for stat in ["damage", "health", "shield", "activation"]:
			var out = buffs[stat].get_value(subject, trigger_card, calling_card, effect_dict)
			if not persistent_effect:
				if out != 0:
					if affect_max:
						subject.set("max_%s"%stat, subject.get("max_%s"%stat) + out)
						subject.set("base_%s"%stat, subject.get("base_%s"%stat) + out)
					subject.set("current_%s"%stat, subject.get("current_%s"%stat) + out)
			else:
				if out != 0:
					dict[stat] = out
		if persistent_effect:
			subject.effect_buffs.append({"function": "buff_stats", 
					"affect_max": affect_max, "stats": dict})

func change_art(subjects: Array, new_art: String) -> void:
	for subject in subjects:
		subject.set_art(new_art)

func damage(subjects: Array, calling_card: Control, trigger_card: Control,
		damage_amt: EffectValue, blocked_by_shield: bool, effect_dict: Dictionary):
	for subject in subjects:
		var dmg: int = int(damage_amt.get_value(subject, trigger_card, calling_card, effect_dict))
		subject.take_damage(dmg, calling_card, blocked_by_shield)
#
#func delayed_effect(subjects: Array, trigger_card: Card, delayed_effects: DelayedEffect):
	#for subject in subjects:
		#var copy = delayed_effects.dupe()
		#copy.activate(subject, trigger_card)

func disable_act(subjects: Array, act_disabled: bool):
	for subject in subjects:
		subject.disable_act(act_disabled)
		subject.set_act(not act_disabled)

# typed array giving weird error with delayed effects
func discard(subjects: Array):
	for subject in subjects:
		for effect in ee.effect_list:
			if effect.trigger_card == subject:
				ee.effect_list.erase(effect)
		subject.discard()
	return(true)

## TODO: add condition calling for require_host
## have to figure out combat modifiers though
## then can remove this and use attach
func equip_item(subjects: Array, calling_card: Item):
	attach(subjects, calling_card)
	for subject: CardToken in subjects:
		for effect in calling_card.effects:
			if effect.function not in ["equip_item", "buff_stats"]:
				subject.effects.append(effect)
				effect.connect_signal(subject)
		subject.combat_modifiers.append_array(calling_card.card_resource.combat_modifiers)

func permanent_buff(subjects: Array, calling_card: Control, trigger_card: Control,
		perm_damage: EffectValue, perm_health: EffectValue, 
		perm_shield: EffectValue, perm_activation: EffectValue,
		effect_dict: Dictionary):
	for card in subjects:
		var damage_amt = perm_damage.get_value(card, trigger_card, calling_card, effect_dict)
		var health_amt = perm_health.get_value(card, trigger_card, calling_card, effect_dict)
		var shield_amt = perm_shield.get_value(card, trigger_card, calling_card, effect_dict)
		var act_amt = perm_activation.get_value(card, trigger_card, calling_card, effect_dict)
		if card is CardLabel:
			card = card.preview_card
		if card is Unit and card is not CardToken:
			card = card.token
		card.card_resource.damage += damage_amt
		card.card_resource.health += health_amt
		card.card_resource.shield += shield_amt
		card.card_resource.activation += act_amt
		if card is Unit:
			card.max_damage += damage_amt
			card.current_damage += damage_amt
			card.base_damage += damage_amt
			card.max_health += health_amt
			card.current_health += health_amt
			card.base_health += health_amt
			card.max_shield += shield_amt
			card.current_shield += shield_amt
			card.base_shield += shield_amt
			card.max_activation += act_amt
			card.current_activation += act_amt
			card.base_activation += act_amt


func remove_tag(subjects: Array, tag: kf.Tag):
	for subject in subjects:
		if tag in subject.tags:
			subject.tags.erase(tag)
			subject.set_tag_text()

func set_act(subjects: Array, can_act: bool):
	for subject in subjects:
		subject.set_act(can_act)

func set_stats(subjects: Array, calling_card: Control, trigger_card: Control,
		set_damage: EffectValue, set_health: EffectValue, 
		set_shield: EffectValue, set_activation: EffectValue,
		affect_max: bool, persistent_effect: bool, effect_dict: Dictionary):
	var values := {"damage": set_damage, "health": set_health, 
				"shield": set_shield, "activation": set_activation}
	for subject in subjects:
		var dict = {}
		for stat in ["damage", "health", "shield", "activation"]:
			var out = values[stat].get_value(subject, trigger_card, calling_card, effect_dict)
			if not persistent_effect:
				if out >= 0:
					if affect_max:
						subject.set("max_%s"%stat, out)
						subject.set("base_%s"%stat, out)
					subject.set("current_%s"%stat, out)
			else:
				if out >= 0:
					dict[stat] = out
		if persistent_effect:
			subject.effect_buffs.append({"function": "set_stats", 
					"affect_max": affect_max, "stats": dict})
					
func modify_cost(subjects: Array, calling_card: Control, trigger_card: Control,
		cost_change: EffectValue, persistent_effect: bool, effect_dict: Dictionary):
	for subject in subjects:
		var val = cost_change.get_value(subject, trigger_card, calling_card, effect_dict)
		if persistent_effect:
			subject.register_cost_modifier(val)
		else:
			subject.base_cost += val
			subject.current_cost += val
	
func add_skill(subjects: Array, calling_card: Control, trigger_card: Control,
		skill: UnitSkill, effect_dict: Dictionary):
	for subject in subjects:
		if skill.effect_value:
			var amt = skill.effect_value.get_value(subject, 
					trigger_card, calling_card, effect_dict)
			skill.amount = int(amt)
		subject.card_resource.skills.append(skill)

## affect_max determines whether the change is applied to the card resource
func change_fatigue(subjects: Array, calling_card: Control, trigger_card: Control,
		fatigue_change: EffectValue, affect_max: bool, effect_dict: Dictionary):
	for subject: Unit in subjects:
		var amt = fatigue_change.get_value(subject, trigger_card, calling_card, effect_dict)
		subject.current_fatigue += int(amt)
		if affect_max:
			subject.card_resource.fatigue += amt

func change_job_progress(subjects: Array, calling_card: Control, trigger_card: Control,
		progress_skill: UnitSkill.Skill, progress_change: EffectValue, effect_dict: Dictionary):
	for subject in subjects:
		if subject is not CardToken:
			continue
		if not subject.current_job:
			continue
		var amt = progress_change.get_value(subject, trigger_card, calling_card, effect_dict)
		subject.current_job.advance_progress(progress_skill, amt)

func modify_pooled_stats(subjects: Array, calling_card: Control, trigger_card: Control,
		is_multiplier: bool, pool_change: EffectValue, effect_dict: Dictionary):
	for subject in subjects:
		if subject is not UnitBox:
			continue
		
		var val = pool_change.get_value(calling_card, trigger_card, calling_card, effect_dict)
		if is_multiplier:
			var prop_name = "pooled_multiplier"
			subject.set(prop_name, subject.get(prop_name) + val)
		else:
			var prop_name = "pooled_additive"
			subject.set(prop_name, subject.get(prop_name) + val)

func draw_cards(subjects: Array, calling_card: Control, trigger_card: Control,
		num_cards: EffectValue, card_draw_type: String, effect_dict: Dictionary):
	if not Bus.draw:
		return
	
	var amt: int = 0
	if subjects.size() > 0:
		amt = int(num_cards.get_value(subjects[0], trigger_card, calling_card, effect_dict))
	else:
		amt = int(num_cards.get_value(calling_card, trigger_card, calling_card, effect_dict))
	
	if card_draw_type == "" or card_draw_type == "Any":
		Bus.draw.draw_cards(amt)
		return
		
	var drawn = 0
	while drawn < amt:
		if Bus.draw.cards.get_child_count() == 0:
			await Bus.discard.shuffle_discard()
		
		# if still 0 after checking discard, no more cards overall
		if Bus.draw.cards.get_child_count() == 0:
			break
			
		var found_card = null
		for card in Bus.draw.cards.get_children():
			if card.card_resource.card_type == card_draw_type:
				found_card = card
				break
				
		if not found_card:
			if Bus.discard.cards.get_child_count() > 0:
				await Bus.discard.shuffle_discard()
				for card in Bus.draw.cards.get_children():
					if card.card_resource.card_type == card_draw_type:
						found_card = card
						break
						
		if found_card:
			Bus.hand.draw_card(found_card)
			drawn += 1
		else:
			break
