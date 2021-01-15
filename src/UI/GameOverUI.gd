extends Control

onready var _tab_container := $TabContainer

func _ready():
	GameFlow.register_overlay("game_over", self)

func show():
	_tab_container.set_current_tab(class_pause_tab.TABS.MAIN)
	visible = true

func hide():
	visible = false
