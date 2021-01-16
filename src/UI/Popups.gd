extends Control

onready var popup_scene = preload("res://src/UI/Popup.tscn")
onready var tween = $Tween

var popups = [null, null, null, null]

var texts_being_shown = []

func _ready():
	GameFlow.register_overlay("popup", self)
	
func show_popup(text: String, type: String = "info", timeout: float = 1.0):
	print("Showing popup")
	if texts_being_shown.has(text):
		return
	var popup = popup_scene.instance()
	add_child(popup)
	popup.rect_position = Vector2(480 - 300, -50)
	var i = 0
	for popup_slot in popups:
		if popup_slot == null:
			popups[i] = popup
			break
		i += 1
	texts_being_shown.append(text)
	popup.set_text(text)
	popup.tween.interpolate_property(popup, "rect_position", Vector2(480 - 300, -50), Vector2(480 - 300, 100 - i * 40), Vector2(480 - 300, 150 - i * 40).distance_to(Vector2(480 - 300, -50)) / 100, Tween.TRANS_QUAD, Tween.EASE_OUT)
	popup.tween.start()
	yield(popup.tween, "tween_completed")
	yield(get_tree().create_timer(timeout), "timeout")
	popup.queue_free()
	texts_being_shown.erase(text)
	popups[i] = null

func show_popup_custom(text: String, position: Vector2, type: String = "info", timeout: float = 1.0):
	print("Showing popup")
	if texts_being_shown.has(text):
		return
	var popup = popup_scene.instance()
	add_child(popup)
	popup.rect_position = Vector2(480 - 300, -50)
	texts_being_shown.append(text)
	popup.set_text(text)
	var destination =  Vector2(480 - 300, 0) + position
	popup.tween.interpolate_property(popup, "rect_position", Vector2(480 - 300, -50), destination, destination.distance_to(Vector2(480 - 300, -50)) / 100, Tween.TRANS_QUAD, Tween.EASE_OUT)
	popup.tween.start()
	yield(popup.tween, "tween_completed")
	yield(get_tree().create_timer(timeout), "timeout")
	popup.queue_free()
	texts_being_shown.erase(text)
