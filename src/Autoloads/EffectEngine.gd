extends Node

## for boons, never fired
signal none()
signal target(targeting_card: Card, the_target: Control)
signal cast(casting_card: Card, mana_cost: int)
signal draw(drawn_card: Card)
signal discard(discarded_card: Card)
signal attach(attaching_card: Card, host: Card)
signal activate(activating_label: CardLabel)
signal move(moving_unit: Unit)
signal start_turn(turn_num: int)
signal combat_start
signal combat_finished
signal damage_taken(damaged_unit: CardToken, damage_taken: int)
## Only fired once per turn if unit attacks
signal unit_first_attack(attacking_card: CardToken)
## Fired for every separate attack
signal unit_attacked(attacker: CardToken, defender: CardToken)
signal unit_defended(defender: CardToken, attacker: CardToken)
signal killing_blow(killing_card: Card, killed_unit: CardToken)
signal unit_killed(killed_unit: CardToken, killing_card: Card)
signal play(played_unit: Unit)
signal consume_used(consume: Consume)
signal card_added_to_deck(card: CardResource)
signal night_fall
# for automatically pulling signals
signal BREAK_HERE

var effect_list: Array[Effect] = []
var this_turn_effects: Array[Effect] = []
# these are checked on the subject and trigger card
# TODO: pull these automatically from conditions script
var condition_list_subject := []
# these are only checked on the trigger card (cannot compare to subject)
var condition_list_calling := []

var method_args := {}

func _ready():
	Bus.trigger_occurred.connect(on_trigger)
	start_turn.connect(on_turn_start)
	Bus.scene_changed.connect(reset)
	Bus.restart_turn.connect(restart_turn)
	# pull args from functions to know which ones to use in callable
	var methods = get_script().get_script_method_list()
	for method in methods:
		var args := []
		# first 3 args are always subject, call_card, trigger_card
		for arg in method['args'].slice(3):
			args.append(arg.name)
		method_args[method.name] = args
		
	# pull the list of checks found in effect conditions
	# this list is everything that needs to be evaluated for each effect
	var condition_subject = EffectConditionSubject.new()
	var list = condition_subject.get_script().get_script_property_list()
	for property in list:
		if property['type'] != TYPE_NIL: # don't include the script
			condition_list_subject.append(property["name"])
	var condition_calling = EffectConditionCalling.new()
	list = condition_calling.get_script().get_script_property_list()
	for property in list:
		if property['type'] != TYPE_NIL: # don't include the script
			condition_list_calling.append(property["name"])
			
	var signals: Array[String] = []
	for signal_dict in get_signal_list():
		if signal_dict["name"] == "BREAK_HERE":
			break
		signals.append(signal_dict["name"])
	for signal_name in signals:
		var callable = Callable.create(self, "on_%s"%signal_name)
		connect(signal_name, callable)

		
func reset():
	effect_list = []
	
func restart_turn():
	for effect in this_turn_effects:
		effect_list.erase(effect)
	this_turn_effects = []
		
func on_trigger(trigger_signal: String, trigger_card: Control):
	if trigger_signal == "discard":
		var effects_to_remove: Array[Effect] = []
		for effect in effect_list:
			# If the card HOSTING the effect is discarded, remove the effect
			if effect.host_card:
				if effect.host_card == trigger_card:
					effects_to_remove.append(effect)
					continue
			
			if effect.calling_card == trigger_card:
				effects_to_remove.append(effect)
		
		for effect in effects_to_remove:
			effect_list.erase(effect)
			
	apply_effects()
	
func on_turn_start(_turn_num: int):
	this_turn_effects = []
		
func apply_effects() -> void:
	# make sure units reset their stats so effects aren't being double applied
	get_tree().call_group("Tokens", "reset_effects")
	get_tree().call_group("UnitBoxes", "reset_effects")
	await get_tree().process_frame
	var current_effects: Array[Effect] = []
	# only keep effects where trigger hasn't been queued
	# can't use effect_list.erase() because it will throw off loop
	for effect in effect_list:
		# If the effect has a host, check if the host is still valid/alive
		#if effect.host_card:
			#if not is_instance_valid(effect.host_card):
				#continue
			
		if is_instance_valid(effect.trigger_card):
			if check_conditions_calling(effect.calling_card, effect.trigger_card, 
					effect.conditions_calling):
				current_effects.append(effect)
		
	effect_list = current_effects
	for effect in effect_list:
		effect.apply_effect({})
	Bus.emit_signal("effects_finished")
	Bus.emit_signal("update_amounts")
		
