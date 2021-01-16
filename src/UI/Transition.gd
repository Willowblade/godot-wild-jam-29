extends Control

onready var color_rect = $ColorRect
onready var tween = $Tween

func _ready():
	GameFlow.register_overlay("transition", self)
	
func transition_to_dark():
	yield(transition_to_color(Color(0, 0, 0, 1), 2.0), "completed")
	
func transition_to_clear():
	yield(transition_to_color(Color(0, 0, 0, 0), 1.0), "completed")

func transition_to_color(color: Color, time: float):
	tween.interpolate_property(color_rect, "color", null, color , time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")	
