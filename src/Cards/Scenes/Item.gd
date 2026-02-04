class_name Item
extends Card

@onready var buff_effect = preload("uid://3wr4lk38bv1y")

var damage: int:
	set(val):
		damage = val
		update_stat("Damage")
var health: int:
	set(val):
		health = val
		update_stat("Health")
var shield: int:
	set(val):
		shield = val
		update_stat("Shield")
var buff: Effect
var setup_complete: bool = false

func class_setup():
	damage = card_resource.damage
	health = card_resource.health
	shield = card_resource.shield
	if card_resource.tags.has(kf.Tag.Indestructible):
		%CostText.text = ""
	else:
		%CostText.text = str(card_resource.current_durability)
	if damage != 0 or health != 0 or shield != 0:
		buff = buff_effect.dupe()
		buff.buff_damage = EffectValue.new()
		buff.buff_damage.number = damage
		buff.buff_health = EffectValue.new()
		buff.buff_health.number = health
		buff.buff_shield = EffectValue.new()
		buff.buff_shield.number = shield
		effects.append(buff)
	for effect in effects:
		effect.connect_signal(self)
	setup_complete = true

func update_stat(stat: String):
	tween_text(stat, get(stat.to_lower()))
	get_node("%" + stat).visible = get(stat.to_lower()) != 0
	get_node("%" + stat + "Spacing").visible = get(stat.to_lower()) == 0

func set_art(override: String = ""):
	card_art = card_name
	if override != "":
		card_art = override
	elif card_resource.card_art_path:
		card_art = card_resource.card_art_path
	#elif Settings:
		#if Settings.card_art.has(card_name):
			#card_art = Settings.card_art[card_name]
	var art_path = "res://assets/CardArt/Items/" + card_art + ".png"
	%CardArt.texture = load(art_path)

func _input(event):
	if event is InputEventMouseButton and card_owner == "Player":
		if event.is_pressed() and event.get_button_index() == 2 and highlighted:
			var target_effects = get_trigger_effects("target")
			if target_effects:
				targeting_arrow.initiate_targeting(target_effects)
		elif not event.is_pressed() and event.get_button_index() == 2:
			if $TargetLine.is_targeting:
				var _result = targeting_arrow.complete_targeting()
			set_highlight(false)

func change_durability(change: int = 0):
	if card_resource.tags.has(kf.Tag.Indestructible):
		return
	card_resource.current_durability = clampi(card_resource.current_durability + change,
			0, card_resource.max_durability)
	if card_resource.current_durability == 0:
		Bus.deck.remove_card(card_resource)

func tween_text(property: String, new_amt: int):
	var text_label: Label = get_node("%" + "%sText"%property)
	if not setup_complete:
		text_label.text = str(new_amt)
		if property == "Activation":
			text_label.set("theme_override_colors/font_color", Color.BLACK)
		else:
			text_label.set("theme_override_colors/font_color", Color.WHITE)
		return
	var start_amt = int(text_label.text)
	if start_amt == new_amt:
		return
	var color: Color = Color.FIREBRICK
	if start_amt < new_amt:
		color = Color.SEA_GREEN
	text_label.set("theme_override_colors/font_color", color)
	var callable = Callable.create(self, "set_%s_text" % property)
	var text_tween = create_tween()
	text_tween.tween_method(callable, start_amt, new_amt, kf.tween_time)
	await text_tween.finished
	if property == "Activation":
		text_label.set("theme_override_colors/font_color", Color.BLACK)
	else:
		text_label.set("theme_override_colors/font_color", Color.WHITE)
	
func set_Health_text(value: int) -> void:
	%HealthText.text = str(value)
	
func set_Damage_text(value: int) -> void:
	%DamageText.text = str(value)
	
func set_Shield_text(value: int) -> void:
	%ShieldText.text = str(value)

func attach_to_card(target: CardToken):
	target.combat_modifiers.append_array(card_resource.combat_modifiers)
	target.items.append(self)
	if not card_resource.tags.has(kf.Tag.Indestructible):
		change_durability(-1)
	super.attach_to_card(target)
