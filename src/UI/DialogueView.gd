extends Control

onready var text_label = $VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/MarginContainer/Text
onready var speaker_label = $VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/Speaker
onready var color_rect := $ColorRect
onready var tween := $Tween

onready var dialogue_container := $VBoxContainer

onready var animation_player := $AnimationPlayer
onready var bataar_speaker := $BataarSpeaker
onready var other_speaker := $OtherSpeaker

onready var other_speakers := {
	"copy": $OtherSpeaker/Copy,
}

onready var speaker_names := {
	"copy": "Bataar???"
}

signal finished

func _ready():
	set_process(false)
	color_rect.color = Color(0, 0, 0, 0.0)
	GameFlow.register_overlay("dialogue", self)

var dialogue_index = 0
var dialogue = []

func set_conversation(conversation: Dictionary):
	set_process(false)
	dialogue_index = 0
	dialogue = conversation.dialogue
	show()
	dialogue_container.hide()
	bataar_speaker.hide()
	other_speaker.hide()
	tween.remove_all()
	for dialogue_entry in dialogue:
		set_speaker(dialogue_entry.get("speaker", "bataar"))
		bataar_speaker.hide()
		other_speaker.hide()
	print(tween.is_active())
	tween.interpolate_property(color_rect, "color", Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.7) , 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	print("Color fade completed")

	dialogue_container.show()
	bataar_speaker.show()
	other_speaker.show()
	start_dialogue_bit()
	# TODO only characters can speak now
	
	set_process(true)

func set_speaker(speaker: String):
	if speaker == "bataar":
		bataar_speaker.modulate = Color(1, 1, 1, 1)
		other_speaker.modulate = Color(0.6, 0.6, 0.6, 0.6)
		speaker_label.text = "Bataar"
	else:
		other_speaker.modulate = Color(1, 1, 1, 1)
		bataar_speaker.modulate = Color(0.6, 0.6, 0.6, 0.6)
		speaker_label.text = speaker_names[speaker]
		for other_speaker_name in other_speakers:
			if other_speaker_name == speaker:
				other_speakers[other_speaker_name].show()
			else:
				other_speakers[other_speaker_name].hide()
				
func animate_speaker(speaker: String, animation: String):
	if animation == "none":
		return
	if speaker == "bataar":
		if animation == "default":
			animation_player.play("bataar_speak")
		elif animation == "angry":
			animation_player.play("bataar_angry")
		else:
			animation_player.play("bataar_speak")
	else:
		if animation == "default":
			animation_player.play("other_speak")
		elif animation == "angry":
			animation_player.play("other_angry")
		else:
			animation_player.play("other_speak")

func end():
	tween.stop_all()
	set_process(false)
	color_rect.color = Color(0, 0, 0, 0.0)
	hide()
	emit_signal("finished")

func start_dialogue_bit():
	var current_dialogue = dialogue[dialogue_index]
	set_speaker(current_dialogue.get("speaker", "bataar"))
	animate_speaker(current_dialogue.get("speaker", "bataar"), current_dialogue.get("animation", "default"))
	text_label.bbcode_enabled = true
	text_label.bbcode_text = current_dialogue.text
	text_label.percent_visible = 0
	tween.interpolate_property(text_label, "percent_visible", 0, 1, current_dialogue.text.length() / 30, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	tween.start()
	set_process(false)
	yield(get_tree().create_timer(0.2), "timeout")
	set_process(true)

func show_next_dialogue():
	dialogue_index += 1
	start_dialogue_bit()


func progress_dialogue():
	if tween.is_active():
		tween.stop_all()
		text_label.percent_visible = 1
		return
	if dialogue_index == dialogue.size() - 1:
		end()
	else:
		show_next_dialogue()
	

func _process(_delta):

	if Input.is_action_just_pressed("confirm"):
		progress_dialogue()
