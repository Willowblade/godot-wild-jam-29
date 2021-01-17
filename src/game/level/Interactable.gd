extends StaticBody2D
class_name Interactable

func _ready():
	$InteractableHint.position = get_interactable_location()
	
	
func get_interactable_location():
	return Vector2(0, -24)
	
func show_hint():
	$InteractableHint.show()
	
func hide_hint():
	$InteractableHint.hide()
