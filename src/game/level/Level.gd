extends Node2D

enum LevelState {
	EXPLORING,
	FLIGHT,
	BATTLE,
	TRANSITION,
}

onready var player: Player = $YSort/Player
onready var floors: Node2D = $Floors
onready var camera: Camera2D = $YSort/Player/Camera
onready var eagle: Eagle = $Eagle

onready var tween: Tween = $Tween
onready var camera_tween: Tween = $Tween

onready var state = LevelState.EXPLORING

var current_floor_player = null
var camera_transition_target = null

func _ready():
	eagle.set_player(player)


func _process(delta):
	_process_inputs(delta)

	var floor_player = floors.get_tile_floor(player.position)
	if floor_player != current_floor_player:
		print("New floor player: ", floor_player)
		current_floor_player = floor_player
		floors.refresh(current_floor_player)
		
		transition_tiles(current_floor_player, 0.5)
			
		var new_zoom = Vector2(0.5, 0.5) / pow(1.1, current_floor_player)
		print(new_zoom)
		tween.interpolate_property(camera, "zoom", null, new_zoom, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
		tween.start()
		
func transition_tiles(floor_level, duration):
	var floors_below = floors.get_floors_below(floor_level)
	floors_below.invert()
	var floors_above = floors.get_floors_above(floor_level)
	var i = 2
	for floor_below in floors_below:
		print(floor_below.name)
		tween.interpolate_property(floor_below, "modulate", null, Color(1 - 0.04 * i, 1 - 0.04 * i, 1 - 0.04 * i), duration, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
		i += 1
	for floor_above in floors_above:
		print(floor_above.name)
		tween.interpolate_property(floor_above, "modulate", null, Color(1 , 1, 1 ), duration, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
		

func transition_to_eagle_flight():
	state = LevelState.TRANSITION
	
	camera_tween.stop_all()
	camera.position = Vector2(0, 0)
	
	# add_child(camera)
	camera.smoothing_enabled = false
	eagle.set_physics_process(false)
	camera_tween.interpolate_property(camera, "position", null, eagle.position - player.position, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	eagle.set_physics_process(true)
	player.remove_child(camera)
	camera.position = Vector2(0, 0)
	eagle.add_child(camera)
	camera.smoothing_enabled = true
	transition_tiles(2, 0.8)
	camera_tween.interpolate_property(camera, "zoom", null, Vector2(0.9, 0.9), 0.8, Tween.TRANS_CUBIC, Tween.EASE_IN)
	camera_tween.interpolate_property(eagle.sprite, "scale", null, Vector2(1.8, 1.8), 0.8, Tween.TRANS_CUBIC, Tween.EASE_IN)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	state = LevelState.FLIGHT

func transition_to_player_from_flight():
	state = LevelState.TRANSITION
	# TODO replace by a fade to black perhaps?
	
	camera_tween.stop_all()
	camera.position = Vector2(0, 0)
	eagle.set_physics_process(false)

	# add_child(camera)
	camera.smoothing_enabled = false
	camera_tween.interpolate_property(camera, "position", null, player.position - eagle.position, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	eagle.set_physics_process(true)
	eagle.remove_child(camera)
	camera.position = Vector2(0, 0)
	player.add_child(camera)
	camera.smoothing_enabled = true
	var new_zoom = Vector2(0.5, 0.5) / pow(1.1, current_floor_player)
	camera_tween.interpolate_property(camera, "zoom", null, new_zoom, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
	camera_tween.interpolate_property(eagle.sprite, "scale", null, Vector2(1.0, 1.0), 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
	transition_tiles(current_floor_player, 0.5)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	state = LevelState.EXPLORING

func switch_state(new_state: int):
	if new_state == LevelState.FLIGHT:
		player.set_still()
		transition_to_eagle_flight()
		eagle.set_free()
	elif new_state == LevelState.EXPLORING:
		eagle.set_follow()
		transition_to_player_from_flight()
		player.set_moving()


func counter_scale_camera(delta, increase):
	var current_zoom = camera.zoom.x
	var new_zoom = max(0.6, min(1.2, current_zoom + 0.3 * delta * increase))
	camera.zoom = Vector2(new_zoom, new_zoom)
	eagle.sprite.scale = 2 * camera.zoom

func _process_inputs(delta):
	print(camera.position)
	if state == LevelState.EXPLORING:
		if Input.is_action_just_pressed("switch"):
			print("Switch pressed!")
			switch_state(LevelState.FLIGHT)

	elif state == LevelState.FLIGHT:
		if Input.is_action_just_pressed("switch"):
			print("Switch pressed")
			switch_state(LevelState.EXPLORING)
		elif Input.is_action_pressed("move_up"):
			print("Moving up")
			counter_scale_camera(delta, 1)
		elif Input.is_action_pressed("move_down"):
			print("Moving down")
			counter_scale_camera(delta, -1)
		elif Input.is_action_pressed("move_right"):
			print("Moving right")
		elif Input.is_action_pressed("move_left"):
			print("Moving left")
