extends Area2D
class_name BattleZone

onready var player_position = $PlayerPosition

export (String) var battle_id = ""

signal player_entered(battle_zone)

var triggered = false
var started = false

var enemies = []
var completed = false

func _ready():
	if battle_id == "":
		battle_id = name
	triggered = Flow.get_battle_value(battle_id, "triggered", false)
	var existing_battle = State.get_battle_by_id(battle_id)
	if existing_battle != null:
		completed = existing_battle.completed

func battle_completed():
	completed = true
	State.add_new_battle(battle_id)

func remove_enemy(enemy: Enemy):
	if enemies.has(enemy):
		enemies.erase(enemy)
		
func trigger_start():
	started = true
	for enemy in enemies:
		print("Showing in battle zone ", enemy)
		enemy.show()

func _on_body_entered(body: Node):
	if body is Enemy:
		if triggered and !started:
			body.hide()
			body.collision_layer = 0
			body.collision_mask = 0
		if completed:
			body.queue_free()
		else:
			enemies.append(body)
	if body is Player:
		if not completed and not triggered:
			emit_signal("player_entered", self)
