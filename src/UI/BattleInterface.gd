extends Control

onready var SelectableScene = preload("res://src/UI/Selectable.tscn")

onready var moves = $VBoxContainer/MarginContainer/HBoxContainer/Moves
onready var moves_container = $VBoxContainer/MarginContainer/HBoxContainer/Moves/MovesContainer
# TODO rename proper
onready var targets = $VBoxContainer/MarginContainer/HBoxContainer/Targets
onready var targets_container = $VBoxContainer/MarginContainer/HBoxContainer/Targets/TargetsContainer
onready var description: RichTextLabel = $VBoxContainer/MarginContainer/HBoxContainer/Description/DescriptionContainer/DescriptionText

signal move_chosen(move, target)
signal target_enemy(target)

export var page_size = 3

enum SelectionState {
	SELECT_MOVE,
	SELECT_TARGET,
}


var targets_list: Array = []
var moves_list: Array = []

var selectables = {
	"moves": [],
	"targets": []
}

var page = {
	"moves": 0,
	"target": 0
}

var visible_moves = []
var visible_targets = []

var selected_move = null
var selected_target = null

var player: Player = null
var current_battle_zone: BattleZone = null

var state = SelectionState.SELECT_MOVE

func _ready():
	set_process(false)
	
	GameFlow.register_overlay("battle", self)
	# make ten selectables for every box
	for i in range(10):
		var selectable = SelectableScene.instance()
		moves_container.add_child(selectable)
		selectables.moves.append(selectable)
		
	for i in range(10):
		var selectable = SelectableScene.instance()
		targets_container.add_child(selectable)
		selectables.targets.append(selectable)
	
func set_battle_zone(battle_zone):
	current_battle_zone = battle_zone
	current_battle_zone.enemies
	# reset all the target data
	targets_list = []
	var i = 0
	page.target = 0
	
	var name_count = {}
	
	for enemy in current_battle_zone.enemies:
		var selectable = selectables.targets[i]
		var enemy_definition = Flow.get_enemy_value(enemy.id, "stats", {})
		# sets all metadata correct for the showing of the targets_list
		if enemy.id in name_count:
			name_count[enemy.id] += 1
		else:
			name_count[enemy.id] = 1
		targets_list.append({
			"index": i,
			"target": enemy,
			"id": enemy.id,
			"count": name_count[enemy.id],
			"name": Flow.get_enemy_value(enemy.id, "name", "PLACEHOLDER_NAME"),
			"description": Flow.get_enemy_value(enemy.id, "description", "PLACEHOLDER_NAME"),
			"selectable": selectable,
		})

		i += 1
		
	for target in targets_list:
		if name_count[target.target.id] > 1:
			print("Adding name count of ", target)
			target.name += " " + str(target.count)
	
	selected_target = targets_list[0]
	update_targets()

func set_player(new_player: Player):
	player = new_player
		
func on_enemy_death(enemy: Enemy):
	for target in targets_list:
		if target.target == enemy:
			targets_list.erase(target)
			if target == selected_target:
				if targets_list.empty():
					pass
				else:
					selected_target = targets_list[0]
	if targets_list.empty():
		print("Battle is over!")
		# TODO
	update_targets()
			
func update_targets():
	var target_page = page.target
	visible_targets = []
	for i in range(targets_list.size()):
		var target = targets_list[i]
		target.index = i

		if i < target_page * page_size or i >= (target_page + 1) * page_size:
			pass
		else:
			print("Adding target ", target)
			if target == selected_target:
				target.selectable.set_selected(true)
			else:
				target.selectable.set_selected(false)
			target.selectable.set_cost(0)
			visible_targets.append(target.selectable)
			target.selectable.set_label_name(target.name)
	
	var hidden_selectables = []
	for selectable_target in selectables.targets:
		if selectable_target in visible_targets:
			selectable_target.show()
		else:
			selectable_target.hide()
			selectable_target.set_selected(false)
			hidden_selectables.append(selectable_target)

	var remainder = page_size - visible_targets.size()
	print("Remainder ", remainder)
	for i in range(remainder):
		hidden_selectables[i].set_label_name("")
		hidden_selectables[i].set_cost(0)
		hidden_selectables[i].show()
	
func generate_moves():
	moves_list = []
	var i = 0
	for move in State.player.get_stats().moves:
		var selectable = selectables.moves[i]
		
		moves_list.append({
			"index": i,
			"move": move,
			"name": Flow.get_move_value(move, "name", "PLACEHOLDER_NAME"),
			"cost": Flow.get_move_value(move, "cost", 100),
			"description": Flow.get_move_value(move, "description", "PLACEHOLDER_DESCRIPTION"),
			"selectable": selectable,
		})
		
		i += 1
		
	update_moves()
	
