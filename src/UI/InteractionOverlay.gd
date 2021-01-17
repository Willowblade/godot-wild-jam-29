extends Control


signal finished
onready var label = $VBoxContainer/MarginContainer/PanelContainer/MarginContainer/RichTextLabel
onready var image = $VBoxContainer/TextureRect

func _ready():
	GameFlow.register_overlay("text", self)
	
func show_text(text: String):
	show()
	label.bbcode_enabled = true
	label.bbcode_text = text
	yield(get_tree().create_timer(0.3), "timeout")
	set_process(true)
	
func stop_showing_text():
	hide()
	set_process(false)
	emit_signal("finished")
	
func _process(delta):
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("interact"):
		stop_showing_text()