######################################
############# CONDITIONS #############
######################################
## only evaluating whether trigger conditions are valid
## does not check subjects
func check_conditions_calling(call_card: Control, trigger_card: Control, conditions: EffectConditionCalling) -> bool:
	for condition_type in condition_list_calling:
		var condition_callable = Callable(self, condition_type)
		# second trigger_card arg is not needed but some functions require 2 args
		# so keep it here as opposed to creating trigger specific functions 
		# correction: use trigger_card as subject and call_card as trigger
		# for cases when they need to be compared (require_self)
		# not sure if this is right though
		var result = condition_callable.call(call_card, trigger_card, conditions.get(condition_type))
		# result is true if condition is passed
		if not result:
			#print('%s failed calling condition: %s'%[call_card.card_name, condition_type])
			return(result)
	return(true)

## subject is card that will be evaluated
## (sometimes in relation to trigger_card)
func check_conditions_subject(subject: Control, call_card: Control, 
		conditions: EffectConditionSubject) -> bool:
	for condition_type in condition_list_subject:
		var condition_callable = Callable(self, condition_type)
		var result = condition_callable.call(subject, call_card, conditions.get(condition_type))
		# result is true if condition is passed
		if not result:
			#print('%s failed subject condition: %s'%[subject.get_path(), condition_type])
			return(result)
	return(true)
	
# some conditions don't require both cards but leave them in so calling can include both
func require_allied(subject: Control, trigger_card: Control, is_allied_required: bool) -> bool:
	if not is_allied_required:
		return(true)
	return(subject.card_owner == trigger_card.card_owner)

func require_enemies(subject: Control, trigger_card: Control, is_enemies_required: bool) -> bool:
	if not is_enemies_required:
		return(true)
	return(subject.card_owner != trigger_card.card_owner)
	
func require_alive(subject: Control, _trigger_card: Control, is_life_required: bool) -> bool:
	if subject is not CardToken or not is_life_required:
		return(true)
	return(subject.remaining_life > 0)
	
func require_owner(subject: Control, _trigger_card: Control, required_owner: String) -> bool:
	if required_owner == "Either":
		return(true)
	return(required_owner == subject.card_owner)
	
func require_turn(_subject: Control, _trigger_card: Control, required_turn: int) -> bool:
	if required_turn < 0:
		return(true)
	return(Bus.Board.turn_counter == required_turn)

func require_trigger(subject: Control, trigger_card: Control, is_self_required: bool) -> bool:
	if not is_self_required:
		return(true)
	return(subject == trigger_card)

func exclude_trigger(subject: Control, trigger_card: Control, is_trigger_excluded: bool) -> bool:
	if not is_trigger_excluded:
		return(true)
	return(subject != trigger_card)

func require_on_board(subject: Control, _trigger_card: Control, is_board_required: bool) -> bool:
	if not is_board_required:
		return(true)
	if subject is not CardToken:
		return(false)
	if not subject.current_slot:
		return(false)
	return(true)

func require_act(subject: Control, _trigger_card: Control, is_act_required: bool) -> bool:
	if not is_act_required or subject is not Card:
		return(true)
	return(subject.can_act)
	
func exclude_act(subject: Control, _trigger_card: Control, is_act_excluded: bool) -> bool:
	if not is_act_excluded or subject is not Card:
		return(true)
	return(not subject.can_act)

func require_act_disabled(subject: Control, _trigger_card: Control, is_disabled_required: bool) -> bool:
	if not is_disabled_required or subject is not Card:
		return(true)
	return(subject.act_disabled)

func exclude_act_disabled(subject: Control, _trigger_card: Control, is_disabled_allowed: bool) -> bool:
	if not is_disabled_allowed or subject is not Card:
		return(true)
	return(not subject.act_disabled)
	
