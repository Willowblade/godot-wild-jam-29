# State is an autoload script that contains all global state variables.
extends Node

var _upgrade_resource := preload("res://src/autoload/state/Upgrade.gd")
var _player_resource := preload("res://src/autoload/state/Player.gd")

### GLOBAL CONSTANTS ##########################################################

## STATE ######################################################################

func load_state_from_context(context : Dictionary):
	print_debug("Loading state from the context...")

	players.clear()
	upgrades.clear()

	# UPGRADES NEEDS TO BE CREATED FIRST!!!
	for upgrade_context in context.get("upgrades", {}):
		add_upgrade_from_context(upgrade_context)

	for player_context in context.get("players", {}):
		add_player_from_context(player_context)

func save_state_to_context() -> Dictionary:
	var context := {}

	var context_dict := {
		"players": players,
		"upgrades": upgrades,
	}

	for key in context_dict.keys():
		context[key] = []
		for context_owner in context_dict[key]:
			var subcontext : Dictionary = context_owner.context
			if not subcontext.empty():
				context[key].append(subcontext)

	return context

## PLAYERS ####################################################################
var players := []

func add_new_player(player_id : String) -> void:
	var player := _player_resource.new()
	player.id = player_id

	print_debug("adding brand-new player with id '{0}' to State!".format([player_id]))
	players.append(player)

func add_player_from_context(player_context : Dictionary) -> void:
	var player := _player_resource.new()
	player.context = player_context

	players.append(player)

func get_player_by_id(player_id : String):
	for player in players:
		if player.id == player_id:
			return player
	push_error("player with id '{0}' is not available in the State!".format([player_id]))
	return null

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

