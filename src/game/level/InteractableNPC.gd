extends Interactable
class_name InteractableNPC

export var id = ""

func _ready():
	var conditions = Flow.get_npc_value(id, "conditions", {})
	var should_be_alive = true
	for condition in conditions.get("exist", []):
		if !State.player.has_condition(condition):
			should_be_alive = false
	if not should_be_alive:
		hide()
		collision_layer = 0
		collision_mask = 0
	if conditions.get("death", []):
		var should_be_dead = true
		for condition in conditions.get("death", []):
			if !State.player.has_condition(condition):
				should_be_dead = false 
		if should_be_dead:
			hide()
			collision_layer = 0
			collision_mask = 0
	print(name)
	print(collision_layer)
	print(collision_mask)

func get_conversation():
	var conversations = Flow.get_npc_value(id, "conversations", {})
	var conversation_keys: Array = conversations.keys()
	conversation_keys.invert()
	for conversation_key in conversation_keys:
		var conditions_met = true
		for condition in conversations[conversation_key].get("conditions", []):
			print("Checking condition ", condition)
			print(State.player.has_condition(condition))
			if not State.player.has_condition(condition):
				conditions_met = false
		if conditions_met:
			return conversations[conversation_key]

	return {
		"dialogue": [{
			"speaker": "copy",
			"text": "Bataar, you're not allowed to speak to me, I don't exist in this game's code..."
		}]
	}
