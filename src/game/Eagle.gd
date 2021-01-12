extends KinematicBody2D
class_name Eagle

export var ROTATION_SPEED = 2
export var MOVEMENT_SPEED = 150
export var CIRCLE_RADIUS = 150
export var CIRCLE_ROTATION_SPEED = 0.6

onready var sprite: AnimatedSprite = $Sprite
onready var tween: Tween = $Tween
onready var target_sprite: Sprite = $Target

var direction = Vector2(10, 0)

enum MovementState {
	FREE,
	FOLLOW,
	BATTLE
}

var state = MovementState.FOLLOW

var patrol_timer = 0.0

var player: Player = null

var rotation_direction = 1

var speed = 0
var target: Vector2 = Vector2(0, 0)
var radius = 0


func _ready():
	pass

func set_player(new_player: Player):
	player = new_player


func update_target():
	var fake_time = patrol_timer * CIRCLE_ROTATION_SPEED
	target = player.position - position + radius * Vector2(cos(fake_time), sin(fake_time) / 2) 


func set_flip(velocity: Vector2):
	if velocity.x > 0:
		if sprite.flip_h == false:
			sprite.flip_h = true
			$Shadow.flip_h = true

	elif velocity.x < 0:
		if sprite.flip_h == true:
			sprite.flip_h = false
			$Shadow.flip_h = false

func set_start_position():
	patrol_timer = randf() * 2 * PI
	update_target()
	position = target
			
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
		set_full_animation("up")
	elif velocity.y > 0:
		set_full_animation("down")
	else:
		set_full_animation("idle")
		
func set_free():
	state = MovementState.FREE
	$Shadow.hide()
	tween.stop_all()

func set_follow():
	state = MovementState.FOLLOW
	$Shadow.show()
	tween.stop_all()

func move_left(delta):
	direction = direction.rotated(ROTATION_SPEED * delta)

func move_right(delta):
	direction = direction.rotated(-ROTATION_SPEED * delta)

func get_quarter():
	# TODO figure out how to do this well
	pass

func set_full_animation(animation_name):
	$Shadow.animation = animation_name
	sprite.animation = animation_name
			
func _physics_process(delta):
	if player == null:
		return
		
	if state == MovementState.FREE:
		if sprite.scale.x > 2:
			speed = MOVEMENT_SPEED * sqrt(sprite.scale.x / 2)
		else:
			speed = MOVEMENT_SPEED * sprite.scale.x / 2
		
		if Input.is_action_pressed("move_left"):
			move_right(delta)
			
		if Input.is_action_pressed("move_right"):
			move_left(delta)
		target_sprite.position = target
		$Direction.position = direction
	elif state == MovementState.FOLLOW:
		radius = CIRCLE_RADIUS
		if player.state == "MOVING":
			radius = CIRCLE_RADIUS / 4
			if player.position.distance_to(position) > 500:
				speed = MOVEMENT_SPEED
			else:
				speed = player.MOVEMENT_SPEED + 10
		elif player.state == "IDLE":
			patrol_timer += delta * rotation_direction
			speed = sqrt(2)/2 * CIRCLE_RADIUS * CIRCLE_ROTATION_SPEED
		update_target()
		target_sprite.position = target
		$Direction.position = direction
		print(direction.angle_to(target))
		# print(direction.angle_to(target - position))
		var angle = direction.angle_to(target)
		if angle > 0:
			move_left(delta)
		else:
			move_right(delta)
		# snap to correct direction if necessary
		if abs(angle) < 0.01:
			print("Normalizing this!!")
			direction = target.normalized() * 10
		
	set_flip(direction.normalized())
	set_animation(direction.normalized())
	
	var collision = move_and_collide(direction.normalized() * speed * delta)
	if collision != null:
		print("COLLIDING!")
		move_right(delta)
	
