extends Interactable
class_name InteractableItem


export var id = ""

func _ready():
	if id == "":
		push_error("Interactable item without id, this will lead to errors! " + str(name))
