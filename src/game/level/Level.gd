extends Node2D

enum LevelState {
	EXPLORING,
	FLIGHT,
	BATTLE,
	TRANSITION,
}

enum LocationState {
	INSIDE,
	OUTSIDE
}

const ZOOM_PER_FLOOR = 1.04

onready var player: Player = $YSort/Player
onready var floors: Node2D = $Floors
onready var camera: Camera2D = $YSort/Player/Camera
onready var eagle: Eagle = $Eagle
onready var battle_status: BattleStatus = $BattleStatus

onready var tween: Tween = $Tween
onready var camera_tween: Tween = $CameraTween

onready var target_selector: Sprite = $TargetSelector

onready var state = LevelState.EXPLORING
onready var location_state = LocationState.OUTSIDE

onready var damage_label = $DamageLabel

var current_floor_player = null
var camera_transition_target = null
var current_battle_zone: BattleZone = null

var player_interactables = []

export var EAGLE_ZOOM = 1.1

var location = null

var yurts = {}
var yurt_interiors = {}
var battle_zones = {}
var dungeons = {}
var caves = {}
var cave_interiors = {}

var previous_interactables = null

func _ready():
	AudioEngine.play_ambiance()
	camera.smoothing_enabled = true
	AudioEngine.play_background_music("main2")

	GameFlow.overlays.battle.connect("move_chosen", self, "_on_attack_move_chosen")
	GameFlow.overlays.battle.connect("target_enemy", self, "_on_target_enemy")
	GameFlow.overlays.hud.set_explore_mode()
	battle_status.connect("character_ready", self, "_on_character_attack_ready")

	for battle_zone in get_tree().get_nodes_in_group("battle_zone"):
		battle_zone.connect("player_entered", self, "_on_player_entered_battle_zone")
		battle_zones[battle_zone.battle_id] = battle_zone
	player.connect("damage_taken", self, "_on_target_take_damage")
	# player.connect("death", self, "_on_target_death")

	for yurt in get_tree().get_nodes_in_group("yurt"):
		yurts[yurt.id] = yurt

	for yurt_interior in get_tree().get_nodes_in_group("yurt_interior"):
		if yurt_interior.id == "":
			push_error("Yurt has no valid id " + yurt_interior.name)
		yurt_interiors[yurt_interior.id] = yurt_interior

	for yurt_id in yurts:
		var yurt = yurts[yurt_id]
		var yurt_interior = yurt_interiors[yurt_id]
		yurt.match_yurt_interior(yurt_interior)
		yurt_interior.match_yurt(self, yurt)

	for cave in get_tree().get_nodes_in_group("cave"):
		caves[cave.id] = cave

	for cave_interior in get_tree().get_nodes_in_group("cave_interior"):
		if cave_interior.id == "":
			push_error("cave has no valid id " + cave_interior.name)
		cave_interiors[cave_interior.id] = cave_interior

	for cave_id in caves:
		var cave = caves[cave_id]
		var cave_interior = cave_interiors[cave_id]
		cave.match_cave_interior(cave_interior)
		cave_interior.match_entrance(self, cave)

	var spawn_location = State.player.location

	if spawn_location.location == "overworld":
		player.position = spawn_location.position
	elif spawn_location.location == "yurt":
		player.position = yurts[spawn_location.id].position + yurts[spawn_location.id].player_position.position
	
	player.set_animation(Vector2(0, 1))
	player.set_animation(Vector2(0, 0))
	eagle.set_player(player)
	eagle.set_start_position()

	if State.player.has_condition("started_game"):
		pass
	else:
		game_start_sequence()


