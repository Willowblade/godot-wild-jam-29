extends StaticBody2D


export var id = ""

onready var player_position = $PlayerPosition
onready var interactable_door = $InteractableDoor

func _ready():
	pass


func match_cave_interior(cave_interior):
	interactable_door.target_position = cave_interior.player_position.position
	interactable_door.target = cave_interior

