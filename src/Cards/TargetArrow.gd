class_name TargetingArrow
extends Line2D

@onready var owner_card: Card = get_parent()

var potential_targets := []
var is_targeting := false
var target_object : Node = null
var curve: Curve2D

var effects_to_check: Array[Effect] = []
var target_types: Array[String] = []

func _ready() -> void:
	$ArrowHead/Area2D.area_entered.connect(_on_ArrowHead_area_entered)
	$ArrowHead/Area2D.area_exited.connect(_on_ArrowHead_area_exited)
	
func _process(_delta: float) -> void:
	if owner_card.disabled:
		return
	if is_targeting:
		$ArrowHead.visible = true
		_draw_targeting_arrow()
	else:
		clear_arrow()
		
func initiate_targeting(effects: Array[Effect] = []) -> void:
	effects_to_check = effects
	for effect in effects_to_check:
		var type: String = effect.target_type
		if not target_types.has(type):
			target_types.append(type)
	is_targeting = true
	kf.mouse_disabled = true
	$ArrowHead.visible = true
	$ArrowHead/Area2D.monitoring = true

func complete_targeting() -> bool:
	if len(potential_targets) > 0 and is_targeting:
		target_object = potential_targets.back()
	else:
		target_object = null
	is_targeting = false
	kf.mouse_disabled = false
	clear_points()
	$ArrowHead.visible = false
	$ArrowHead/Area2D.monitoring = false
	if target_object:
		ee.emit_signal("target", owner_card, target_object)
		return(true)
	return(false)

func _on_ArrowHead_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if not is_targeting or not parent.visible:
		return
	if not ((parent is CardToken and target_types.has("Unit") or (
				parent is CardLabel and target_types.has("CardLabel")) or (
				parent is TokenSlot and (target_types.has("Rank") or target_types.has("File")))
			)):
		return
	var valid_target = true
	for effect in effects_to_check:
		valid_target = ee.check_conditions_subject(parent, owner_card, 
			effect.conditions_subject)
		if valid_target and not potential_targets.has(parent):
			if parent is TokenSlot:
				if target_types.has("Rank"):
					Bus.Grid.show_rank_highlight(parent)
				elif target_types.has("File"):
					parent.box.set_highlight(true)
			else:
				parent.set_highlight(true)
			potential_targets.append(parent)

func _on_ArrowHead_area_exited(area: Area2D) -> void:
	if area.get_parent() in potential_targets:
		potential_targets.erase(area.get_parent())
		if area.get_parent() is TokenSlot:
			var has_slot: bool = false
			for target in potential_targets:
				if target is TokenSlot:
					has_slot = true
			if not has_slot:
				Bus.Grid.hide_rank_highlight()
				area.get_parent().box.set_highlight(false)
		else:
			area.get_parent().set_highlight(false)

func _draw_targeting_arrow() -> void:
	curve = Curve2D.new()
	var card_half_size = Bus.card_size/2
	if owner_card is CardToken:
		card_half_size = Bus.token_size/2
	var centerpos = global_position + card_half_size * scale
	clear_points()
	var start_position = centerpos
	if is_targeting:
		add_arrow(start_position, get_global_mouse_position())

func add_arrow(start_position, end_position):
	var card_half_size = Bus.token_size/2
	var final_point =  end_position - (position + card_half_size)
	curve.add_point(to_local(start_position),
			Vector2(0,0),
			start_position.direction_to(get_viewport().size/2) * 75)
	curve.add_point(to_local(position +
			card_half_size + final_point),
			Vector2(0, 0), Vector2(0, 0))
	set_points(curve.get_baked_points())
	$ArrowHead.position = get_point_position(
			get_point_count() - 1)
	for _del in range(1,3):
		remove_point(get_point_count() - 1)
	if get_point_count() > 0:
		$ArrowHead.rotation = get_point_position(
					get_point_count() - 1).direction_to(
					to_local(position + card_half_size + final_point)).angle()
	$ArrowHead.color = Color.FIREBRICK

func clear_arrow():
	clear_points()
	get_node("ArrowHead").visible = false
