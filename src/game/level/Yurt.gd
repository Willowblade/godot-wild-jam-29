extends StaticBody2D
class_name Yurt

onready var door = $Door
onready var sprite = $Sprite
onready var player_position = $PlayerPosition
onready var interactable_door = $InteractableDoor

enum DOOR_TYPES {
	ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT
}

enum COLORS {
	RED, BLUE, AQUA, GREEN, YELLOW, ORANGE, PURPLE, WHITE, GOLD
}

export var id = ""
export (DOOR_TYPES) var door_type = DOOR_TYPES.ONE
export (COLORS) var door_color = COLORS.RED 


const types_to_rects = {
	DOOR_TYPES.ONE: Rect2(Vector2(7, 5), Vector2(17, 22)), 
	DOOR_TYPES.TWO: Rect2(Vector2(7 + 32, 5), Vector2(17, 22)), 
	DOOR_TYPES.THREE: Rect2(Vector2(7 + 64, 5), Vector2(17, 22)), 
	DOOR_TYPES.FOUR: Rect2(Vector2(7 + 96, 5), Vector2(17, 22)), 
	DOOR_TYPES.FIVE: Rect2(Vector2(7, 37), Vector2(17, 22)), 
	DOOR_TYPES.SIX: Rect2(Vector2(7 + 32, 37), Vector2(17, 22)), 
	DOOR_TYPES.SEVEN: Rect2(Vector2(7 + 64, 37), Vector2(17, 22)), 
	DOOR_TYPES.EIGHT: Rect2(Vector2(7 + 96, 37), Vector2(17, 22)), 
}

const colors_to_names = {
	COLORS.RED: "punched the baby in the face red",
	COLORS.AQUA: "drowned in the river yonder aqua",
	COLORS.BLUE: "almost made it but unfortunately not blue",
	COLORS.GOLD: "killed the khan and took his ring gold",
}

const colors_to_colors = {
	COLORS.RED: Color(Color.crimson),
	COLORS.AQUA: Color(Color.aqua),
	COLORS.BLUE: Color(Color.cornflower),
	COLORS.GREEN: Color(Color.webgreen),
	COLORS.YELLOW: Color(Color.yellow),
	COLORS.ORANGE: Color(Color.orange),
	COLORS.PURPLE: Color(Color.rebeccapurple),
	COLORS.WHITE: Color(Color.white),
	COLORS.GOLD: Color(Color.goldenrod),
}

func match_yurt_interior(yurt_interior):
	interactable_door.target_position = yurt_interior.player_position.position
	interactable_door.target = yurt_interior

func _ready():
	if id == "":
		push_error("Yurt without id, this will lead to errors! " + str(name))
	door.region_rect = types_to_rects[door_type]
	door.modulate = colors_to_colors[door_color]

func _on_area_body_entered(body):
	# if body is Player:
	# 	GameFlow.overlays.popup.show_popup_custom(colors_to_names.get(door_color, "nonyabusiness").capitalize() + " yurt", Vector2(0, 40), "yurt", 2.5)
	pass
