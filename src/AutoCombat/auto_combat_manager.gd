class_name AutoCombatManager
extends Node2D

@onready var heartbeat_timer: Timer = $TickTimer
@onready var start_button: Button = $Start
@onready var combat_grid: CombatGrid = $CombatGrid
@onready var unit_panel = $CanvasLayer/Bottom/UnitPanel
@onready var bottom_ui = $CanvasLayer/Bottom

@export var sample_units: Array[CardResource] = []

const AUTO_UNIT_SCENE = preload("res://src/AutoCombat/AutoUnit.tscn")

# Keep track of all living units in combat
var active_units: Array[AutoUnit] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	combat_grid.manager = self
		
	start_button.pressed.connect(start_combat)
	heartbeat_timer.timeout.connect(_on_heartbeat)
	
	if sample_units.size() == 0:
		var unit_res_script = load("res://src/Cards/ResourceTypes/UnitResource.gd")
		for i in 3:
			var dummy = unit_res_script.new()
			dummy.card_name = "Test Unit " + str(i+1)
			dummy.health = 50
			dummy.damage = 10
			dummy.shield = 0
			dummy.speed = 2
			sample_units.append(dummy)
			
	if sample_units.size() > 0:
		unit_panel.load_units(sample_units)

func start_combat() -> void:
	start_button.visible = false
	bottom_ui.visible = false
	
	# Gather all units
	var player_units = get_tree().get_nodes_in_group("player_units")
	var enemy_units = get_tree().get_nodes_in_group("enemy_units")
	
	for unit in player_units + enemy_units:
		if unit is AutoUnit:
			active_units.append(unit) # Add to our managed queue
			
			# Ensure hex pos matches visual location if not manually deployed
			if unit.hex_pos == Vector2i(0, 0) and not combat_grid.grid.has(Vector2i(0, 0)) or unit.is_enemy:
				unit.hex_pos = combat_grid.pixel_to_hex(unit.global_position)
				
			var hex = unit.hex_pos
			combat_grid.grid[hex] = unit
			combat_grid.set_hex_occupied(hex, true)
			unit.global_position = combat_grid.hex_to_pixel(hex)
			unit.manager = self
			
			if unit.current_health > 0:
				unit.state_machine.transition_to("Idle")
				
	heartbeat_timer.start(0.25)

func deploy_unit(card_node: Node, hex: Vector2i) -> void:
	var auto_unit = AUTO_UNIT_SCENE.instantiate()
	
	auto_unit.is_enemy = false
	auto_unit.hex_pos = hex
	
	if card_node.get("max_health"):
		auto_unit.max_health = card_node.get("max_health")
	if card_node.get("max_damage"):
		auto_unit.attack_damage = card_node.get("max_damage")
		
	combat_grid.grid[hex] = auto_unit
	combat_grid.set_hex_occupied(hex, true)
	auto_unit.global_position = combat_grid.hex_to_pixel(hex)
	
	add_child(auto_unit)
	auto_unit.manager = self
	
	card_node.queue_free()

func _on_heartbeat() -> void:
	# 1. Clean up any dead units from the array
	active_units = active_units.filter(func(u): return is_instance_valid(u) and u.current_health > 0)
	
	# 2. SORTING (The Tie-Breaker)
	# Shuffle the array so that ties are resolved completely randomly each tick.
	# This prevents the same unit from always bullying others out of a hex.
	active_units.shuffle()
	
	# 3. Execution
	# Now we tick them one by one in the newly randomized order
	for unit in active_units:
		unit.state_machine.on_tick()
