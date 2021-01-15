extends HBoxContainer

onready var selected_texture_rect: TextureRect = $Selected
onready var name_label: RichTextLabel = $Name
onready var cost: Label = $Cost

enum State {
	SELECTED,
	UNSELECTED,
}

const textures = {
	State.SELECTED: preload("res://assets/graphics/ui/selected.png"),
	State.UNSELECTED: preload("res://assets/graphics/ui/unselected.png"),
}

var state = State.UNSELECTED


func _ready():
	set_label_name("Hello my lord")
	
func set_label_name(new_name: String):
	name_label.bbcode_text = new_name
	
func set_cost(new_cost):
	if new_cost == 0:
		cost.hide()
	else:
		cost.show()
		cost.text = str(new_cost) + " SP"


func set_selected(selected: bool):
	if selected and state == State.UNSELECTED:
		state = State.SELECTED
		selected_texture_rect.texture = textures[State.SELECTED]
	
	elif !selected and state == State.SELECTED:
		state = State.UNSELECTED
		selected_texture_rect.texture = textures[State.UNSELECTED]
		
func toggle_selected():
	if state == State.SELECTED:
		set_selected(false)
	else:
		set_selected(true)
