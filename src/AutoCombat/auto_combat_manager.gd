class_name AutoCombatManager
extends Node2D

@onready var heartbeat_timer: Timer = $TickTimer
@onready var start_button: Button = $Start
@onready var combat_grid: CombatGrid = $CombatGrid

# Keep track of all living units in combat
var active_units: Array[AutoUnit] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	start_button.pressed.connect(start_combat)
	heartbeat_timer.timeout.connect(_on_heartbeat)

func start_combat() -> void:
	start_button.visible = false
	
	# Gather all units
	var player_units = get_tree().get_nodes_in_group("player_units")
	var enemy_units = get_tree().get_nodes_in_group("enemy_units")
	
	for unit in player_units + enemy_units:
		if unit is AutoUnit:
			active_units.append(unit) # Add to our managed queue
			
			var start_hex = combat_grid.pixel_to_hex(unit.global_position)
			unit.hex_pos = start_hex
			combat_grid.grid[start_hex] = unit
			combat_grid.set_hex_occupied(start_hex, true)
			unit.global_position = combat_grid.hex_to_pixel(start_hex)
			unit.manager = self
			
			if unit.current_health > 0:
				unit.state_machine.transition_to("Idle")
				
	heartbeat_timer.start(0.25)

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
