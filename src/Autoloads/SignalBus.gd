extends Node

signal turn_starting
signal board_loaded
signal combat_starting
signal scene_changed
signal new_scene_loaded
signal trigger_occurred(trigger: String, trigger_card: Control)
signal effects_finished
signal update_amounts
signal target_change
signal take_snapshot
signal restart_turn
signal currency_changed(currency: String, old_amt: int, change: int)
signal map_scale_changed(new_scale: float)
signal energy_changed

var map: Control
var player: Player
## Player's deck to be kept track of
var deck: Deck:
	set(val):
		player.deck = val
		val.update_upkeep()
	get():
		if not player:
			return(null)
		return(player.deck)
var gold: int:
	set(val):
		var change = max(0, val) - player.gold
		player.gold = max(0, val)
		emit_signal("currency_changed", "gold", player.gold, change)
	get():
		return(player.gold)
var upkeep: int:
	set(val):
		var change = val - upkeep
		upkeep = val
		emit_signal("currency_changed", "upkeep", upkeep, change)
var mana: int:
	set(val):
		val = clamp(val, 0, max_mana)
		var change = val - mana
		mana = val
		emit_signal("currency_changed", "mana", mana, change)
var max_mana: int:
	set(val):
		player.max_mana = val
	get():
		return(player.max_mana)
var spell_power: int = 0:
	set(val):
		var change = val - player.spell_power
		player.spell_power = val
		get_tree().call_group("SpellPowerCards", "set_card_text")
		emit_signal("currency_changed", "spell_power", spell_power, change)
	get():
		return(player.spell_power)
var snapshot_spell_power: int
var snapshot_mana: int
var snapshot_gold: int

########################################

var ui: UI
var Board: Combat
var draw: Pile
var hand: Hand
var Grid: UnitGrid
var discard: Pile
var energy: int:
	set(val):
		energy = val
		emit_signal("energy_changed")

########################################

const card_size := Vector2(200, 300)
const token_size := Vector2(120, 120)
const label_size := Vector2(170, 25)

func _ready() -> void:
	scene_changed.connect(reset_vars)

func reset_vars() -> void:
	var node_list = ["Board", "ui", "draw", "discard", "hand", "Grid"]
	for node in node_list:
		set(node, null)
