class_name AutoUnit
extends Node2D

@export var is_enemy: bool = false
@export var max_health: int = 50

# TICK BASED STATS
@export var move_ticks: int = 2     # Takes 2 heartbeats to step 1 hex
@export var attack_ticks: int = 4   # Takes 4 heartbeats to swing weapon
@export var attack_range: int = 1   # Measured in hexes (1 = melee)
@export var attack_damage: int = 10

var current_health: int
var hex_pos: Vector2i
var target: AutoUnit = null

# References
var manager: AutoCombatManager
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var hp_bar: ProgressBar = $Health
@onready var tree: AnimationTree = $AnimationTree

func _ready() -> void:
	current_health = max_health
	if is_enemy:
		add_to_group("enemy_units")
		sprite.modulate = Color(1, 0.2, 0.2) 
	else:
		add_to_group("player_units")

# Hooked up by the states
func find_nearest_target() -> void:
	target = null
	var shortest_distance: int = 9999
	var target_group = "player_units" if is_enemy else "enemy_units"
	var possible_targets = get_tree().get_nodes_in_group(target_group)
	
	for potential in possible_targets:
		if potential.current_health > 0:
			var dist = manager.hex_distance(hex_pos, potential.hex_pos)
			if dist < shortest_distance:
				shortest_distance = dist
				target = potential

func take_damage(amount: int) -> void:
	if current_health <= 0: return
	
	current_health -= amount
	update_hp_bar()
	if current_health <= 0:
		die()

func die() -> void:
	visible = false
	manager.grid.erase(hex_pos) # Free up the hex
	manager.set_hex_occupied(hex_pos, false)
	remove_from_group("enemy_units" if is_enemy else "player_units")
	state_machine.transition_to("Dead")

func update_hp_bar():
	if current_health == max_health or current_health == 0:
		hp_bar.visible = false
	else:
		hp_bar.visible = true
		var pct_hp = int(float(current_health) / max_health * 100)
		var tween = get_tree().create_tween()
		tween.tween_property(hp_bar, "value", pct_hp, 0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
		var sb = hp_bar.get_theme_stylebox("fill")
		if pct_hp <= 20:
			sb.bg_color = Color.DARK_RED
		elif pct_hp <= 50:
			sb.bg_color = Color.GOLD
		else:
			sb.bg_color = Color(0, 0.4, 0, 1)
