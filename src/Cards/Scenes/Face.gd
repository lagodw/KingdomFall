class_name Face
extends CardToken

func setup_stats():
	super.setup_stats()
	if card_owner == "Player":
		base_health = Bus.player.health
		max_health = base_health
		current_health = Bus.player.current_health
		base_damage = Bus.player.damage
		max_damage = base_damage
		current_damage = base_damage
		base_shield = Bus.player.shield
		current_shield = base_shield
		
		#for boon: Boon in Bus.player.boons:
			#for effect: Effect in boon.effects:
				#effects.append(effect)
				#effect.connect_signal(self)
				
	if base_damage > 0:
		%Damage.visible = true
		%Speed.visible = true
	reset_remaining()

func check_act():
	can_act = true
		
func set_art(_override: String = ""):
	%ShieldSpacing.visible = false
	var portrait: String = "King.png"
	if card_owner == "Player":
		var path = "res://assets/Card/Portraits/"
		%CardArt.texture = load(path + portrait)
	else:
		%CardArt.texture = Bus.map.current_location.enemy.portrait

func show_shield(value):
	%Shield.visible = value
	if max_shield > 0:
		%ShieldSpacing.visible = not value
	else:
		%ShieldSpacing.visible = false

func discard():
	if card_owner == "Player":
		# let effects finish
		await get_tree().create_timer(0.1).timeout
		Bus.Board.defeat()
	else:
		Bus.Board.combat_won()

func set_highlight(_status: bool):
	highlight.visible = false
	highlighted = false
