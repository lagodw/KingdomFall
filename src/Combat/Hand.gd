class_name Hand
extends HBoxContainer

@export var max_x_size: float = 525.0

var focused_card: Card = null

func _ready() -> void:
	Bus.set("hand", self)
	child_exiting_tree.connect(_on_exit)
	Bus.restart_turn.connect(on_reset_turn)
	
func _on_exit(_node: Node):
	if _node == focused_card:
		focused_card = null
	await get_tree().process_frame
	update_z_indexes()

func draw_card(card: Card) -> void:
	var old_pos = card.global_position
	if card.get_parent():
		card.get_parent().remove_child(card)
		
	# 1. Spacer strategy to reserve space in HBox
	var spacer = Control.new()
	spacer.custom_minimum_size = Bus.card_size
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spacer)
	
	# 2. Add card visual
	# Add to Hand but TopLevel so it doesn't affect layout immediately
	add_child(card)
	card.z_index = 10
	card.top_level = true
	card.global_position = old_pos
	# Reset any rotation from deck or previous state
	card.rotation = 0
	card.scale = get_global_transform().get_scale()
	update_spacing()
	
	# Wait for layout to update spacer position
	await get_tree().process_frame
	
	# 3. Setup Tween to spacer position
	var target_pos = spacer.global_position
	
	card.reset_tween()
	card.tween.set_parallel(true)
	card.tween.tween_property(card, "global_position", target_pos, kf.tween_time
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	await card.tween.finished
	
	# 4. Dock card into HBox
	if is_instance_valid(spacer):
		var idx = spacer.get_index()
		card.top_level = false
		card.scale = Vector2.ONE
		if card.get_parent() == self:
			move_child(card, idx)
		spacer.queue_free()
		
	# Ensure default state
	update_z_indexes()

func on_reset_turn():
	await get_tree().process_frame
	update_z_indexes()

func set_card_focus(card: Card, is_focused: bool) -> void:
	if is_focused:
		focused_card = card
	elif focused_card == card:
		focused_card = null
	
	card.focus_in_hand(is_focused)
	update_z_indexes()
	
func update_z_indexes() -> void:
	for i in get_child_count():
		var child = get_child(i)
		
		if not child is Card:
			continue
			
		if child == focused_card:
			child.z_index = 15 # Float strictly on top
		else:
			child.z_index = i # Natural stacking order
	update_spacing()
	
func update_spacing():
	var card_count: int = 0
	for child in get_children():
		# ignore temporary spacings
		if child is Card:
			card_count += 1
	var space_per_card = (max_x_size - 200) / (card_count - 1)
	var spread = min(0, space_per_card - Bus.card_size.x)
	
	add_theme_constant_override("separation", int(spread))
	
