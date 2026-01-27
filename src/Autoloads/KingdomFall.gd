@tool
extends Node

## force the order of loading classes to avoid errors
var force_load_subject: EffectConditionSubject
var force_load_calling: EffectConditionCalling

enum Tag {Creature, Taunt, Resistant, Magic, Stealth, Mounted, Flying,
		Physical, Undead, Fairie, Giant, Immortal, Indestructible, Volley}
enum AttackType {Melee, Ranged, Magic}
enum ArmorType {Light, Heavy, Inanimate}
enum ItemType {Weapon, Armor, Jewelry}

var tween_time := 0.25
var combat_tween := 0.5
var user: Resource

var color_map: Dictionary[String, String] = {"NoAct": "Grey",
				"Unit": "Blue",
				"Spell": "Purple",
				"Item": "Brown",
				"Burden": "Red",
				"Face": "Green",
				"Consume": "Gold"
				}
var mouse_disabled := false
var dragging: Unit = null
var highlighted_slot: TokenSlot

var fog: bool = true
	
func _ready() -> void:
	#user = load("res://src/Autoloads/UserSettings.gd").new()
	#user.setup()
		
	var custom_drag_image = load("uid://cbfuu0tudcjm5")
	Input.set_custom_mouse_cursor(
		custom_drag_image,
		Input.CURSOR_CAN_DROP,
		Vector2(0, 0)
	)
	# TODO: Input.CURSOR_FORBIDDEN
	
func copy_deck(deck: Deck) -> Deck:
	var new_deck = deck.dupe()
	return(new_deck)
	
func create_card(card_resource: CardResource, card_owner: String = "Player") -> Card:
	var newcard: Card
	if card_resource is UnitResource:
		newcard = R.unit.instantiate()
	elif card_resource is ItemResource:
		newcard = R.item.instantiate()
		add_equip(card_resource)
	elif card_resource is SpellResource:
		newcard = R.spell.instantiate()
	elif card_resource is BurdenResource:
		newcard = R.burden.instantiate()
	elif card_resource is ConsumeResource:
		newcard = R.consume.instantiate()
	newcard.card_resource = card_resource
	newcard.card_owner = card_owner
	return(newcard)
	
func create_label(card_resource: CardResource, card_owner: String = "Player") -> CardLabel:
	var newlabel: CardLabel = R.card_label.instantiate()
	newlabel.card_resource = card_resource
	newlabel.card_owner = card_owner
	return(newlabel)
	
func create_token(card_resource: CardResource, card_owner: String = "Player") -> CardToken:
	var newtoken = R.token.instantiate()
	newtoken.card_resource = card_resource
	newtoken.card_owner = card_owner
	return(newtoken)
		
func add_equip(card_resource: ItemResource) -> void:
	for effect in card_resource.effects:
		if effect.function == "attach":
			return
	var equip = R.equip_item.dupe()
	if card_resource.item_type == ItemType.Weapon:
		var allowed_type: Array[AttackType]
		allowed_type.append(card_resource.attack_type)
		equip.conditions_subject.require_attack_type = allowed_type
	elif card_resource.item_type == ItemType.Armor:
		var allowed_type: Array[ArmorType] = [ArmorType.Heavy]
		if card_resource.armor_type == ArmorType.Light:
			allowed_type.append(ArmorType.Light)
		equip.conditions_subject.require_armor_type = allowed_type
	equip.conditions_subject.exclude_item_type_equipped.append(card_resource.item_type)
	card_resource.effects.append(equip)
	
func change_scene_to_packed(new_scene: PackedScene) -> void:
	Bus.emit_signal("scene_changed")
	await get_tree().process_frame
	get_tree().change_scene_to_packed(new_scene)

func load_map() -> void:
	load_scene("uid://bh5c0lqir8g3a")
	
func load_town() -> void:
	load_scene("uid://vemck1rodckn")
	
func add_player_deck(scene: Node) -> void:
	var escape = load("uid://k4x5rr75uoch").instantiate()
	scene.add_child(escape)
	escape.visible = false
	var ui = load("uid://dglfstjlbuudi").instantiate()
	scene.add_child(ui)
	var deck = load("uid://dbs16ja7fgnco").instantiate()
	deck.card_owner = "Player"
	scene.add_child(deck)
	#deck.global_position = Vector2(52, 590)
	
#func save_game() -> void:
	#var save = SaveFile.new()
	#save.map = Bus.map
	#save.deck = Bus.deck
	#save.gold = Bus.gold
	#ResourceSaver.save(save, "user://SaveFile.tres")
	
#########################
######### UTILS #########
#########################

func sort_cards(card_a: Control, card_b: Control) -> bool:
	# sort by activation cost -> type -> name
	var data_a = card_a.card_resource
	var data_b = card_b.card_resource
	var act_a: int
	var act_b: int
	# spells don't have max_activation
	if card_a is CardLabel:
		act_a = card_a.max_activation
		act_b = card_b.max_activation
	elif card_a is Card:
		act_a = card_a.card_resource.activation
		act_b = card_b.card_resource.activation
		
	if act_a == act_b:
		if data_a.card_type == data_b.card_type:
			if data_a.card_name < data_b.card_name:
				return(true)
		# use > so units are before spells
		elif data_a.card_type > data_b.card_type:
			return(true)
	elif act_a < act_b:
		return(true)
	return(false)

