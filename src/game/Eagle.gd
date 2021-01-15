extends KinematicBody2D
class_name Eagle

export var ROTATION_SPEED = 2
export var MOVEMENT_SPEED = 150
export var CIRCLE_RADIUS = 150
export var CIRCLE_ROTATION_SPEED = 0.6

onready var sprite: AnimatedSprite = $Sprite
onready var tween: Tween = $Tween
onready var target_sprite: Sprite = $Target
onready var shadow: AnimatedSprite = $Shadow

var direction = Vector2(10, 0)

enum MovementState {
	FREE,
	FOLLOW,
	BATTLE
}

var state = MovementState.FOLLOW

var patrol_timer = 0.0

var player: Player = null
var battle_zone: BattleZone = null

var rotation_direction = 1

var speed = 0
var target: Vector2 = Vector2(0, 0)
var radius = 0

var stats = {
	"timeout": 5.5
}


func _ready():
	pass

func set_player(new_player: Player):
	player = new_player
	
func set_battle_zone(new_battle_zone: BattleZone):
	battle_zone = new_battle_zone


func update_target():
	var fake_time = patrol_timer * CIRCLE_ROTATION_SPEED
	if state == MovementState.FOLLOW:
		target = player.position - position + radius * Vector2(cos(fake_time), sin(fake_time) / 2)
	elif state == MovementState.BATTLE:
		target = battle_zone.position + Vector2(0, -25) - position + radius * Vector2(cos(fake_time), sin(fake_time) / 2)

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

func get_charge_timeout() -> float:
	return 8.0

func set_animation(velocity: Vector2):	
	var animation_direction = get_direction(velocity)
	if velocity == Vector2(0, 0):
		if sprite.playing:
			sprite.playing = false
			shadow.playing = false
		sprite.frame = 1
		shadow.frame = 1
	else:
		sprite.animation = animation_direction
		shadow.animation = animation_direction
		if !sprite.playing:
			sprite.playing = true
			shadow.playing = true

func set_start_position():
	patrol_timer = randf() * 2 * PI
	update_target()
	position = target
		
func set_free():
	state = MovementState.FREE
	shadow.hide()
	tween.stop_all()

func set_follow():
	state = MovementState.FOLLOW
	shadow.show()
	tween.stop_all()
	
func set_battle():
	state = MovementState.BATTLE
	shadow.show()
	tween.stop_all()

	
func move_left(delta):
	direction = direction.rotated(ROTATION_SPEED * delta)

func move_right(delta):
	direction = direction.rotated(-ROTATION_SPEED * delta)

func get_quarter():
	# TODO figure out how to do this well
	pass

func set_full_animation(animation_name):
	shadow.animation = animation_name
	sprite.animation = animation_name
	
func move_towards_target(delta):
	target_sprite.position = target
	$Direction.position = direction
	# print(direction.angle_to(target - position))
	var angle = direction.angle_to(target)
	if angle > 0:
		move_left(delta)
	else:
		move_right(delta)
	# snap to correct direction if necessary
	if abs(angle) < 0.01:
		direction = target.normalized() * 10
			
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
		move_towards_target(delta)
	elif state == MovementState.BATTLE:
		radius = CIRCLE_RADIUS * 1.2
		speed = sqrt(2)/2 * radius * CIRCLE_ROTATION_SPEED
		patrol_timer += delta * rotation_direction
		update_target()
		move_towards_target(delta)
			
	set_animation(direction.normalized())
	
	var collision = move_and_collide(direction.normalized() * speed * delta)
	if collision != null:
		move_right(delta)
	
