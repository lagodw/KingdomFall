class_name FaceCard
extends Unit

func create_token():
	if self is not Unit or disabled:
		return
	token = load("uid://7mvdye3t7s4").instantiate()
	token.card_owner = card_owner
	token.card_resource = card_resource
	token.visible = false
	token.card = self
	token.z_index = 2
	token.label = label
	add_child(token)
	
func set_art(_override: String = ""):
	var portrait: String = "King.png"
	if card_owner == "Player":
		var path = "res://assets/Card/Portraits/"
		%CardArt.texture = load(path + portrait)
	else:
		%CardArt.texture = Bus.map.current_location.enemy.portrait

func setup_stats():
	super.setup_stats()
	if base_damage > 0:
		%Damage.visible = true
		%Speed.visible = true
		%DamageSpacing.visible = false
		%SpeedSpacing.visible = false
	if base_shield > 0:
		%Shield.visible = true
		%ShieldSpacing.visible = false
		%ShieldSpacing2.visible = false
