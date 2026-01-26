class_name Spell
extends Card

var mana_cost: int

func class_setup():
	mana_cost = card_resource.mana_cost
	%CostText.text = str(mana_cost)
	Bus.currency_changed.connect(on_currency_changed)
	for effect in effects:
		effect.connect_signal(self)
	
func on_currency_changed(currency: String, _new_amt: int, _change: int):
	# only check if in combat
	if currency == "mana" and Bus.Board:
		check_castable_spell()

func _input(event):
	if not can_act or Bus.mana < mana_cost: 
		return
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
				var result = targeting_arrow.complete_targeting()
				if result:
					Bus.mana -= mana_cost
			elif highlighted:
				Bus.mana -= mana_cost
				ee.emit_signal("cast", self, mana_cost)
			set_highlight(false)
			
## grey out spells if they can't be cast during combat
func check_castable_spell() -> void:
	if card_resource.mana_cost > Bus.mana:
		%CostText.set("theme_override_colors/font_color", Color.FIREBRICK)
	else:
		%CostText.set("theme_override_colors/font_color", Color.WHITE)
