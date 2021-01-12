extends KinematicBody2D

onready var animation = $Animation
onready var raycast = $RayCast

var orientation = Vector2(1, 0)

var orientation_memory = 0

func _ready():
	pass

func update_animation(speed: Vector2):
	if speed == Vector2(0, 0):
		set_idle_animation()
	else:
		# makes it more achievable to maintain a diagonal direction after releasing the buttons and missing a frame
		if speed.normalized() != orientation:
			if orientation_memory == 1:
				set_orientation(speed.normalized())
				orientation_memory = 0
			else:
				orientation_memory += 1
		
#		orientation = speed.normalized()
		set_walk_animation()
		
func set_orientation(new_orientation: Vector2):
	orientation = new_orientation
	var direction = get_direction()
	
	if direction == "right":
		raycast.cast_to = Vector2(32, 0)
#		raycast.rotation_degrees = 0.0
	elif direction == "up_rigt":
		raycast.cast_to = Vector2(32, -32)
#		raycast.rotation_degrees = -45
	elif direction == "up":
		raycast.cast_to = Vector2(0, -32)
#		raycast.rotation_degrees = -90
	elif direction == "up_left":
		raycast.cast_to = Vector2(-32, -32)
#		raycast.rotation_degrees = -135
	elif direction == "left":
		raycast.cast_to = Vector2(-32, 0)
#		raycast.rotation_degrees = -180
	elif direction == "down_left":
		raycast.cast_to = Vector2(-32, 32)
#		raycast.rotation_degrees = -225
	elif direction == "down":
		raycast.cast_to = Vector2(0, 32)
#		raycast.rotation_degrees = -270
	elif direction == "down_right":
		raycast.cast_to = Vector2(32, 32)
#		raycast.rotation_degrees = -315
		

func _set_directional_animation(animation_name: String):
	var directional_animation_name = animation_name + "_" + get_direction()
	if not directional_animation_name in animation.frames.get_animation_names():
		print("Animation " + animation_name + "does not exist for " + name)
	_set_animation(directional_animation_name)
	
func _set_animation(animation_name: String):
	if animation.animation != animation_name:
		animation.animation = animation_name

func set_idle_animation():
	_set_directional_animation("idle")
	
func set_walk_animation():
	_set_directional_animation("walk")
	
func get_direction():
	if orientation.x > sqrt(3)/2:
		return "right"
	elif orientation.x < -sqrt(3)/2:
		return "left"
	elif orientation.y > sqrt(3)/2:
		return "down"
	elif orientation.y < -sqrt(3)/2:
		return "up"
	elif orientation.x > 0 and orientation.y > 0:
		return "down_right"
	elif orientation.x > 0 and orientation.y < 0:
		return "up_right"
	elif orientation.x < 0 and orientation.y > 0:
		return "down_left"
	elif orientation.x < 0 and orientation.y < 0:
		return "up_left"

export var movement_speed: float = 200.0


var current_interactable

signal interacted(interactable)

func _ready():
	pass
	

func _physics_process(delta):
	var velocity = Vector2(0, 0)
	var speed_factor = 1.0
	
	if Input.is_action_pressed("sprint"):
		speed_factor *= 2.0

	if Input.is_action_pressed("ui_left"):
		velocity.x -= movement_speed * speed_factor
		
	if Input.is_action_pressed("ui_right"):
		velocity.x += movement_speed * speed_factor
		
	if Input.is_action_pressed("ui_down"):
		velocity.y += movement_speed * speed_factor
		
	if Input.is_action_pressed("ui_up"):
		velocity.y -= movement_speed * speed_factor

	
	if raycast.is_colliding():
		var interactable = raycast.get_collider()
		if current_interactable != interactable:
			if current_interactable:
				current_interactable.deactivate()
			current_interactable = interactable
			current_interactable.activate()
	else:
		if current_interactable:
			current_interactable.deactivate()
			current_interactable = null

	if Input.is_action_just_pressed("ui_accept"):
		print(current_interactable)
		if current_interactable:
			emit_signal("interacted", current_interactable)
#			current_interactable.interact()
		
	update_animation(velocity)
	
	# fixes sliding along when pressed against an NPC
	move_and_slide(velocity, orientation.normalized())
	
func interacting(interactable_path: String):
	emit_signal("interacted", get_node(interactable_path))