func update_moves():
	var moves_page = page.moves
	visible_moves = []
	for i in range(moves_list.size()):
		var move = moves_list[i]
		move.index = i
		print("Moves page ", moves_page)
		if i < moves_page * page_size or i >= (moves_page + 1) * page_size:
			pass
		else:
			if move == selected_move:
				move.selectable.set_selected(true)
			else:
				move.selectable.set_selected(false)
			move.selectable.set_label_name(move.name)
			move.selectable.set_cost(move.cost)
			visible_moves.append(move.selectable)
			
	var hidden_selectables = []
	var visible_selectables = []
	for selectable_move in selectables.moves:
		if selectable_move in visible_moves:
			selectable_move.show()
			visible_selectables.append(selectable_move)
		else:
			selectable_move.hide()
			selectable_move.set_selected(false)
			hidden_selectables.append(selectable_move)

	var remainder = page_size - visible_moves.size()
	for i in range(remainder):
		hidden_selectables[i].set_label_name("")
		hidden_selectables[i].set_cost(0)
		hidden_selectables[i].show()
		visible_selectables.append(hidden_selectables[i])
	
	for i in range(visible_selectables.size()):
		moves_container.move_child(visible_selectables[i], i)

func reset_move():
	selected_move = moves_list[0]
	set_move_page(selected_move.index)
	page.moves = 0

func set_move_page(index: int):
	if index < 0:
		index += moves_list.size()
	# this is pretty hacky to put this here but hey
	targets.hide()
	for move in moves_list:
		if move.index == index:
			selected_move = move
	page.moves = index / page_size

	description.bbcode_text = selected_move.description
	emit_signal("target_enemy", null)
	update_moves()

func set_target_page(index: int):
	if index < 0:
		index += targets_list.size()
		
	for target in targets_list:
		if target.index == index:
			selected_target = target
			print("selected_target = ", selected_target)
	page.target = index / page_size
	var enemy_definitions = {}
	description.bbcode_text = selected_target.description
	emit_signal("target_enemy", selected_target)
	update_targets()

func go_to_target_select():
	state = SelectionState.SELECT_TARGET
	targets.show()
	set_target_page(selected_target.index)

func _process(delta):
	if state == SelectionState.SELECT_MOVE:
		# description.bbcode_text = selected_move.description
		moves.show()
		targets.hide()
	elif state == SelectionState.SELECT_TARGET:
		# moves.hide()
		# description.bbcode_text = selected_target.description
		targets.show()
		
	if Input.is_action_just_pressed("move_down"):
		if state == SelectionState.SELECT_MOVE:
			var new_index = (selected_move.index + 1) % moves_list.size()
			set_move_page(new_index)
		elif state == SelectionState.SELECT_TARGET:
			var new_index = (selected_target.index + 1) % targets_list.size()
			set_target_page(new_index)
	elif Input.is_action_just_pressed("move_up"):
		if state == SelectionState.SELECT_MOVE:
			var new_index = (selected_move.index - 1) % moves_list.size()
			set_move_page(new_index)
		elif state == SelectionState.SELECT_TARGET:
			var new_index = (selected_target.index - 1) % targets_list.size()
			set_target_page(new_index)
	if Input.is_action_just_pressed("move_right"):
		if state == SelectionState.SELECT_TARGET:
			var new_index = (selected_target.index + 1) % targets_list.size()
			set_target_page(new_index)
	elif Input.is_action_just_pressed("move_left"):
		if state == SelectionState.SELECT_TARGET:
			var new_index = (selected_target.index - 1) % targets_list.size()
			set_target_page(new_index)
	elif Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("interact"):
		if state == SelectionState.SELECT_MOVE:
			go_to_target_select()
		elif state == SelectionState.SELECT_TARGET:
			if selected_move.cost > player.stats.stamina:
				print("No good! Insufficient stamina...")
			else:
				emit_signal("move_chosen", selected_move, selected_target)
	elif Input.is_action_just_pressed("return"):
		if state == SelectionState.SELECT_TARGET:
			state = SelectionState.SELECT_MOVE
			set_move_page(selected_move.index)

func start():
	generate_moves()
	reset_move()

func pause():
	hide()
	set_process(false)

func resume():
	show()
	state = SelectionState.SELECT_MOVE
	targets.hide()
#	reset_move()
	set_process(true)
	
func stop():
	set_process(false)
	hide()
	


