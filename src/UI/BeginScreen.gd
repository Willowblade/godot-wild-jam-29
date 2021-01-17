extends Control

onready var label = $ColorRect/CenterContainer/RichTextLabel
onready var tween: Tween = $Tween

signal finished()

var halted = false

func _ready():
	if name == "BeginScreen":
		GameFlow.register_overlay("begin", self)
	else:
		GameFlow.register_overlay("end", self)
	set_process(false)


func start():
	set_process(true)
	show()
	label.percent_visible = 0
	show_text()

func stop():
	set_process(true)
	hide()
	
	
func show_text():
	var text = label.bbcode_text
	var parts = text.split("\n\n")
	var i = 0
	var count = 0
	for part in parts:
		if halted:
			return
		var target = count + part.length()
		if i == 0:
			target -= 10
			if name == "BeginScreen":
				target -= 5
		else:
			if name == "BeginScreen":
				target -= 1
		tween.interpolate_property(label, "visible_characters", count, target, part.length() / 28, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		
		count = target
		i += 1
		yield(tween, "tween_completed")
		yield(get_tree().create_timer(1.0), "timeout")
	
	
func _process(delta):
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
		if not label.percent_visible == 1:
			tween.remove_all()
			halted = true
			label.percent_visible = 1
		else:
			if name == "BeginScreen":
				emit_signal("finished")
			else:
				Flow.go_to_menu()
	


