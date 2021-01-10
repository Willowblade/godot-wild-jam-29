extends Node2D


onready var player = $YSort/Player
onready var floors = $Floors
onready var camera = $YSort/Player/Camera

onready var tween = $Tween

var current_floor_player = null

func _ready():
	pass


func _process(delta):
	var floor_player = floors.get_tile_floor(player.position)
	if floor_player != current_floor_player:
		print("New floor player: ", floor_player)
		current_floor_player = floor_player
		floors.refresh(current_floor_player)
		var floors_below = floors.get_floors_below(current_floor_player)
		floors_below.invert()
		var floors_above = floors.get_floors_above(current_floor_player)
		var i = 2
		for floor_below in floors_below:
			print(floor_below.name)
			tween.interpolate_property(floor_below, "modulate", null, Color(1 - 0.04 * i, 1 - 0.04 * i, 1 - 0.04 * i), 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
			i += 1
		print("ABOVE")
		for floor_above in floors_above:
			print(floor_above.name)
			tween.interpolate_property(floor_above, "modulate", null, Color(1 , 1, 1 ), 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
			
		var new_zoom = Vector2(0.5, 0.5) / pow(1.1, current_floor_player)
		print(new_zoom)
		tween.interpolate_property(camera, "zoom", null, new_zoom, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
		tween.start()
		
