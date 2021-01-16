extends Area2D
class_name BattleZone

onready var player_position = $PlayerPosition

export (String) var battle_id = ""

signal player_entered(battle_zone)


var enemies = []
var completed = false

func _ready():
	if battle_id == "":
		battle_id = name
	var existing_battle = State.get_battle_by_id(battle_id)
	if existing_battle != null:
		completed = existing_battle.completed

func battle_completed():
	completed = true
	State.add_new_battle(battle_id)

func remove_enemy(enemy: Enemy):
	if enemies.has(enemy):
		enemies.erase(enemy)

func _on_body_entered(body: Node):
	if body is Enemy:
		if completed:
			body.queue_free()
		else:
			enemies.append(body)
	if body is Player:
		if not completed:
			emit_signal("player_entered", self)
