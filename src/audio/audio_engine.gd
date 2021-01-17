"""
Audio Engine

Implemented:
	- Background music
	- Sound effects
	- Sounds for objects that generally make sounds

To implement:
	- Speech for conversations
"""
extends Node

onready var background_players = {
	"first": $BackgroundPlayer,
	"second": $SecondBackgroundPlayer,
}

var current_background_player = null


const tracks = {
	"battle2": "res://assets/audio/music/battle2.ogg",
	"battle3": "res://assets/audio/music/battle3.ogg",
	"main": "res://assets/audio/music/main.ogg",
	"main2": "res://assets/audio/music/main2.ogg",
	"menu": "res://assets/audio/music/menu.ogg",
}

const sfx = {
	"desert_ambiance_loop": "res://assets/audio/sfx/desert_ambiance_loop.ogg",
	"door_close": "res://assets/audio/sfx/door_close.ogg",
	"door_open": "res://assets/audio/sfx/door_open.ogg",
	"eagle_screech1": "res://assets/audio/sfx/eagle_screech1.ogg",
	"eagle_screech2": "res://assets/audio/sfx/eagle_screech2.ogg",
	"flap1": "res://assets/audio/sfx/flap1.ogg",
	"flap2": "res://assets/audio/sfx/flap2.ogg",
	"flap3": "res://assets/audio/sfx/flap3.ogg",
	"flap4": "res://assets/audio/sfx/flap4.ogg",
	"footstep1": "res://assets/audio/sfx/footstep1.ogg",
	"footstep2": "res://assets/audio/sfx/footstep2.ogg",
	"footstep3": "res://assets/audio/sfx/footstep3.ogg",
	"footstep4": "res://assets/audio/sfx/footstep4.ogg",

	"slam": "res://assets/audio/sfx/heavenly_slam.ogg",
	"slap": "res://assets/audio/sfx/EnemyHitThump2.ogg",
	"tengrislap": "res://assets/audio/sfx/slap.ogg",
	"throw": "res://assets/audio/sfx/throw.ogg",

	"item_interact": "res://assets/audio/sfx/item_interact.ogg",
	"item_open": "res://assets/audio/sfx/item_open.ogg",

	"bataar_talking": "res://assets/audio/sfx/male_dialogue1.ogg",
	"bataar_explaining": "res://assets/audio/sfx/male_dialogue2.ogg",
	"bataar_mocking": "res://assets/audio/sfx/male_dialogue3.ogg",
	"bataar_correcting": "res://assets/audio/sfx/male_dialogue4.ogg",
	"bataar_whatever": "res://assets/audio/sfx/male_dialogue5.ogg",
	
	"male_talking": "res://assets/audio/sfx/male_dialogue1.ogg",
	"male_explaining": "res://assets/audio/sfx/male_dialogue2.ogg",
	"male_mocking": "res://assets/audio/sfx/male_dialogue3.ogg",
	"male_correcting": "res://assets/audio/sfx/male_dialogue4.ogg",
	"male_whatever": "res://assets/audio/sfx/male_dialogue5.ogg",

	"female_talking": "res://assets/audio/sfx/male_dialogue1.ogg",
	"female_explaining": "res://assets/audio/sfx/male_dialogue2.ogg",
	"female_mocking": "res://assets/audio/sfx/male_dialogue3.ogg",
	"female_correcting": "res://assets/audio/sfx/male_dialogue4.ogg",
	"female_whatever": "res://assets/audio/sfx/male_dialogue5.ogg",

	"female_mumble_1": "res://assets/audio/sfx/female_mumble_1_louder.ogg",
	"female_mumble_2": "res://assets/audio/sfx/female_mumble_2_louder.ogg",
	"female_mumble_3": "res://assets/audio/sfx/female_mumble_3_louder.ogg",

	"monster_hurt1": "res://assets/audio/sfx/EnemyHitThump2.ogg",
	"monster_hurt2": "res://assets/audio/sfx/EnemyHitThump2.ogg",
	"person_hurt1": "res://assets/audio/sfx/EnemyHitThump2.ogg",
	"person_hurt2": "res://assets/audio/sfx/EnemyHitThump2.ogg",
}