func sort_resources(data_a: CardResource, data_b: CardResource) -> bool:
	# sort by activation cost -> type -> name
	if data_a.activation == data_b.activation:
		if data_a.card_type == data_b.card_type:
			if data_a.card_name < data_b.card_name:
				return(true)
		# use > so units are before spells
		elif data_a.card_type > data_b.card_type:
			return(true)
	elif data_a.activation < data_b.activation:
		return(true)
	return(false)
	
## returns the opposite of Player/Enemy
func invert_owner(card_owner: String) -> String:
	if card_owner == "Player":
		return("Enemy")
	elif card_owner == "Enemy":
		return("Player")
	else:
		push_error("INVALID invert_owner")
		return("???")

# https://forum.godotengine.org/t/how-to-check-for-array-intersection/27600/3
func intersect_arrays(arr1: Array, arr2: Array) -> Array:
	var arr2_dict := {}
	for v in arr2:
		arr2_dict[v] = true

	var in_both_arrays := []
	for v in arr1:
		if arr2_dict.get(v, false):
			in_both_arrays.append(v)
	return in_both_arrays

## find largest text size that will fit in the given area
func fit_font_size(node: Control, max_font_size: int = 24) -> void:
	var font = node.get_theme_font("font")
	var font_size = node.get_theme_font_size("font_size")
	
	font_size = min(font_size, max_font_size)
	var size_x = node.size.x - 2
	var size_y = node.size.y
	var text_size = font.get_multiline_string_size(node.text, 
			HORIZONTAL_ALIGNMENT_CENTER, size_x, font_size)
	
	while text_size.x > size_x or text_size.y > size_y:
		text_size = font.get_multiline_string_size(node.text, 
			HORIZONTAL_ALIGNMENT_CENTER, size_x, font_size)
		var text_size_bigger = font.get_multiline_string_size(node.text, 
			HORIZONTAL_ALIGNMENT_CENTER, size_x, font_size+1)
		
		if text_size.x > size_x or text_size.y > size_y:
			if font_size == 1:
				break
			font_size -= 1
		elif font_size < max_font_size and text_size_bigger.x <= size_x\
			and text_size_bigger.y <= size_y:
			font_size += 1
	
	node.add_theme_font_size_override("font_size", font_size)

## find largest text size that will fit in the given area without allowing multilines
func fit_font_single_line(node: Control, max_font_size: int = 24) -> void:
	var font = node.get_theme_font("font")
	var font_size = node.get_theme_font_size("font_size")
	
	font_size = min(font_size, max_font_size)
	var size_x = node.size.x - 2
	var text_size = font.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT,
			-1, font_size)
	
	while text_size.x > size_x:
		text_size = font.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT,
			-1, font_size)
		var text_size_bigger = font.get_string_size(node.text, 
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1)
		
		if text_size.x > size_x:
			if font_size == 1:
				break
			font_size -= 1
		elif font_size < max_font_size and text_size_bigger.x <= size_x:
			font_size += 1
	
	node.add_theme_font_size_override("font_size", font_size)

# --- Public API: Call this function from any script to change scenes ---
func load_scene(path: String) -> void:
	# 1. Instantiate and display the loading screen
	Bus.emit_signal("scene_changed")
	var loading_screen_instance = R.loading_scene.instantiate()
	get_tree().root.add_child(loading_screen_instance)

	# 2. Tell the loading screen to start the asynchronous load
	# Note: We pass the path to the loading screen which will handle the ResourceLoader calls
	loading_screen_instance.start_loading(path)
	
# --- Private API: Called by the LoadingScreen when a resource is ready ---
func finish_transition(new_scene_resource: PackedScene) -> void:
	# 1. Get a reference to the current main scene
	var old_scene = get_tree().current_scene
	
	# 2. Instantiate the new scene
	var new_scene = new_scene_resource.instantiate()
	
	# 3. Add the new scene to the tree before removing the old one (safer transition)
	get_tree().root.add_child(new_scene)

	# 4. Set the new scene as the current scene
	get_tree().current_scene = new_scene

	# 5. Remove and free the old scene (deferred for safety)
	if old_scene:
		old_scene.call_deferred("queue_free")
	Bus.emit_signal("new_scene_loaded")
	
func load_tutorial_scene(scene_path: String, use_tween: bool = true) -> void:
	# 1. Get a unique ID from the filename (e.g., "DeckIntro.tscn" -> "DeckIntro")
	var file_name = scene_path.get_file().get_basename()
	
	## 2. Check if seen
	if Settings.tutorial_progress.has(file_name) or Settings.settings.hide_tutorial:
		return
		
	# 3. Mark as seen and save immediately
	Settings.tutorial_progress[file_name] = true
	Settings.save_settings()
	
	# 4. Instantiate the scene
	var scene_res = load(scene_path)
	if not scene_res:
		push_error("Tutorial scene not found: " + scene_path)
		return
		
	var instance = scene_res.instantiate()
	if not use_tween:
		instance.tween_time = 0.0
	# 5. Add to the SceneTree root (so it persists across scene changes if needed)
	get_tree().root.add_child(instance)
	return
