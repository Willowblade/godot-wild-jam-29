extends Node
class_name BattleStatus

signal updated_charge(updated_chargers)
signal character_ready(character)

var chargers = []

var performed_move = null

var number_of_enemies = 0

func _ready():
	connect("updated_charge", GameFlow.overlays.hud, "_on_updated_charges")
	
func set_chargers(new_chargers):
	number_of_enemies = 0
	chargers = []
	for charger in new_chargers:
		if charger is Enemy:
			number_of_enemies += 1
		chargers.append({
			"character": charger,
			"progress": 0,
			"threshold": charger.get_charge_timeout()
		})
	emit_signal("updated_charge", chargers)


func remove_enemy(enemy: Enemy):
	var sought_charger = null
	for charger in chargers:
		if charger.character == enemy:
			sought_charger = charger
	chargers.erase(sought_charger)
	number_of_enemies -= 1

func start_charging():
	performed_move = null
	set_process(true)

func stop_charging():
	set_process(false)

func _process(delta):
	for charger in chargers:
		charger.progress += delta
	
	emit_signal("updated_charge", chargers)
	for charger in chargers:
		if charger.progress > charger.threshold:
			print("Character ", charger.character, " is ready for its attack!")
			charger.progress = 0
			emit_signal("character_ready", charger.character)
			return
