class_name UnitGrid
extends HBoxContainer

@export var player_front: UnitBox
@export var player_back: UnitBox
@export var enemy_front: UnitBox
@export var enemy_back: UnitBox

func _ready() -> void:
	Bus.Grid = self
	Bus.trigger_occurred.connect(on_trigger)

func on_trigger(trigger: String, _trigger_card: Control) -> void:
	if trigger in ['target', 'cast', 'discard', 'attach', 'move', 'consume_used']:
		await get_tree().process_frame
		update_previews()

func get_units(unit_owner: String) -> Array:
	var units: Array = []
	if unit_owner == "Player":
		units.append_array(player_front.get_units())
		units.append_array(player_back.get_units())
	else:
		units.append_array(enemy_front.get_units())
		units.append_array(enemy_back.get_units())
	return units

func update_previews() -> void:
	get_tree().call_group("Tokens", "reset_remaining")
	await get_tree().process_frame
	
	player_front.update_preview()
	player_back.update_preview()
	enemy_front.update_preview()
	enemy_back.update_preview()
	
	execute_combat(false)

func start_combat() -> void:
	await execute_combat(true)

func execute_combat(real: bool) -> void:
	# 1. ENEMY GOES FIRST: Calculate Enemy Attack vs Player Shield
	var enemy_back_dmg = enemy_back.get_pooled_damage(real)
	var player_front_shield = player_front.get_pooled_shield(real)
	var enemy_overflow = enemy_back_dmg - player_front_shield
	
	# 2. Distribute Enemy Overflow -> Player Side
	if enemy_overflow > 0:
		if real:
			await distribute_overflow_damage(enemy_overflow, "Player", true)
		else:
			distribute_overflow_damage(enemy_overflow, "Player", false)
	
	# If this is a real combat and the player died/lost during the enemy phase, stop here
	if real and Bus.Board.combat_over:
		return
	
	# 3. PLAYER GOES SECOND: Calculate Player Attack (using surviving units) vs Enemy Shield
	var player_back_dmg = player_back.get_pooled_damage(real)
	var enemy_front_shield = enemy_front.get_pooled_shield(real)
	var player_overflow = player_back_dmg - enemy_front_shield
	
	# 4. Distribute Player Overflow -> Enemy Side
	if player_overflow > 0:
		if real:
			await distribute_overflow_damage(player_overflow, "Enemy", true)
		else:
			distribute_overflow_damage(player_overflow, "Enemy", false)

func distribute_overflow_damage(amount: int, target_owner: String, real: bool) -> void:
	var remaining_damage = amount
	var all_target_units = get_units(target_owner)
	
	# Filter valid targets based on whether this is real or a preview
	var valid_targets = []
	for unit in all_target_units:
		var hp = unit.current_health if real else unit.remaining_life
		if hp > 0:
			valid_targets.append(unit)
			
	# Sort by the dynamic ratio
	valid_targets.sort_custom(func(a, b): return _sort_by_attack_ratio(a, b, real))
	
	# Apply damage
	for unit in valid_targets:
		if remaining_damage <= 0:
			break
			
		var hp = unit.current_health if real else unit.remaining_life
		var health_dmg = min(remaining_damage, hp)
		
		if real:
			unit.current_health -= health_dmg
			remaining_damage -= health_dmg
			
			if typeof(get_tree()) != TYPE_NIL:
				# Using 0.25 here for pacing; replace with kf.tween_time if applicable
				await get_tree().create_timer(0.25).timeout 
		else:
			# Modifying remaining_life automatically updates the preview UI in CardToken.gd
			unit.remaining_life -= health_dmg
			remaining_damage -= health_dmg
			
	# Hit the gate if real combat overflows past all units
	if remaining_damage > 0 and target_owner == "Player":
		if Bus.gate and real:
			Bus.gate.current_health -= remaining_damage

func _sort_by_attack_ratio(a, b, real: bool) -> bool:
	var hp_a = a.current_health if real else a.remaining_life
	var hp_b = b.current_health if real else b.remaining_life
	
	var dmg_a = a.current_damage if real else a.remaining_base_damage
	var dmg_b = b.current_damage if real else b.remaining_base_damage
	
	var ratio_a = float(dmg_a) / float(hp_a) if hp_a > 0 else 0.0
	var ratio_b = float(dmg_b) / float(hp_b) if hp_b > 0 else 0.0
	
	return ratio_a > ratio_b
