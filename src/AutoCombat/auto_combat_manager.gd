class_name AutoCombatManager
extends Node2D

@onready var heartbeat_timer: Timer = $TickTimer
@onready var start_button: Button = %Start
@onready var combat_grid: CombatGrid
@onready var unit_panel = $CanvasLayer/Bottom/UnitPanel
@onready var bottom_ui = $CanvasLayer/Bottom

@export var sample_units: Array[CardResource] = []
var enemy_army_scene: PackedScene
var selected_unit_resources: Array[UnitResource]

const AUTO_UNIT_SCENE = preload("res://src/AutoCombat/AutoUnit.tscn")

# Keep track of all living units in combat
var active_units: Array[AutoUnit] = []
var combat_over: bool = false
var tick_time: float = 0.5

func _ready() -> void:
	$CombatWon.choices = Bus.map.current_location.unit_options
	$CombatWon.setup()
		
	enemy_army_scene = Bus.map.current_location.enemy.grid_scene
	# Overwrite grid if an army configuration provided
	if enemy_army_scene:
		var army = enemy_army_scene.instantiate()
		var custom_grid = army.get_node_or_null("CombatGrid")
		
		if custom_grid:
			army.remove_child(custom_grid)
			custom_grid.owner = null  # Unset owner to prevent hierarchy inconsistency warnings
			add_child(custom_grid)
			combat_grid = custom_grid
			
		combat_grid.manager = self
		# Wait one frame for the Grid's ready to execute if it was just injected
		if custom_grid and not custom_grid.is_node_ready():
			await custom_grid.ready
		
		# Hydrate our grid with the spawned enemies
		for child in army.get_children():
			if child is EnemySpawn and child.unit_resource:
				var enemy_unit = AUTO_UNIT_SCENE.instantiate()
				enemy_unit.is_enemy = true
				enemy_unit.resource = child.unit_resource
				
				# Physically snap them to the grid coordinates securely based on visual Editor layout
				var hex = combat_grid.pixel_to_hex(child.global_position)
				enemy_unit.hex_pos = hex
				enemy_unit.global_position = combat_grid.hex_to_pixel(hex)
				
				combat_grid.grid[hex] = enemy_unit
				combat_grid.set_hex_occupied(hex, true)
				
				add_child(enemy_unit)
				enemy_unit.manager = self
				
		army.queue_free()
	else:
		combat_grid.manager = self

	start_button.pressed.connect(start_combat)
	heartbeat_timer.timeout.connect(_on_heartbeat)
	
	var units: Array[CardResource]
	if Bus.map.current_location.enemy.is_night_enemy:
		for card in Bus.deck.cards:
			if card is UnitResource:
				units.append(card)
	else:
		for card in Bus.player.day_deck:
			if card is UnitResource:
				units.append(card)
	unit_panel.load_units(units)

func start_combat() -> void:
	start_button.visible = false
	bottom_ui.visible = false
	
	# Gather all units
	var player_units = get_tree().get_nodes_in_group("player_units")
	var enemy_units = get_tree().get_nodes_in_group("enemy_units")
	
	for unit in player_units + enemy_units:
		if unit is AutoUnit:
			active_units.append(unit) # Add to our managed queue
			
			# Ensure hex pos matches visual location if not manually deployed (player units)
			if unit.hex_pos == Vector2i(0, 0) and not combat_grid.grid.has(Vector2i(0, 0)):
				unit.hex_pos = combat_grid.pixel_to_hex(unit.global_position)
				
			var hex = unit.hex_pos
			combat_grid.grid[hex] = unit
			combat_grid.set_hex_occupied(hex, true)
			unit.global_position = combat_grid.hex_to_pixel(hex)
			unit.manager = self
			
			if unit.current_health > 0:
				unit.state_machine.transition_to("Idle")
				
	heartbeat_timer.start(tick_time)

func deploy_unit(card: Unit, hex: Vector2i) -> void:
	var auto_unit = AUTO_UNIT_SCENE.instantiate()
	
	auto_unit.is_enemy = false
	auto_unit.hex_pos = hex
	auto_unit.resource = card.card_resource
	
	combat_grid.grid[hex] = auto_unit
	combat_grid.set_hex_occupied(hex, true)
	auto_unit.global_position = combat_grid.hex_to_pixel(hex)
	
	add_child(auto_unit)
	auto_unit.manager = self
	
	card.queue_free()

func _on_heartbeat() -> void:
	# 1. Clean up any dead units from the array
	active_units = active_units.filter(func(u): return is_instance_valid(u) and u.current_health > 0)
	
	# 2. Check for Victory or Loss
	var enemies_alive = false
	for u in active_units:
		if u.is_enemy:
			enemies_alive = true
			break
			
	if not enemies_alive:
		heartbeat_timer.stop()
		combat_won()
		return

	var players_alive = false
	for u in active_units:
		if not u.is_enemy:
			players_alive = true
			break
	
	if not players_alive:
		heartbeat_timer.stop()
		combat_lost()
		return
	
	# 3. Sorting (The Tie-Breaker)
	# Shuffle the array so that ties are resolved completely randomly each tick.
	# This prevents the same unit from always bullying others out of a hex.
	active_units.shuffle()
	
	# 4. Execution
	# Now we tick them one by one in the newly randomized order
	for unit in active_units:
		unit.state_machine.on_tick()

func combat_won():
	#if Bus.map.current_location.enemy.is_final_enemy:
		#kf.load_scene("uid://b5u1o6v1y4j3i")
		#return
	# wait for last units to tween
	# TODO: hide remaining cards instead
	#await get_tree().create_timer(kf.tween_time*1.5).timeout
	#for card in Bus.hand.get_children():
		#card.queue_free()
	#for unit in Bus.deck.get_units():
		#if not selected_unit_resources.has(unit) and Bus.map.current_location.enemy.is_night_enemy:
			#unit.fatigue -= 5
	#for card in Bus.PlayerGraveyard.get_units():
		#card.card_resource.fatigue += 10
	get_tree().paused = true
	combat_over = true
	$CombatWon.visible = true
	
func combat_lost():
	kf.load_scene("uid://bw1l202axfrki")
