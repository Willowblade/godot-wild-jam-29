extends Control
class_name GamePopup

onready var tween: Tween = $Tween
onready var label: RichTextLabel = $PanelContainer/HBoxContainer/RichTextLabel

func _ready():
	pass


func set_text(text: String):
	label.bbcode_text = text
