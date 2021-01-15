extends KinematicBody2D
class_name Enemy

signal damage_taken(enemy, damage_position)
signal death(enemy)

export var id = ""

onready var visual: Node2D = $Visual
onready var sprite: AnimatedSprite = $Visual/Sprite
onready var animation_player: AnimationPlayer = $AnimationPlayer

var selector_point := Vector2(0, 0)
var eagle_point := Vector2(0, 0)

# TODO get from game data
onready var stats = {
	"health": 20,
	"timeout": 1.5,
	"damage": 0.8,
}

var dead = false


func trigger_damage_taken():
	emit_signal("damage_taken", self, visual.position)

func _ready():
	if id == "":
		print("Bad ID! for enemy", name)
	var sprite_frames = sprite.frames
	var texture = sprite_frames.get_frame(sprite.animation, 0)
	selector_point = Vector2(-texture.get_width() / 2 - 5, - texture.get_height() / 2) - sprite.position
	eagle_point = sprite.position + Vector2(0, -texture.get_height()/4)

func play_animation(animation_name: String):
	animation_player.play(animation_name)

func take_damage(damage_amount: int):
	stats.health -= damage_amount
	if stats.health <= 0:
		dead = true
		emit_signal("death", self)

func get_charge_timeout() -> float:
	return stats.timeout

func die():
	animation_player.play("death")
	yield(animation_player, "animation_finished")
	queue_free()