func exclude_faces(_subject: Control, _trigger_card: Control, faces_excluded: bool) -> bool:
	if not faces_excluded:
		return(true)
	#return(subject is not Face)
	return(true)

func require_activated(subject: Control, _trigger_card: Control, is_required: bool) -> bool:
	if subject is not CardLabel or not is_required:
		return(true)
	return(subject.activated)
	
func require_same_file(subject: Control, trigger_card: Control, is_same_required: bool) -> bool:
	if subject is not CardToken or trigger_card is not CardToken or not is_same_required:
		return(true)
	if not subject.current_slot or not trigger_card.current_slot:
		return(false)
	var subject_file = subject.current_slot.file
	var trigger_file = trigger_card.current_slot.file
	return(subject_file == trigger_file)
	
func require_same_rank(subject: Control, trigger_card: Control, is_same_required: bool) -> bool:
	if subject is not CardToken or trigger_card is not CardToken or not is_same_required:
		return(true)
	if not subject.current_slot or not trigger_card.current_slot or \
			subject.card_owner != trigger_card.card_owner:
		return(false)
	#var is_support_slot: bool = (subject.current_slot.slot_type == TokenSlot.SlotType.Support)
	#if is_support_slot and trigger_card.current_slot.slot_type != TokenSlot.SlotType.Support:
		#return(false)
	#if not is_support_slot and trigger_card.current_slot.slot_type == TokenSlot.SlotType.Support:
		#return(false)
	var subject_rank: int
	var trigger_rank: int
	#if is_support_slot:
		#subject_rank = subject.current_slot.box.support_slots.find(subject.current_slot)
		#trigger_rank = trigger_card.current_slot.box.support_slots.find(trigger_card.current_slot)
	#else:
		#subject_rank = subject.current_slot.box.fighting_slots.find(subject.current_slot)
		#trigger_rank = trigger_card.current_slot.box.fighting_slots.find(trigger_card.current_slot)
	return(subject_rank == trigger_rank)

func require_tags(subject: Control, _trigger_card: Control, required_tags: Array) -> bool:
	if not subject is Card:
		return(true)
	return(kf.intersect_arrays(subject.tags, required_tags) == required_tags)
	
func exclude_tags(subject: Control, _trigger_card: Control, excluded_tags: Array) -> bool:
	if not subject is Card:
		return(true)
	return(len(kf.intersect_arrays(subject.tags, excluded_tags)) == 0)
	
func require_attack_type(subject: Control, _trigger_card: Control, 
		allowed_types: Array[kf.AttackType]) -> bool:
	if subject is not CardToken:
		return(true)
	for type in allowed_types:
		if subject.card_resource.attack_type == type:
			return(true)
	return(false)
	
func require_armor_type(subject: Control, _trigger_card: Control, 
		allowed_types: Array[kf.ArmorType]) -> bool:
	if subject is not CardToken:
		return(true)
	for type in allowed_types:
		if subject.card_resource.armor_type == type:
			return(true)
	return(false)
	
func exclude_item_type_equipped(subject: Control, _trigger_card: Control, 
			excluded_item_types: Array[kf.ItemType]) -> bool:
	if subject is not CardToken:
		return(true)
	for item in subject.items:
		if excluded_item_types.has(item.card_resource.item_type):
			return(false)
	return(true)
	
func required_slots(subject: Control, _trigger_card: Control, types_required: Array[
		TokenSlot.SlotType]) -> bool:
	if subject is not CardToken or types_required.size() == 0:
		return(true)
	if not subject.current_slot:
		return(false)
	return(types_required.has(subject.current_slot.slot_type))

func require_building_name(subject: Control, _trigger_card: Control, required_building: String) -> bool:
	if not required_building:
		return(true)
	if not subject.current_slot:
		return(false)
	if not subject.current_slot.job:
		return(false)
	if subject.current_slot.job.bldg.resource.building_name != required_building:
		return(false)
	return(true)
	
func require_job_name(subject: Control, _trigger_card: Control, required_job: String) -> bool:
	if subject is not CardToken or required_job == "":
		return(true)
	if not subject.current_job:
		return(false)
	return(subject.current_job.description == required_job)

