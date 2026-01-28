class_name Consume
extends Card

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
			elif highlighted:
				ee.emit_signal("consume_used", self)
			set_highlight(false)

func class_setup():
	for effect in effects:
		effect.connect_signal(self)

func set_art(override: String = ""):
	card_art = card_name
	if override != "":
		card_art = override
	elif card_resource.card_art_path:
		card_art = card_resource.card_art_path
	#elif Settings:
		#if Settings.card_art.has(card_name):
			#card_art = Settings.card_art[card_name]
	var art_path = "res://assets/CardArt/Consumables/" + card_art + ".png"
	%CardArt.texture = load(art_path)
