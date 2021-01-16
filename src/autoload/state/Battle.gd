extends Reference
class_name class_battle

var id := ""
var completed := false

func _ready():
	pass # Replace with function body.

var context : Dictionary setget set_context, get_context
func set_context(value : Dictionary) -> void:
	if not value.has("id"):
		push_error("Battle context requires id!")

	id = value.id
	completed = value.get("completed", false)

func get_context() -> Dictionary:
	var _context := {}

	# Only save the Battle to the context if it is completed!
	if completed:
		_context.id = id
		_context.completed = true

	return _context
