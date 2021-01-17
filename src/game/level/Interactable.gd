extends StaticBody2D
class_name Interactable

func _ready():
	$InteractableHint.position = get_interactable_location()
	
	
func get_interactable_location():
	return Vector2(0, -24)
	
func show_hint():
	if scale.x < 0:
		$InteractableHint.scale.x = -0.75
	else:
		$InteractableHint.scale.x = 0.75
	$InteractableHint.show()
	
func hide_hint():
	$InteractableHint.hide()
