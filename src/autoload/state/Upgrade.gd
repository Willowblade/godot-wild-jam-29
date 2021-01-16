extends Reference
class_name class_upgrade

var id := ""

var context : Dictionary setget set_context, get_context
func set_context(value : Dictionary) -> void:
	if not value.has("id"):
		push_error("Upgrade context requires id!")
		return

	id = value.id

func get_context() -> Dictionary:
	var _context := {}

	_context.id = id

	return _context

# These are all constants derived from data.JSON and should be treated as such!
var name : String setget , get_name
func get_name() -> String:
	return Flow.get_upgrade_value(id, "name", "MISSING NAME")

var description : String setget , get_description
func get_description() -> String:
	return Flow.get_upgrade_value(id, "description", "MISSING DESCRIPTION")

var effect : Dictionary setget , get_effect
func get_effect() -> Dictionary:
	return Flow.get_upgrade_value(id, "effect", {})

var target : Dictionary setget , get_target
func get_target() -> Dictionary:
	return Flow.get_upgrade_value(id, "target", {})
