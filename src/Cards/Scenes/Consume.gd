class_name Consume
extends Card

var uses: int:
	set(val):
		uses = val
		card_resource.uses = val
		%CostText.text = str(uses)
		if uses <= 0:
			Bus.deck.remove_card(card_resource)
			queue_free()

func _input(event):
	# right click = target or cast spell
	if event is InputEventMouseButton and card_owner == "Player":
		if event.is_pressed() and event.get_button_index() == 2 and highlighted:
			var target_effects = get_trigger_effects("target")
			if target_effects:
				kf.mouse_disabled = true
				targeting_arrow.initiate_targeting(target_effects)
		elif not event.is_pressed() and event.get_button_index() == 2:
			if $TargetLine.is_targeting:
				kf.mouse_disabled = false
				targeting_arrow.complete_targeting()
				uses -= 1
			elif highlighted:
				ee.emit_signal("consume_used", self)
				uses -= 1
			set_highlight(false)

func class_setup():
	uses = card_resource.uses
	for effect in effects:
		effect.connect_signal(self)
