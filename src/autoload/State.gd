# State is an autoload script that contains all global state variables.
extends Node

var _upgrade_resource := preload("res://src/autoload/state/Upgrade.gd")
var _player_resource := preload("res://src/autoload/state/Player.gd")
var _battle_resource := preload("res://src/autoload/state/Battle.gd")

### GLOBAL CONSTANTS ##########################################################

## STATE ######################################################################

func load_state_from_context(context : Dictionary):
	print_debug("Loading state from the context...")

	player = null
	upgrades.clear()
	battles.clear()



	# UPGRADES NEEDS TO BE CREATED FIRST!!!
	for upgrade_context in context.get("upgrades", {}):
		add_upgrade_from_context(upgrade_context)
		
	for battle_context in context.get("battles", {}):
		add_battle_from_context(battle_context)

	add_player_from_context(context.get("player", {}))
		
func save_state_to_context() -> Dictionary:
	var context := {}

	var context_dict := {
		"player": player,
		"upgrades": upgrades,
		"battles": battles,
	}

	for key in ["upgrades", "battles"]:
		context[key] = []
		for context_owner in context_dict[key]:
			var subcontext : Dictionary = context_owner.context
			if not subcontext.empty():
				context[key].append(subcontext)
	
	context["player"] = player.context

	return context

## PLAYERS ####################################################################
var player: class_player = null

func add_player_from_context(player_context : Dictionary) -> void:
	player = _player_resource.new()
	player.context = player_context

## UPGRADES ####################################################################
var upgrades := []

func add_new_upgrade(upgrade_id : String) -> void:
	var upgrade := _upgrade_resource.new()
	upgrade.id = upgrade_id

	print_debug("adding brand-new upgrade with id '{0}' to State!".format([upgrade_id]))
	upgrades.append(upgrade)

func add_upgrade_from_context(upgrade_context : Dictionary) -> void:
	var upgrade := _upgrade_resource.new()
	upgrade.context = upgrade_context

	upgrades.append(upgrade)

func get_upgrades_by_id() -> Array:
	var upgrade_ids := []
	for upgrade in upgrades:
		upgrade_ids.append(upgrade.id)
	return upgrade_ids


## BATTLES ####################################################################
var battles := []

func add_new_battle(battle_id : String) -> void:
	var battle := _battle_resource.new()
	battle.id = battle_id
	battle.completed = true

	battles.append(battle)

func add_battle_from_context(battle_context : Dictionary) -> void:
	var battle := _battle_resource.new()
	battle.context = battle_context

	battles.append(battle)

func get_battles_by_id() -> Array:
	var battle_ids := []
	for battle in battles:
		battle_ids.append(battle.id)
	return battle_ids

func get_battle_by_id(id: String):
	for battle in battles:
		if battle.id == id:
			return battle