onready var background_player: AudioStreamPlayer = $BackgroundPlayer
onready var ambiance_player: AudioStreamPlayer = $AmbiancePlayer
onready var dialogue_player: AudioStreamPlayer = $DialoguePlayer
onready var effects: Node = $Effects


func convert_scale_to_db(scale: float):
	return 20 * log(scale) / log(10)


var background_audio = null

export var MAX_SIMULTANEOUS_EFFECTS = 5


func _ready():
	#play_background_music("light_rain")
	for _i in range(MAX_SIMULTANEOUS_EFFECTS):
		effects.add_effect()


func play_effect(effect_name: String):
	effects.play_effect(sfx[effect_name])

func reset():
#	effects.reset()
	stop_background_music()
	
func play_ambiance():
	ambiance_player.play()

func stop_ambiance():
	ambiance_player.stop()
	
func play_background_music(track_name: String):
	var track_path = tracks[track_name]
	if background_audio == track_path:
		return
		
	var background_player = null
	if current_background_player == null:
		current_background_player = background_players.first
		background_audio = track_path
		current_background_player.stream = load(track_path)
		current_background_player.play()
	else:
		if current_background_player == background_players.first:
			$AnimationPlayer.play("switch_2")
			current_background_player = background_players.second
			background_audio = track_path
			current_background_player.stream = load(track_path)
			current_background_player.play()
		elif current_background_player == background_players.second:
			$AnimationPlayer.play("switch_1")
			current_background_player = background_players.first
			background_audio = track_path
			current_background_player.stream = load(track_path)
			current_background_player.play()
			
func play_dialogue_audio(track_name: String):
	var track_path = sfx[track_name]
	dialogue_player.stop()
	var base_pitch = 1.1 + 0.3 * randf()
	dialogue_player.volume_db = -6
	var dialogue_player_stream = load(track_path)
	if track_name.begins_with("male"):
		dialogue_player.pitch_scale = 0.8 * base_pitch
	if track_name.begins_with("bataar"):
		dialogue_player.pitch_scale = 1.0 * base_pitch
	elif track_name.begins_with("female_mumble"):
		dialogue_player.volume_db = 0
		dialogue_player.pitch_scale = 1.0
	elif track_name.begins_with("female"):
		dialogue_player.pitch_scale = 1.3 * base_pitch
	dialogue_player_stream.loop = false
	dialogue_player.stream = dialogue_player_stream
	dialogue_player.play()

func stop_background_music():
	"""Stops the background music track"""
	if background_player.playing:
		background_player.stop()
		background_audio = null		

var custom = {
	"walking": false,
	"flying": false,
	"was_walking": false,
	"was_flying": false,
	"walking_timer": 0,
	"flying_timer": 0,
	"walking_timeout": 0.12,
	"flying_timeout": 0.3
}

func set_walking(walking: bool):
	custom.walking = walking
	custom.walking_timer = 1
	

func set_flying(flying: bool):
	custom.flying = flying
	custom.flying_timer = 1
	
var footsteps =  ["footstep2", "footstep3", "footstep4"]
# var flaps = ["flap1", "flap2", "flap3", "flap4"]
# var flaps = ["footstep1", "footstep2", "footstep3", "footstep4"]
var flaps = []
func _process(delta):
	var effects_playing = effects.effects_playing.keys()

	if custom.walking:
		var is_walking = false
		for footstep_sfx in footsteps:
			if effects_playing.has(sfx[footstep_sfx]):
				is_walking = true
		if not is_walking and custom.was_walking:
			custom.was_walking = false
			custom.walking_timer = 0
		elif not is_walking:
			custom.walking_timer += delta
			if custom.walking_timer > custom.walking_timeout:
				print("Playing footstep")
				var random_sfx = footsteps[randi() % footsteps.size()]
				play_effect(random_sfx)
		else:
			custom.was_walking = true
	if custom.flying and flaps.size() > 0:
		print(effects_playing)
		var is_flying = false
		for flap_sfx in flaps:
			if effects_playing.has(sfx[flap_sfx]):
				is_flying = true
		if not is_flying and custom.was_flying:
			custom.was_flying = false
			custom.flying_timer = 0
		elif not is_flying:
			custom.flying_timer += delta
			if custom.flying_timer > custom.flying_timeout:
				print("Playing flap")
				var random_sfx = flaps[randi() % flaps.size()]
				play_effect(random_sfx)
		else:
			custom.was_flying = true
