class_name State
extends Node

signal transitioned(state: State, new_state_name: String)
var unit: AutoUnit

func enter() -> void: pass
func exit() -> void: pass

# Replaced physics_process with an explicit tick update
func on_tick() -> void: pass
