extends KinematicBody2D
class_name Player

onready var sprite: AnimatedSprite = $Sprite

export var MOVEMENT_SPEED: float = 50.0

signal interact

var direction = Vector2(1, 0)


var state = "IDLE"

func _ready():
	pass


func get_direction(velocity: Vector2):
	var normalized_velocity = velocity.normalized()
	if normalized_velocity.x > sqrt(3)/2:
		return "e"
	elif normalized_velocity.x < -sqrt(3)/2:
		return "w"
	elif normalized_velocity.y > sqrt(3)/2:
		return "s"
	elif normalized_velocity.y < -sqrt(3)/2:
		return "n"
	elif normalized_velocity.x > 0 and normalized_velocity.y > 0:
		return "se"
	elif normalized_velocity.x > 0 and normalized_velocity.y < 0:
		return "ne"
	elif normalized_velocity.x < 0 and normalized_velocity.y > 0:
		return "sw"
	elif normalized_velocity.x < 0 and normalized_velocity.y < 0:
		return "nw"
			
func set_animation(velocity: Vector2):	
	var animation_direction = get_direction(velocity)
	if velocity == Vector2(0, 0):
		state = "IDLE"
		if sprite.playing:
			sprite.playing = false
		sprite.frame = 1
	else:
		sprite.animation = animation_direction
		if !sprite.playing:
			sprite.playing = true
		state = "MOVING"		
	
func player_specific(delta):
	pass

func set_moving():
	set_physics_process(true)

func set_still():
	set_physics_process(false)
			
func _physics_process(delta):
	player_specific(delta)
	
	var velocity = Vector2(0, 0)
	var speed_factor = 1.0
	
	if Input.is_action_pressed("move_left"):
		velocity.x -= MOVEMENT_SPEED * speed_factor
		
	if Input.is_action_pressed("move_right"):
		velocity.x += MOVEMENT_SPEED * speed_factor
		
	if Input.is_action_pressed("move_down"):
		velocity.y += MOVEMENT_SPEED * speed_factor
		
	if Input.is_action_pressed("move_up"):
		velocity.y -= MOVEMENT_SPEED * speed_factor
		
	if Input.is_action_just_pressed("interact"):
		emit_signal("interact")
		
	if Input.is_action_just_pressed("debugging"):
		pass
		
	set_animation(velocity)
	
	move_and_slide(velocity)
