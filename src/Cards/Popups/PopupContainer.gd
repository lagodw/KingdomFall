class_name PopupContainer
extends VBoxContainer

const icon_folder = "res://assets/Card/Icons/"

const tag_dict: Dictionary[String, String] = {
		"Taunt": "Must be targeted first",
		"Flying": "Can only be attacked by Ranged or Flying",
		"Resistant": "Not affected by Magic",
		#"Magic": "Does not affect Resistant units",
		"Mounted": "Attacks before the enemy units",
		"Stealth": "Cannot be blocked",
		"Immortal": "Returns to your deck after combat even if it died",
		
		"Creature": "Very scary",
		"Undead": "Immune to Poison",
		"Fairie": "Immune to Weaken",
		"Giant": "Immune to Vulnerable",
		
		"Physical": "Affects Resistant units",
		
		"Light": "Can only equip Light armor",
		"Heavy": "Can equip Light or Heavy armor",
		"Inanimate": "Cannot equip armor",
		
		"Indestructible": "Does not lose durability",
		
		"Melee": "Can only equip Melee weapons",
		"Ranged": "Can only equip Ranged weapons",
		"Magic": "Can only equip Magic weapons",
}

const text_dict: Dictionary[String, String] = {
		"[b]Deploy[/b]": "Occurs when the unit is played to any box",
		"[b]Board[/b]": "Has effect when unit is on the battlefield",
		"[b]Support[/b]": "Has effect when unit is in Support box",
		"[b]Target[/b]": "When unit is in Support box, right click to target a unit",
		"[b]Death[/b]": "Occurs when the unit dies",
		"[b]Start of Turn[/b]": "Occurs at the start of each turn",
		"[b]Combat End[/b]": "Occurs at the start of each turn",
		"[b]Dormant[/b]": "Cannot act until awakend",
		"[b]Shield[/b]": "Absorbs damage and regenerates at the start of each turn",
		"[b]Thorns[/b]": "Melee attackers take X damage",
		"[b]Vulnerable[/b]": "Takes +X damage when attacked",
		"[b]Feeble[/b]": "Deals -X damage when attacking",
		"[b]Poison[/b]": "Take X damage at the end of the turn",
		
		"[b]Rank[/b]": "A horizontal row of units",
		"[b]File[/b]": "A vertical column of units",
	}
	
const item_tag_dict: Dictionary[String, String] = {
	"Light": "Can be equipped by any unit",
	"Heavy": "Can only be equipped by heavy units",
	"Melee": "Can only be equipped by melee units",
	"Ranged": "Can only be equipped by ranged units",
	"Magic": "Can only be equipped by magic units",
}

func create_popups() -> void:
	for child in get_children():
		child.queue_free()
	if owner is Unit:
		create_armor_type_popup(owner.card_resource.armor_type)
		create_attack_type_popup(owner.card_resource.attack_type)
	#elif owner is Burden:
		#create_popup("Burden", "This card has a negative effect until drawn")
	elif owner is Item:
		if not owner.card_resource.tags.has(kf.Tag.Indestructible):
			create_popup("Durability", 
				"Items lose 1 durability each time they are used and are destroyed if they reach 0 durability",
				"uid://dkteqdm5uvadh")
		if owner.card_resource.item_type == kf.ItemType.Weapon:
			create_attack_type_popup(owner.card_resource.attack_type, item_tag_dict)
		elif owner.card_resource.item_type == kf.ItemType.Armor:
			create_armor_type_popup(owner.card_resource.armor_type, item_tag_dict)
	elif owner is Consume:
		create_popup("Consumable", 
				"Can only be used once")
	for tag in owner.tags:
		create_tag_popup(tag)
	for key in text_dict:
		if key.is_subsequence_of(owner.get_node("%CardText").text):
			var paths = R.art.get_matching_paths(["**/" + Utils.strip_bold(key) + ".png"])
			var path: String = ""
			if paths.size() == 1:
				path = paths[0]
			create_popup(key, text_dict[key], path)
	visible = false
	
func create_tag_popup(tag: kf.Tag):
	var tag_str: String = kf.Tag.keys()[tag]
	create_popup(tag_str, tag_dict[tag_str],
			icon_folder + "%s.png"%tag_str)

func create_attack_type_popup(attack_type: kf.AttackType, dict: Dictionary[String, String] = tag_dict):
	var tag_str: String = kf.AttackType.keys()[attack_type]
	create_popup(tag_str, dict[tag_str],
			icon_folder + "%s.png"%tag_str)

func create_armor_type_popup(armor_type: kf.ArmorType, dict: Dictionary[String, String] = tag_dict):
	var tag_str: String = kf.ArmorType.keys()[armor_type]
	create_popup(tag_str, dict[tag_str],
			icon_folder + "%s.png"%tag_str)

func create_popup(key: String, text: String, 
		icon_path: String = "") -> Control:
	var popup = R.tooltip.instantiate()
	popup.title = key
	popup.description = text
	popup.icon_path = icon_path
	add_child(popup)
	return(popup)
	
func create_keyword_popup(keyword: String, num: int = 0) -> Control:
	var icon: String
	match keyword:
		"Shield": icon = "uid://b6lm11rvw7ni3"
		"Vulnerable": icon = "uid://0un1v3txl4g7"
		"Feeble": icon = "uid://8f7nhd2p1vde"
		"Poison": icon = "uid://ct5bhmqv074i2"
	var txt: String = text_dict["[b]%s[/b]"%keyword]
	if num != 0:
		keyword += " (%s)"%num
		txt = txt.replace(" -X ", " -%s "%num)
		txt = txt.replace(" +X ", " +%s "%num)
		txt = txt.replace(" X ", " %s "%num)
	return(create_popup(keyword, txt, icon))

func show_tooltips(value: bool):
	for tooltip in get_children():
		tooltip.set_node_sizes()
	visible = value
	
