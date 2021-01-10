extends Node2D

onready var door = $Door
onready var sprite = $Sprite

enum DOOR_TYPES {
	ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT
}

enum COLORS {
	RED, BLUE, AQUA, GREEN, YELLOW, ORANGE, PURPLE, WHITE, GOLD
}

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


func _ready():
	door.region_rect = types_to_rects[door_type]
	door.modulate = colors_to_colors[door_color]
