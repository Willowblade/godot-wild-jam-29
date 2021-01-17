extends StaticBody2D

onready var interactable_door = $Door
onready var ysort = $YSort
onready var player_position = $PlayerPosition

export var id = ""

func match_entrance(level, cave):
	interactable_door.target_position = cave.position + cave.player_position.position
	interactable_door.target = level

func add_player(player: Player, player_position: Vector2):
	var current_parent = player.get_parent()

	current_parent.remove_child(player)
	$YSort.add_child(player)
	player.position = player_position
	popup()

func popup():
	if name == "ThirdCave":
		GameFlow.overlays.popup.show_popup_custom("Entered Shrine of Kok Tengri", Vector2(0, 40), "yurt", 2.5)
	elif name == "FirstCave":
		GameFlow.overlays.popup.show_popup_custom("Entered Shrine of Boz Tengri", Vector2(0, 40), "yurt", 2.5)
	elif name == "SecondCave":
		GameFlow.overlays.popup.show_popup_custom("Entered Shrine of Od Tengri", Vector2(0, 40), "yurt", 2.5)
					
