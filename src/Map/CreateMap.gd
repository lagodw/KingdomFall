class_name CreateMap
extends Control

func create_map():
	var act = load("uid://bmbwribogtqb2").dupe()
	#var act = load("uid://ccmbm3ielwgxj").duplicate(true) # small
	await act.setup()
	
	var map = Map.new()
	map.acts.append(act)
	map.current_act = act
	Bus.map = map
