extends Control

onready var color_rect = $ColorRect
onready var tween = $Tween

func _ready():
	GameFlow.register_overlay("transition", self)
	
func transition_to_dark(timeout: float = 2.0):
	yield(transition_to_color(Color(0, 0, 0, 1), timeout), "completed")
	
func transition_to_clear(timeout: float = 1.0):
	yield(transition_to_color(Color(0, 0, 0, 0), timeout), "completed")

func transition_to_color(color: Color, time: float):
	tween.interpolate_property(color_rect, "color", null, color , time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")	
