extends Interactable
class_name InteractableDoor

var target_position = Vector2()
var target = null

func _ready():
	pass

func get_interactable_location():
	return Vector2(0, -8)
