extends Control

onready var bataar_action_timer_container = $VBoxContainer/MarginContainer/PanelContainer/HBoxContainer/BataarActionTimerContainer
onready var burg_action_timer_container = $VBoxContainer/MarginContainer/PanelContainer/HBoxContainer/BurgActionTimerContainer

onready var bataar_action_timer = $VBoxContainer/MarginContainer/PanelContainer/HBoxContainer/BataarActionTimerContainer/ActionTimer
onready var burg_action_timer = $VBoxContainer/MarginContainer/PanelContainer/HBoxContainer/BurgActionTimerContainer/ActionTimer

onready var health_value: Label = $VBoxContainer/MarginContainer/PanelContainer/HBoxContainer/HealthContainer/HealthValue
onready var stamina_value: Label = $VBoxContainer/MarginContainer/PanelContainer/HBoxContainer/StaminaContainer/StaminaValue

func _ready():
	GameFlow.register_overlay("hud", self)


func _on_updated_charges(chargers):
	for charger in chargers:
		if charger.character is Player:
			bataar_action_timer.value = int(charger.progress / charger.threshold * 100)
		elif charger.character is Eagle:
			burg_action_timer.value = int(charger.progress / charger.threshold * 100)

func on_player_updated_stats(updated_stats):
	var player_stats = State.player.get_stats()

	# TODO get max player stat from game data (calculation plus upgrades)
	health_value.text = str(updated_stats.health) + "/" + str(player_stats.max_health)
	stamina_value.text = str(updated_stats.stamina) + "/" + str(player_stats.max_stamina)

func set_battle_mode():
	bataar_action_timer_container.show()
	burg_action_timer_container.show()

func set_explore_mode():
	bataar_action_timer_container.hide()
	burg_action_timer_container.hide()
