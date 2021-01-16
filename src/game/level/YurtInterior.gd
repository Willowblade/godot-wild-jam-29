extends StaticBody2D

export var id = ""

onready var interactable_door = $InteractableDoor
onready var ysort = $YSort
onready var player_position = $PlayerPosition


func _ready():
	if id == "":
		push_error("Yurt interior without id, this will lead to errors! " + str(name))
		
func match_yurt(level, yurt):
	interactable_door.target_position = yurt.position + yurt.player_position.position
	interactable_door.target = level
	
func add_player(player: Player, player_position: Vector2):
	var current_parent = player.get_parent()

	current_parent.remove_child(player)
	$YSort.add_child(player)
	player.position = player_position