func game_start_sequence():
	yield(show_begin(), "completed")
	GameFlow.overlays.begin.stop()
	show_dialogue({
		"dialogue": [
			{
				"speaker": "copy",
				"text": "Hey sleepyhead! Wake up! You're daydreaming again!",
				"animation": "angry",
			},
			{
				"speaker": "bataar",
				"text": "Wait, are you me?"
			},
			
			{
				"speaker": "copy",
				"text": "No Bataar, I am merely a storytelling device constructed in your own mind to visualize your subconsciousness.",
				"audio": "bataar_explaining",
				"animation": "none"
			},
			{
				"speaker": "copy",
				"text": "Anyway... Time for your mantras",
			},
			{
				"speaker": "copy",
				"text": "Walk around with the arrow keys",
			},
			{
				"speaker": "bataar",
				"text": "Walk around with the arrow keys",
			},
			{
				"speaker": "copy",
				"text": "Interact with E or Enter",
			},
			{
				"speaker": "bataar",
				"text": "Interact with E or Enter",
			},
			
			{
				"speaker": "copy",
				"text": "Choose wrestling moves and targets with arrows and E or Enter",
			},
			{
				"speaker": "bataar",
				"text": "Choose wrestling moves and targets with arrows and E or Enter",
			},
			
			{
				"speaker": "copy",
				"text": "Use the Tab key to use your eagle to navigate the desert",
			},
			{
				"speaker": "bataar",
				"text": "Use the Tab key to use your eagle to navigate the desert",
			},
			{
				"speaker": "copy",
				"text": "Up and down let Burg fly higher or lower, turn Burg with left and right",
			},
			{
				"speaker": "bataar",
				"text": "Up and down let Burg fly higher or lower, turn Burg with left and right",
			},
			{
				"speaker": "copy",
				"text": "Good! I see you still have them memorized",
			},
			{
				"speaker": "copy",
				"text": "If you don't want to see me again, I advise you to get some sleep inside the yurt, saving your progress",
			},
		]
	}, [])
	State.player.add_condition("started_game")

func _on_character_attack_ready(character):
	if character is Player:
		battle_status.stop_charging()
		GameFlow.overlays.battle.resume()
	elif character is Eagle:
		eagle_attack()
	elif character is Enemy:
		enemy_attack(character)


