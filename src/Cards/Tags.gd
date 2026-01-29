extends HBoxContainer

var tag_folder = "res://assets/Card/Icons/"
	
func add_tags():
	for child in get_children():
		child.queue_free()
	for tag in owner.card_resource.tags:
		add_tag_icon(tag)
	if owner is Unit:
		#for upgrade: UnitUpgrade in owner.card_resource.upgrades:
			## TODO: use resourcegroup
			#var upgrade_name: String = UnitUpgrade.Upgrade.keys()[upgrade.upgrade_type]
			#var path = tag_folder + "%s.png"%upgrade_name
			#add_icon(load(path))
		add_armor_icon(owner.card_resource.armor_type)
		add_attack_icon(owner.card_resource.attack_type)
		var curse_paths: Array[String] = []
		for curse in owner.card_resource.curses:
			if curse.icon_uid not in curse_paths:
				curse_paths.append(curse.icon_uid)
		for path in curse_paths:
			add_icon(load(path))
	elif owner is Item:
		if owner.card_resource.item_type == kf.ItemType.Weapon:
			add_attack_icon(owner.card_resource.attack_type)
		elif owner.card_resource.item_type == kf.ItemType.Armor:
			add_armor_icon(owner.card_resource.armor_type)
			
func add_tag_icon(tag: kf.Tag):
	add_icon(load("%s%s.png"%[tag_folder, kf.Tag.keys()[tag]]))
	
func add_attack_icon(type: kf.AttackType):
	add_icon(load("%s%s.png"%[tag_folder, kf.AttackType.keys()[type]]))
	
func add_armor_icon(type: kf.ArmorType):
	add_icon(load("%s%s.png"%[tag_folder, kf.ArmorType.keys()[type]]))
	
func add_icon(texture: Texture):
	var rect = TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	rect.texture = texture
	add_child(rect)
