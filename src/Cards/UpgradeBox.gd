extends HBoxContainer

var tag_folder = "res://assets/Card/Icons/"
	
func add_tags():
	for child in get_children():
		child.queue_free()
	if owner is Unit:
		for upgrade: UnitUpgrade in owner.card_resource.upgrades:
			# TODO: use resourcegroup
			var upgrade_name: String = UnitUpgrade.Upgrade.keys()[upgrade.upgrade_type]
			var path = tag_folder + "%s.png"%upgrade_name
			add_icon(load(path))

func add_icon(texture: Texture):
	var rect = TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	rect.texture = texture
	add_child(rect)