func eagle_attack():
	var eagle_moves = State.player.get_eagle_stats().moves
	# chooses the most likely eagle attack
	battle_status.performer = eagle
	var eagle_move_most_damage_value = 0
	for move in eagle_moves:
		var damage = Flow.get_move_value(move, "damage", 0)
		if damage > eagle_move_most_damage_value:
			eagle_move_most_damage_value = damage
			battle_status.performed_move = move

	GameFlow.overlays.popup.show_popup("Burg used " + Flow.get_move_value(battle_status.performed_move, "name", "NO NAME"))


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
	AudioEngine.play_effect(Flow.get_move_value(battle_status.performed_move, "sfx", battle_status.performed_move))
	eagle.set_physics_process(true)
	tween.interpolate_property(eagle.shadow, "position", null, Vector2(44, 44), max(1 - duration, 0.5), Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	# TODO define some eagle moves and enemy reacts, maybe add claw effect too? Some blood particles...
	if should_flip:
		enemy.scale = Vector2(-1, 1)
	enemy.play_animation(Flow.get_move_value(battle_status.performed_move, "animation", battle_status.performed_move))
	yield(enemy.animation_player, "animation_finished")
	if enemy.dead:
		_on_target_death(enemy)
	enemy.scale = Vector2(1, 1)
	update_battle()

func enemy_attack(enemy: Enemy):
	battle_status.performer = enemy
	var random_enemy_move_counter = 0
	var random_value = randf()
	for move in Flow.get_enemy_value(enemy.id, "stats", {}).moves:
		var chance = move.get("chance", 1.0)
		if random_value < random_enemy_move_counter + chance:
			battle_status.performed_move = move.name
			break
		else:
			random_enemy_move_counter += chance

	GameFlow.overlays.popup.show_popup(enemy.name + " used " + Flow.get_move_value(battle_status.performed_move, "name", "NO NAME"))
	
	battle_status.stop_charging()
	# TODO pick a move from available moves...
	var enemy_start_position = enemy.position + Vector2()
	var target = player.position + Vector2(-6, -8)
	enemy.sprite.speed_scale = 2.0
	var duration = enemy.position.distance_to(target) / player.MOVEMENT_SPEED / 2
	tween.interpolate_property(enemy, "position", null, target, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	AudioEngine.play_effect(Flow.get_move_value(battle_status.performed_move, "sfx", battle_status.performed_move))
	enemy.sprite.speed_scale = 1.0
	tween.interpolate_property(enemy, "position", null, target + Vector2(0, 4), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	player.animation_player.play(Flow.get_move_value(battle_status.performed_move, "animation", battle_status.performed_move))
	tween.interpolate_property(enemy, "position", null, target, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(player.animation_player, "animation_finished")
	if player.dead:
		_on_target_death(player)
		yield(player.die(), "completed")
		update_battle()
		return

	tween.interpolate_property(enemy, "position", null, enemy_start_position, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	update_battle()

func _on_player_entered_battle_zone(battle_zone: BattleZone):
	AudioEngine.play_background_music("battle3")
	print("Starting battle")
	if battle_zone.enemies.size() == 0:
		print("No enemies here, not doing anything")
	for enemy in battle_zone.enemies:
		enemy.connect("damage_taken", self, "_on_target_take_damage")
		# enemy.connect("death", self, "_on_target_death")

	current_battle_zone = battle_zone
	switch_state(LevelState.BATTLE)

func _on_attack_move_chosen(move, target):
	battle_status.performed_move = move.move
	battle_status.performer = player
	player.perform_action(move.cost)
	GameFlow.overlays.battle.pause()
	target_selector.hide()

	var enemy = target.target

	yield(move_player_to_enemy(target.target), "completed")
	AudioEngine.play_effect(Flow.get_move_value(move.move, "sfx", move.move))
	tween.interpolate_property(player, "position", null, player.position - Vector2(0, 6), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	enemy.play_animation(Flow.get_move_value(move.move, "animation", move.move))
	tween.interpolate_property(player, "position", null, player.position + Vector2(0, 6), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(enemy.animation_player, "animation_finished")
	if enemy.dead:
		_on_target_death(enemy)
	yield(move_player_to_battle_zone(), "completed")

	update_battle()

func update_battle():
	if battle_status.number_of_enemies == 0:
		current_battle_zone.battle_completed()
		yield(switch_state(LevelState.EXPLORING), "completed")
		GameFlow.overlays.hud.set_explore_mode()
		GameFlow.overlays.battle.stop()
		AudioEngine.play_background_music("main2")
		var triggers = Flow.get_battle_value(current_battle_zone.battle_id, "triggers", [])
		for trigger in triggers:
			handle_trigger(trigger)
	elif player.dead:
		# big TODO
		set_process(false)
		battle_status.stop_charging()
		GameFlow.overlays.game_over.show()
		AudioEngine.play_background_music("menu")
	else:
		battle_status.start_charging()


func move_player_to_enemy(enemy: Enemy):
	var enemy_position = enemy.position + Vector2(6, 12)
	if player.position.distance_to(enemy_position) > player.position.distance_to(enemy.position + Vector2(6, 12)):
		enemy_position = enemy.position + Vector2(0, 12)
	if player.position.distance_to(enemy_position) > player.position.distance_to(enemy.position + Vector2(-6, 12)):
		enemy_position = enemy.position + Vector2(-6, 12)
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
	AudioEngine.set_walking(false)
	AudioEngine.custom.walking_timeout /= 2
	player.set_animation(current_battle_zone.position + current_battle_zone.player_position.position - player.position)
	tween.interpolate_property(player, "position", null, current_battle_zone.position + current_battle_zone.player_position.position, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	player.sprite.speed_scale = 1.0
	player.set_animation(current_battle_zone.position - player.position)
	AudioEngine.set_walking(false)
	AudioEngine.custom.walking_timeout *= 2

func show_damage_popup(damage_amount, damage_position):
	damage_label.text = str(damage_amount)
	damage_label.rect_position = damage_position - Vector2(10, 0) + Vector2(0, -4)
	damage_label.show()
	yield(get_tree().create_timer(0.5), "timeout")
	damage_label.hide()

func _on_target_death(target):
	# TODO use death animation...
	if target is Enemy:
		current_battle_zone.remove_enemy(target)
		GameFlow.overlays.battle.on_enemy_death(target)
		battle_status.remove_enemy(target)
		target.die()
		
func _on_target_take_damage(target, target_position):
	var damage = Flow.get_move_value(battle_status.performed_move, "damage", 0)
	if battle_status.performer is Enemy:
		damage *= Flow.get_enemy_value(battle_status.performer.id, "stats", {}).strength
	elif battle_status.performer is Eagle:
		damage *= State.player.get_eagle_stats().strength
	elif battle_status.performer is Player:
		damage *= State.player.get_stats().strength
	if target is Enemy:
		damage /= Flow.get_enemy_value(target.id, "stats", {}).defense
		AudioEngine.play_effect("person_hurt" + str((randi() % 2) + 1))
	elif target is Player:
		damage /= State.player.get_stats().defense
		AudioEngine.play_effect("monster_hurt" + str((randi() % 2) + 1))
	target.take_damage(int(damage))
	show_damage_popup(int(damage), target.position + target.visual.position + Vector2(0, -8).rotated(target.visual.rotation))

func _on_target_enemy(target):
	if target == null:
		target_selector.hide()
	else:
		target_selector.show()
		target_selector.position = target.target.position + target.target.selector_point

func _process(delta):
	_process_inputs(delta)
	
	if previous_interactables and previous_interactables is Interactable:
		previous_interactables.hide_hint()
	previous_interactables = player.collider_under_raycast
	if previous_interactables and state == LevelState.EXPLORING and previous_interactables is Interactable:
		previous_interactables.show_hint()
	

	if state == LevelState.EXPLORING and location_state == LocationState.OUTSIDE:
		var floor_player = floors.get_tile_floor(player.position)
		if floor_player != current_floor_player:
			current_floor_player = floor_player
			floors.refresh(current_floor_player)
			
			transition_tiles(current_floor_player, 0.5)
				
			var new_zoom = Vector2(0.5, 0.5) / pow(ZOOM_PER_FLOOR, current_floor_player)
			tween.interpolate_property(camera, "zoom", null, new_zoom, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
			tween.start()
		
func transition_tiles(floor_level, duration):
	var floors_below = floors.get_floors_below(floor_level)
	floors_below.invert()
	var floors_above = floors.get_floors_above(floor_level)
	var i = 2
	for floor_below in floors_below:
		tween.interpolate_property(floor_below, "modulate", null, Color(1 - 0.04 * i, 1 - 0.04 * i, 1 - 0.04 * i), duration, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
		i += 1
	for floor_above in floors_above:
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
	AudioEngine.play_effect("eagle_screech2")
	player.remove_child(camera)
	camera.position = Vector2(0, 0)
	eagle.add_child(camera)
	camera.smoothing_enabled = true
	transition_tiles(2, 0.8)
	camera_tween.interpolate_property(camera, "zoom", null, Vector2(0.8, 0.8), 0.8, Tween.TRANS_CUBIC, Tween.EASE_IN)
	camera_tween.interpolate_property(eagle.sprite, "scale", null, Vector2(1.6, 1.6) * EAGLE_ZOOM, 0.8, Tween.TRANS_CUBIC, Tween.EASE_IN)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	state = LevelState.FLIGHT

func transition_to_player_from_battle():
	state = LevelState.TRANSITION
	# TODO replace by a fade to black perhaps?
	
	camera_tween.stop_all()
	camera.position = Vector2(0, 0)

	# add_child(camera)
	camera.smoothing_enabled = false
	camera_tween.interpolate_property(camera, "position", null, player.position - current_battle_zone.position, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	current_battle_zone.remove_child(camera)
	camera.position = Vector2(0, 0)
	player.add_child(camera)
	camera.smoothing_enabled = true
	var new_zoom = Vector2(0.5, 0.5) / pow(ZOOM_PER_FLOOR, current_floor_player)
	camera_tween.interpolate_property(camera, "zoom", null, new_zoom, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	state = LevelState.EXPLORING
	current_battle_zone = null


func transition_to_player_from_flight():
	state = LevelState.TRANSITION
	# TODO replace by a fade to black perhaps?
	
	camera_tween.stop_all()
	camera.position = Vector2(0, 0)
	eagle.set_physics_process(false)

	# add_child(camera)
	camera.smoothing_enabled = false
	AudioEngine.play_effect("eagle_screech1")
	camera_tween.interpolate_property(camera, "position", null, player.position - eagle.position, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	camera_tween.start()
	yield(camera_tween, "tween_completed")
	eagle.set_physics_process(true)
	eagle.remove_child(camera)
	camera.position = Vector2(0, 0)
	player.add_child(camera)
	camera.smoothing_enabled = true
	var new_zoom = Vector2(0.5, 0.5) / pow(ZOOM_PER_FLOOR, current_floor_player)
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
	player.remove_child(camera)
	
	add_child(camera)
	camera.position = player.position

	camera_tween.interpolate_property(camera, "position", null, current_battle_zone.position, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	camera_tween.start()
	yield(move_player_to_battle_zone(), "completed")
	remove_child(camera)
	camera.position = Vector2(0, 0)
	current_battle_zone.add_child(camera)
	camera.smoothing_enabled = true
		
	state = LevelState.BATTLE

func switch_state(new_state: int):
	if new_state == LevelState.FLIGHT:
		player.set_still()
		player.set_animation(Vector2())
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
		if location_state == LocationState.OUTSIDE:
			eagle.set_battle_zone(current_battle_zone)
			eagle.set_battle()
		yield(transition_to_battle_zone_from_player(), "completed")
		GameFlow.overlays.battle.set_player(player)
		GameFlow.overlays.battle.set_battle_zone(current_battle_zone)
		GameFlow.overlays.battle.start()
		GameFlow.overlays.hud.set_battle_mode()

		if location_state == LocationState.OUTSIDE:
			battle_status.set_chargers([player, eagle] + current_battle_zone.enemies)
		else:
			battle_status.set_chargers([player] + current_battle_zone.enemies)

		battle_status.start_charging()

func counter_scale_camera(delta, increase):
	var current_zoom = camera.zoom.x
	var new_zoom = max(0.6, min(1.0, current_zoom + 0.3 * delta * increase))
	camera.zoom = Vector2(new_zoom, new_zoom)
	eagle.sprite.scale = 2 * camera.zoom * EAGLE_ZOOM


func show_begin():
	state = LevelState.TRANSITION
	GameFlow.overlays.begin.start()
	yield(GameFlow.overlays.begin, "finished")


func show_end():
	state = LevelState.TRANSITION
	GameFlow.overlays.end.start()

func add_player(player: Player, player_position: Vector2):
	var current_parent = player.get_parent()
	current_parent.remove_child(player)
	$YSort.add_child(player)
	player.position = player_position

func handle_trigger(trigger: Dictionary):
	if "condition" in trigger:
		State.player.add_condition(trigger.condition)
	elif "battle" in trigger:
		state = LevelState.TRANSITION
		player.set_still()
		current_battle_zone = battle_zones[trigger.battle]
		var completed =  State.get_battle_by_id(trigger.battle)
		if completed != null and completed.completed:
			GameFlow.overlays.popup.show_popup("BUG: Already won this battle!")
			print("Already won this battle!")
			player.set_moving()
			state = LevelState.EXPLORING
			return
		yield(GameFlow.overlays.transition.transition_to_dark(1.0), "completed")
		player.position = current_battle_zone.position + current_battle_zone.player_position.position
		player.set_animation(current_battle_zone.position - player.position)
		camera_tween.stop_all()
		tween.stop_all()
		camera.position = Vector2(0, 0)
		player.remove_child(camera)
		current_battle_zone.add_child(camera)
		if location_state == LocationState.OUTSIDE:
			eagle.set_battle_zone(current_battle_zone)
			eagle.set_start_position()
			eagle.set_battle()
		AudioEngine.play_background_music("battle3")
		GameFlow.overlays.battle.set_player(player)
		GameFlow.overlays.battle.set_battle_zone(current_battle_zone)
		GameFlow.overlays.battle.start()
		GameFlow.overlays.hud.set_battle_mode()
		state = LevelState.BATTLE
		current_battle_zone.trigger_start()
		for enemy in current_battle_zone.enemies:
			enemy.connect("damage_taken", self, "_on_target_take_damage")	
		yield(GameFlow.overlays.transition.transition_to_clear(0.8), "completed")
		if location_state == LocationState.OUTSIDE:
			battle_status.set_chargers([player, eagle] + current_battle_zone.enemies)
		else:
			battle_status.set_chargers([player] + current_battle_zone.enemies)

		battle_status.start_charging()

	elif "hide" in trigger:
		yield(get_tree().create_timer(1.0), "timeout")
		for npc in get_tree().get_nodes_in_group("npc"):
			if npc.id == trigger.hide:
				npc.hide()
				npc.collision_layer = 0
				npc.collision_mask = 0
	elif "show" in trigger:
		yield(get_tree().create_timer(1.0), "timeout")
		for npc in get_tree().get_nodes_in_group("npc"):
			if npc.id == trigger.show:
				npc.show()
				npc.collision_layer = 3
				npc.collision_mask = 3
	elif "upgrade" in trigger:
		var upgrade_description = Flow.get_upgrade_value(trigger.upgrade, "description", "No DESC")
		State.add_new_upgrade(trigger.upgrade)
		player.refresh_stats()
		show_interact(upgrade_description, trigger.get("triggers", []))
	elif "conversation" in trigger:
		state = LevelState.TRANSITION
		if "move" in trigger.conversation:
			state = LevelState.TRANSITION
			yield(GameFlow.overlays.transition.transition_to_dark(1.0), "completed")
			# hack for last teleport
			if location_state == LocationState.INSIDE:
				add_player(player, Vector2(0, 0))
				var new_zoom = Vector2(0.5, 0.5) / pow(ZOOM_PER_FLOOR, current_floor_player)
				camera.zoom = new_zoom
				location_state = LocationState.OUTSIDE
				eagle.set_process(true)
			if trigger.conversation.move.location == "npc":
				var found = false
				for npc in get_tree().get_nodes_in_group("npc"):
					if npc.id == trigger.conversation.move.npc:
						camera.smoothing_enabled = false
						player.position = npc.position + Vector2(-8, 8)
						player.set_animation(Vector2(1, -1))
						yield(get_tree().create_timer(0.5), "timeout")
						camera.smoothing_enabled = true
						found = true
				if !found:
					GameFlow.overlays.popup.show_popup("Couldn't find target " + trigger.conversation.move.npc)
			yield(GameFlow.overlays.transition.transition_to_clear(0.5), "completed")
		show_dialogue(trigger.conversation, trigger.conversation.get("triggers", []))
	elif "interact" in trigger:
		show_interact(trigger.interact.description, trigger.interact.get("triggers", []))
	elif "end" in trigger:
		show_end()

func show_dialogue(conversation: Dictionary, triggers: Array):
	print("We got conversation", conversation)
	player.set_still()
	player.set_animation(Vector2(0, 0))
	state = LevelState.TRANSITION
	GameFlow.overlays.dialogue.set_conversation(conversation)
	yield(GameFlow.overlays.dialogue, "finished")
	yield(get_tree().create_timer(0.2), "timeout")
	player.set_moving()
	state = LevelState.EXPLORING
	for trigger in triggers:
		handle_trigger(trigger)

func use_door(door):
	print("Moving to target", door.target.name)
	if State.player.location.location != "cave":
		AudioEngine.play_effect("door_open")
	yield(GameFlow.overlays.transition.transition_to_dark(), "completed")
	door.target.add_player(player, door.target_position)
	if location_state == LocationState.INSIDE:
		var new_zoom = Vector2(0.5, 0.5) / pow(ZOOM_PER_FLOOR, current_floor_player)
		camera.zoom = new_zoom
		location_state = LocationState.OUTSIDE
		eagle.set_process(true)
		AudioEngine.stop_ambiance()
	elif location_state == LocationState.OUTSIDE:
		camera.zoom = Vector2(0.33, 0.33)
		location_state = LocationState.INSIDE
		eagle.set_process(false)
		AudioEngine.play_ambiance()

	if not door.target.is_in_group("cave_interior"):
		AudioEngine.play_effect("door_close")

	camera.smoothing_enabled = false
	yield(get_tree().create_timer(0.5), "timeout")
	camera.smoothing_enabled = true
	yield(GameFlow.overlays.transition.transition_to_clear(), "completed")
	player.set_moving()
	if door.target.is_in_group("yurt_interior"):
		State.player.location = {
			"location": "yurt",
			"id": door.target.id,
		}
	elif door.target == self:
		State.player.location = {
			"location": "overworld",
			"position": player.position,
		}
	elif door.target.is_in_group("cave_interior"):
		State.player.location = {
			"location": "cave",
			"id": door.target.id,
		}
	else:
		# TODO get the eagle here?
		State.player.location = {
			"location": null,
			"position": Vector2(0, 0)
		}

	state = LevelState.EXPLORING

func show_interact(description: String, triggers: Array):
	player.set_animation(Vector2(0, 0))
	player.set_still()
	AudioEngine.play_effect("item_interact")
	state = LevelState.TRANSITION
	GameFlow.overlays.text.show_text(description)
	yield(GameFlow.overlays.text, "finished")
	yield(get_tree().create_timer(0.2), "timeout")
	player.set_moving()
	state = LevelState.EXPLORING
	var save_point = Flow.get_interactive_value(player.collider_under_raycast.id, "save_point", false)
	if save_point:
		state = LevelState.TRANSITION
		player.set_still()
		yield(GameFlow.overlays.transition.transition_to_dark(), "completed")
		
		Flow.save_game()
		if State.player.location != null and State.player.location.location == "yurt":
			var yurt = yurts[State.player.location.id]
			add_player(player, yurt.position + yurt.player_position.position)
			var new_zoom = Vector2(0.5, 0.5) / pow(ZOOM_PER_FLOOR, current_floor_player)
			camera.zoom = new_zoom
			location_state = LocationState.OUTSIDE
			player.set_animation(Vector2(0, 1))
			player.set_animation(Vector2(0, 0))
			player.refresh_stats()
		yield(GameFlow.overlays.transition.transition_to_clear(), "completed")
		# TODO move player to wake up outside yurt
		player.set_moving()
		state = LevelState.EXPLORING
	for trigger in triggers:
		handle_trigger(trigger)

func _process_inputs(delta):
	if state == LevelState.EXPLORING:
		if Input.is_action_just_pressed("switch"):
			if location_state == LocationState.OUTSIDE:
				switch_state(LevelState.FLIGHT)
			else:
				# TODO play no es possible audio effect
				pass
		elif Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
			if player.collider_under_raycast is InteractableItem:
				print("We're interacting with ", player.collider_under_raycast, " ", player.collider_under_raycast.id)
				var descriptions = Flow.get_interactive_value(player.collider_under_raycast.id, "descriptions", ["EMPTY_DESCRIPTION"])
				var description = descriptions[randi() % descriptions.size()]
				var triggers = Flow.get_interactive_value(player.collider_under_raycast.id, "triggers", [])
				show_interact(description, triggers)
			if player.collider_under_raycast is InteractableNPC:
				
				print("We're interacting with ", player.collider_under_raycast, " ", player.collider_under_raycast.id)
				var conversation = player.collider_under_raycast.get_conversation()
				# TODO superhacky fix to see if it's an actually good dialogue
				if len(conversation.dialogue) > 3:
					if player.collider_under_raycast is InteractableFloor:
						player.collider_under_raycast.show_sigil()
				var triggers = conversation.get("triggers", [])
				show_dialogue(conversation, triggers)
				
			elif player.collider_under_raycast is InteractableDoor:
				state = LevelState.TRANSITION
				player.set_still()
				player.set_animation(Vector2(0, 0))
				var door = player.collider_under_raycast
				use_door(door)

	elif state == LevelState.FLIGHT:
		if Input.is_action_just_pressed("switch"):
			switch_state(LevelState.EXPLORING)
		elif Input.is_action_pressed("move_up"):
			counter_scale_camera(delta, 1)
		elif Input.is_action_pressed("move_down"):
			counter_scale_camera(delta, -1)
