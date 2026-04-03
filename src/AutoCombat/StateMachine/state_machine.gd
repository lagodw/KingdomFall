class_name StateMachine
extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	await owner.ready
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(on_child_transitioned)
			child.unit = owner as AutoUnit

func transition_to(state_name: String) -> void:
	var new_state = states.get(state_name.to_lower())
	if current_state:
		current_state.exit()
	new_state.enter()
	current_state = new_state

# The Manager calls this directly now! No signals needed.
func on_tick() -> void:
	if current_state:
		current_state.on_tick()

func on_child_transitioned(state: State, new_state_name: String) -> void:
	if state == current_state:
		transition_to(new_state_name)
