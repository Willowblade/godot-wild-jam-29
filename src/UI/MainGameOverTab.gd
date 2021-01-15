extends class_pause_tab

onready var _restart_button := $VBoxContainer/VBoxContainer/RestartButton
onready var _abort_button := $VBoxContainer/VBoxContainer/AbortButton
onready var _quit_button := $VBoxContainer/VBoxContainer/QuitButton

func _ready():
	var _error : int = _restart_button.connect("pressed", self, "_on_restart_button_pressed")
	_error = _abort_button.connect("pressed", self, "_on_abort_button_pressed")

	if OS.get_name() == "HTML5":
		_quit_button.visible = false
	else:
		_quit_button.visible = true
		_error = _quit_button.connect("pressed", self, "_on_quit_button_pressed")

func update_tab():
	_restart_button.grab_focus()

func _on_restart_button_pressed():
	Flow.go_to_game()
	hide()

func _on_abort_button_pressed():
	Flow.go_to_menu()
