extends InteractableNPC
class_name InteractableFloor


onready var tween = $Tween
onready var sigil = $Sigil

var activated = false

func _ready():
	show_sigil()


func show_sigil():
	if not activated:
		activated = true
		tween.interpolate_property(sigil, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 2.0, Tween.TRANS_BOUNCE, Tween.EASE_IN)
		tween.start()
