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
onready var battle_status: BattleStatus = $BattleStatus

onready var tween: Tween = $Tween
onready var camera_tween: Tween = $CameraTween

onready var target_selector: Sprite = $TargetSelector

onready var state = LevelState.EXPLORING

onready var damage_label = $DamageLabel

var current_floor_player = null
var camera_transition_target = null
var current_battle_zone: BattleZone = null

export var EAGLE_ZOOM = 1.2

func _ready():
	eagle.set_player(player)

	GameFlow.overlays.battle.connect("move_chosen", self, "_on_attack_move_chosen")
	GameFlow.overlays.battle.connect("target_enemy", self, "_on_target_enemy")
	GameFlow.overlays.hud.set_explore_mode()
	battle_status.connect("character_ready", self, "_on_character_attack_ready")

	for battle_zone in get_tree().get_nodes_in_group("battle_zone"):
		battle_zone.connect("player_entered", self, "_on_player_entered_battle_zone")

	player.connect("damage_taken", self, "_on_target_take_damage")
	# player.connect("death", self, "_on_target_death")


func _on_character_attack_ready(character):
	if character is Player:
		battle_status.stop_charging()
		GameFlow.overlays.battle.resume()
	elif character is Eagle:
		eagle_attack()
	elif character is Enemy:
		enemy_attack(character)


