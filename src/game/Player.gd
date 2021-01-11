extends KinematicBody2D
class_name Player

onready var sprite: AnimatedSprite = $Sprite


signal interact

var direction = Vector2(1, 0)

const MOVEMENT_SPEED: float = 50.0

var state = "IDLE"

func _ready():
	pass


func set_flip(velocity: Vector2):
	if velocity.x > 0:
		if sprite.flip_h == false:
			sprite.flip_h = true

	elif velocity.x < 0:
		if sprite.flip_h == true:
			sprite.flip_h = false
			
func set_animation(velocity: Vector2):	
#	if velocity.x < 0:
#		sprite.animation = "walk"
#		if state != "HORIZONTAL_LEFT":
#			state = "HORIZONTAL_LEFT"
#	elif velocity.x > 0:
#		sprite.animation = "walk"
#		if state != "HORIZONTAL_RIGHT":
#			state = "HORIZONTAL_RIGHT"
#
	if velocity.y < 0:
		sprite.animation = "up"
		if state != "VERTICAL_UP":
			state = "VERTICAL_UP"

	elif velocity.y > 0:
		sprite.animation = "down"
		if state != "VERTICAL_DOWN":
			state = "VERTICAL_DOWN"
	else:
		sprite.animation = "idle"
		state = "IDLE"
		

func set_direction(velocity: Vector2):
	if velocity.x > 0:
		direction = Vector2(1, 0)
	elif velocity.x < 0:
		direction = Vector2(-1, 0)
	elif velocity.y < 0:
		direction = Vector2(0, -1)
	elif velocity.y > 0:
		direction = Vector2(0, 1)
	
func player_specific(delta):
	pass
			
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
		# GameState.grow()
		pass
		
	set_flip(velocity)
	set_animation(velocity)
	set_direction(velocity)
	
	move_and_collide(velocity * delta)