func require_card_type(subject: Control, _trigger_card: Control, required_types: Array) -> bool:
	if required_types.size() == 0 or (subject is not Card and subject is not CardLabel):
		return(true)
	for type in required_types:
		if subject.card_type == type:
			return(true)
	return(false)

func minimum_damage(subject: Control, _trigger_card: Control, min_damage: int) -> bool:
	if subject is not CardToken:
		return(true)
	return(subject.current_damage >= min_damage)

func minimum_shield(subject: Control, _trigger_card: Control, min_shield: int) -> bool:
	if subject is not CardToken:
		return(true)
	return(subject.current_shield >= min_shield)

func require_missing_health(subject: Control, _trigger_card: Control, missing_required: bool) -> bool:
	if not missing_required or subject is not CardToken:
		return(true)
	return(subject.current_health < subject.max_health)

func minimum_activation(subject: Control, _trigger_card: Control, min_activation: int) -> bool:
	if subject is not Card and subject is not CardLabel:
		return(true)
	return(subject.card_resource.activation >= min_activation)
	
func maximum_activation(subject: Control, _trigger_card: Control, max_activation: int) -> bool:
	if subject is not Card and subject is not CardLabel:
		return(true)
	return(subject.card_resource.activation <= max_activation)

func require_name(subject: Control, _trigger_card: Control, required_name: String) -> bool:
	if required_name == "":
		return(true)
	return(subject.card_name == required_name)

## typed array giving weird error with delayed effects
func discard_card(subject: Control):
	for effect in effect_list:
		if effect.calling_card == subject:
			if not effect.host_card:
				effect_list.erase(effect)
	subject.discard()
	return(true)

# TODO: are these really necessary? 
# They are here to combine all triggers in trigger_occurred
# but nodes could connect to all signals
func on_target(targeting_card: Card, _target: Control):
	Bus.emit_signal("trigger_occurred", "target", targeting_card)
func on_cast(casting_card: Card, _mana_cost: int):
	Bus.emit_signal("trigger_occurred", "cast", casting_card)
func on_draw(drawn_card: Card):
	Bus.emit_signal("trigger_occurred", "draw", drawn_card)
func on_discard(discarded_card: Card):
	Bus.emit_signal("trigger_occurred", "discard", discarded_card)
func on_attach(attaching_card: Card, _host: CardToken):
	Bus.emit_signal("trigger_occurred", "attach", attaching_card)
func on_activate(activated_label: CardLabel):
	Bus.emit_signal("trigger_occurred", "activate", activated_label)
func on_move(moving_unit: Unit):
	Bus.emit_signal("trigger_occurred", "move", moving_unit)
func on_start_turn(_turn_num: int):
	Bus.emit_signal("trigger_occurred", "start_turn", Bus.Board)
func on_combat_start():
	Bus.emit_signal("trigger_occurred", "combat_start", Bus.Board)
func on_combat_finished():
	Bus.emit_signal("trigger_occurred", "combat_finished", Bus.Board)
func on_damage_taken(damaged_unit: CardToken, _damage_taken: int):
	Bus.emit_signal("trigger_occurred", "damage_taken", damaged_unit)
func on_unit_first_attack(attacking_card: CardToken):
	Bus.emit_signal("trigger_occurred", "unit_first_attack", attacking_card)
func on_unit_attacked(attacker: CardToken, _defender: CardToken):
	Bus.emit_signal("trigger_occurred", "unit_attacked", attacker)
func on_unit_defended(defender: CardToken, _attacker: CardToken):
	Bus.emit_signal("trigger_occurred", "unit_defended", defender)
func on_killing_blow(killing_card: Card, _killed_card: CardToken):
	Bus.emit_signal("trigger_occurred", "killing_blow", killing_card)
func on_unit_killed(killed_card: CardToken, _killing_card: Card):
	Bus.emit_signal("trigger_occurred", "unit_killed", killed_card)
func on_play(played_unit: Unit):
	Bus.emit_signal("trigger_occurred", "play", played_unit)
func on_consume_used(consume: Consume):
	Bus.emit_signal("trigger_occurred", "consume_used", consume)