func eagle_attack():
	battle_status.performed_move = {
		"definition": {
			"damage": 8
		}
	}
	# todo this might need a cleanup at some point
	eagle.set_physics_process(false)
	battle_status.stop_charging()
	var enemies = current_battle_zone.enemies
	var enemy: Enemy = enemies[randi() % enemies.size()]
	var target = enemy.position + enemy.eagle_point
	eagle.patrol_timer += PI / eagle.CIRCLE_ROTATION_SPEED
	eagle.direction = (target - eagle.position).normalized() * 10
	eagle.set_animation(eagle.direction)
	var should_flip = false
	if eagle.position.x > enemy.position.x:
		should_flip = true
		
	var duration = eagle.position.distance_to(target) / eagle.MOVEMENT_SPEED / 1
	tween.interpolate_property(eagle, "position", null, target, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(eagle.shadow, "position", null, Vector2(22, 22), duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	eagle.set_physics_process(true)
	tween.interpolate_property(eagle.shadow, "position", null, Vector2(44, 44), max(1 - duration, 0.5), Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	# TODO define some eagle moves and enemy reacts, maybe add claw effect too? Some blood particles...
	if should_flip:
		enemy.scale = Vector2(-1, 1)
	enemy.play_animation("throw")
	yield(enemy.animation_player, "animation_finished")
	if enemy.dead:
		_on_target_death(enemy)
	enemy.scale = Vector2(1, 1)
	update_battle()


func enemy_attack(enemy: Enemy):
	print("Enemy attacking!")
	battle_status.performed_move = {
		"definition": {
			"damage": 30
		}
	}
	battle_status.stop_charging()
	# TODO pick a move from available moves...
	var enemy_start_position = enemy.position + Vector2()
	var target = player.position + Vector2(-6, -8)
	enemy.sprite.speed_scale = 2.0
	var duration = enemy.position.distance_to(target) / player.MOVEMENT_SPEED / 2
	tween.interpolate_property(enemy, "position", null, target, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	enemy.sprite.speed_scale = 1.0
	tween.interpolate_property(enemy, "position", null, target + Vector2(0, 4), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	player.animation_player.play("throw")
	tween.interpolate_property(enemy, "position", null, target, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(player.animation_player, "animation_finished")
	if player.dead:
		print("Whatwhat")
		_on_target_death(player)
		yield(player.die(), "completed")
		update_battle()
		return

	tween.interpolate_property(enemy, "position", null, enemy_start_position, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	update_battle()

func _on_player_entered_battle_zone(battle_zone: BattleZone):
	
	print("Starting battle")
	if battle_zone.enemies.size() == 0:
		print("No enemies here, not doing anything")
	for enemy in battle_zone.enemies:
		enemy.connect("damage_taken", self, "_on_target_take_damage")
		# enemy.connect("death", self, "_on_target_death")

	current_battle_zone = battle_zone
	switch_state(LevelState.BATTLE)
	print(battle_zone.enemies)

func _on_attack_move_chosen(move, target):
	battle_status.performed_move = move
	print("Attack move chosen!!")
	player.perform_action(move.definition.cost)
	GameFlow.overlays.battle.pause()
	target_selector.hide()

	var enemy = target.target

	yield(move_player_to_enemy(target.target), "completed")
	tween.interpolate_property(player, "position", null, player.position - Vector2(0, 6), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	enemy.play_animation(move.move)
	tween.interpolate_property(player, "position", null, player.position + Vector2(0, 6), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(enemy.animation_player, "animation_finished")
	if enemy.dead:
		_on_target_death(enemy)
	yield(move_player_to_battle_zone(), "completed")

	update_battle()

func update_battle():
	if battle_status.number_of_enemies == 0:
		switch_state(LevelState.EXPLORING)
		GameFlow.overlays.hud.set_explore_mode()
		GameFlow.overlays.battle.stop()
	elif player.dead:
		# big TODO
		set_process(false)
		battle_status.stop_charging()
		GameFlow.overlays.game_over.show()
	else:
		battle_status.start_charging()


func move_player_to_enemy(enemy: Enemy):
	var enemy_position = enemy.position + Vector2(6, 12)
	player.set_animation(enemy_position - player.position)
	var duration = player.position.distance_to(enemy_position) / player.MOVEMENT_SPEED / 2
	player.sprite.speed_scale = 2.0
	tween.interpolate_property(player, "position", null, enemy_position, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	player.sprite.speed_scale = 1.0
	player.set_animation(enemy.position - player.position)
	player.set_animation(Vector2(0, 0))
	
func move_player_to_battle_zone():
	var duration = player.position.distance_to(current_battle_zone.position + current_battle_zone.player_position.position) / player.MOVEMENT_SPEED / 2
	player.sprite.speed_scale = 2.0
	player.set_animation(current_battle_zone.position + current_battle_zone.player_position.position - player.position)
	tween.interpolate_property(player, "position", null, current_battle_zone.position + current_battle_zone.player_position.position, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	player.sprite.speed_scale = 1.0
	player.set_animation(current_battle_zone.position - player.position)

func show_damage_popup(damage_amount, damage_position):
	damage_label.text = str(damage_amount)
	damage_label.rect_position = damage_position - Vector2(10, 0) + Vector2(0, -4)
	damage_label.show()
	yield(get_tree().create_timer(0.5), "timeout")
	damage_label.hide()

func _on_target_death(target):
	# TODO use death animation...
	if target is Enemy:
		GameFlow.overlays.battle.on_enemy_death(target)
		battle_status.remove_enemy(target)
		target.die()
		
func _on_target_take_damage(target, target_position):
	var damage = battle_status.performed_move.definition.damage
	target.take_damage(damage)
	show_damage_popup(damage, target.position + target.visual.position + Vector2(0, -8).rotated(target.visual.rotation))

func _on_target_enemy(target):
	if target == null:
		target_selector.hide()
	else:
		target_selector.show()
		target_selector.position = target.target.position + target.target.selector_point

func _process(delta):
	_process_inputs(delta)

	var floor_player = floors.get_tile_floor(player.position)
	if floor_player != current_floor_player:
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
	camera_tween.interpolate_property(eagle.sprite, "scale", null, Vector2(1.8, 1.8) * EAGLE_ZOOM, 0.8, Tween.TRANS_CUBIC, Tween.EASE_IN)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	state = LevelState.FLIGHT

func transition_to_player_from_battle():
	state = LevelState.TRANSITION
	# TODO replace by a fade to black perhaps?
	
	camera_tween.stop_all()
	camera.position = Vector2(0, 0)
	eagle.set_physics_process(false)

	# add_child(camera)
	camera.smoothing_enabled = false
	camera_tween.interpolate_property(camera, "position", null, player.position - current_battle_zone.position, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	eagle.set_physics_process(true)
	current_battle_zone.remove_child(camera)
	camera.position = Vector2(0, 0)
	player.add_child(camera)
	camera.smoothing_enabled = true
	var new_zoom = Vector2(0.5, 0.5) / pow(1.1, current_floor_player)
	camera_tween.interpolate_property(camera, "zoom", null, new_zoom, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	state = LevelState.EXPLORING


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
	
func transition_to_battle_zone_from_player():
	state = LevelState.TRANSITION
	
	camera_tween.stop_all()
	tween.stop_all()
	camera.position = Vector2(0, 0)
	
	# add_child(camera)
	camera.smoothing_enabled = false
	eagle.set_physics_process(false)
	player.remove_child(camera)
	
	add_child(camera)
	camera.position = player.position

	move_player_to_battle_zone()
		
	camera_tween.interpolate_property(camera, "position", null, current_battle_zone.position, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	eagle.set_physics_process(true)
	remove_child(camera)
	camera.position = Vector2(0, 0)
	current_battle_zone.add_child(camera)
	camera.smoothing_enabled = true
		
	state = LevelState.BATTLE

func switch_state(new_state: int):
	if new_state == LevelState.FLIGHT:
		player.set_still()
		yield(transition_to_eagle_flight(), "completed")
		eagle.set_free()
	elif new_state == LevelState.EXPLORING:
		if state == LevelState.FLIGHT:
			eagle.set_player(player)
			eagle.set_follow()
			yield(transition_to_player_from_flight(), "completed")
			player.set_moving()
		elif state == LevelState.BATTLE:
			eagle.set_player(player)
			eagle.set_follow()
			yield(transition_to_player_from_battle(), "completed")
			player.set_moving()
	elif new_state == LevelState.BATTLE:
		player.set_still()
		eagle.set_battle_zone(current_battle_zone)
		eagle.set_battle()
		yield(transition_to_battle_zone_from_player(), "completed")
		GameFlow.overlays.battle.set_player(player)
		GameFlow.overlays.battle.set_battle_zone(current_battle_zone)
		GameFlow.overlays.battle.start()
		GameFlow.overlays.hud.set_battle_mode()

		battle_status.set_chargers([player, eagle] + current_battle_zone.enemies)
		battle_status.start_charging()

func counter_scale_camera(delta, increase):
	var current_zoom = camera.zoom.x
	var new_zoom = max(0.6, min(2.0, current_zoom + 0.3 * delta * increase))
	camera.zoom = Vector2(new_zoom, new_zoom)
	eagle.sprite.scale = 2 * camera.zoom * EAGLE_ZOOM

func _process_inputs(delta):
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
