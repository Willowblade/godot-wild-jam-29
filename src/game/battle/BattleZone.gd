extends Area2D
class_name BattleZone

onready var player_position = $PlayerPosition

export (String) var battle_id = ""

signal player_entered(battle_zone)


var enemies = []

func _ready():
	if battle_id == "":
		battle_id = name

func _on_body_entered(body: Node):
	if body is Enemy:
		print("Enemy entered! ", body.name)
		enemies.append(body)
	if body is Player:
		print("Player entered! ", body.name)
		emit_signal("player_entered", self)
