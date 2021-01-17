extends Reference
class_name class_player

var level := 1
var experience := 0
var location := {
	"location": "overworld",
	"position": Vector2(0, 0),
}

var conditions = []

var context : Dictionary setget set_context, get_context
func set_context(value : Dictionary) -> void:
	level = value.get("level", 1)
	experience = value.get("experience", 0)
	location = value.get("location", 0)
	conditions = value.get("conditions", [])

func get_context() -> Dictionary:
	var _context := {}
	
	_context.level = level
	_context.experience = experience
	_context.location = location
	_context.conditions = conditions

	return _context
	
func get_player_level_effect(level_index: int) -> Dictionary:
	return {
		"health": int(6 * (1 + level_index / 3)),
		"stamina": int(4 * (1 + level_index / 2)),
		"strength": 0.1,
		"defense": +0.08
	}
	
func get_eagle_level_effect(level_index: int) -> Dictionary:
	return {
		"strength": 0.15,
	}

func add_condition(condition: String):
	if conditions.has(condition):
		return
	conditions.append(condition)

func has_condition(condition: String):
	return conditions.has(condition)
	
func get_level():
	if experience > 600:
		return 9
	elif experience > 470:
		return 8
	elif experience > 350:
		return 7
	elif experience > 250:
		return 6
	elif experience > 170:
		return 5
	elif experience > 100:
		return 4
	elif experience > 50:
		return 3
	elif experience > 20:
		return 2
	return 1
	
func get_level_effects() -> Array:
	var actual_level = get_level()
	var upgrades = []
	for i in range(1, level):
		upgrades.append({
			"name": "playerlevel" + str(i),
			"target": "player",
			"effects": get_player_level_effect(i)
		})
		upgrades.append({
			"name": "eaglelevel" + str(i),
			"target": "eagle",
			"effects": get_eagle_level_effect(i)
		})
	return upgrades

func get_stats() -> Dictionary:
	var stats: Dictionary = get_base_stats().duplicate(true)
	for upgrade in State.upgrades + get_level_effects():
		var upgrade_target = Flow.get_upgrade_value(upgrade.id, "target", "player")
		var upgrade_effects = Flow.get_upgrade_value(upgrade.id, "effects", {})
		if upgrade_target == "player":
			var effect = upgrade_effects
			for key in effect:
				stats[key] += effect[key]
	return stats

func get_eagle_stats() -> Dictionary:
	var stats: Dictionary = get_base_eagle_stats().duplicate(true)
	for upgrade in State.upgrades:
		if upgrade.target == "eagle":
			var effect = upgrade.effect
			for key in effect:
				stats[key] += effect[key]
	return stats

var base_stats : Dictionary setget , get_base_stats
func get_base_stats():
	return Flow.get_player_value("base_stats", PLAYER_BASE_STATS)

var base_eagle_stats : Dictionary setget , get_base_eagle_stats
func get_base_eagle_stats():
	return Flow.get_eagle_value("base_stats", EAGLE_BASE_STATS)

const PLAYER_BASE_STATS := {

}

const EAGLE_BASE_STATS := {
	
}
