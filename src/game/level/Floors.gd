tool
extends Node2D

onready var floor_to_tiles = {}
onready var floors = get_children()
onready var reversed_floors = floors.duplicate(true)


func _ready():
	cleanup()

func cleanup():
	floor_to_tiles = {}
	floors = get_children()
	reversed_floors = floors.duplicate(true)
	reversed_floors.invert()
	
	var i = 0
	for floor_ in floors:
		floor_.remove_borders()
		# create a hashmap for easy access later.
		floor_to_tiles[floor_] = {
			"index": i,
			"tiles": {}
		}
		for tile in floor_.get_used_cells():
			floor_to_tiles[floor_].tiles[tile] = null
		i += 1
		
	if Engine.editor_hint:
		var all_tiles_on_top = {}
		i = 0
		for reversed_floor_ in reversed_floors:
			reversed_floor_.remove_borders()
			reversed_floor_.add_from_upper(all_tiles_on_top.keys())
			var all_tiles_on_top_keys = all_tiles_on_top.keys()
			
			# we don't need to do this for the lowest floor
			if reversed_floor_ == floors[0]:
				continue
				
			all_tiles_on_top = {}
			for tile in reversed_floor_.get_used_cells():
				all_tiles_on_top[tile] = null
			i += 1
			
	for floor_ in floors:
		floor_.clean()
		floor_.activate_borders()

func refresh(floor_index: int):
	for floor_ in floors:
		if floor_to_tiles[floor_].index < floor_index:
			floor_.deactivate()
		elif floor_to_tiles[floor_].index > floor_index + 3:
			floor_.deactivate()
		else:
			floor_.activate()

func get_floors_below(floor_index: int):
	var floors_below = []
	for floor_ in floors:
		if floor_to_tiles[floor_].index < floor_index:
			floors_below.append(floor_)
	return floors_below
	
func get_floors_above(floor_index: int):
	var floors_above = []
	for floor_ in floors:
		if floor_to_tiles[floor_].index >= floor_index:
			floors_above.append(floor_)
	return floors_above
	
func get_tile_floor(tile_position: Vector2):
	for floor_ in reversed_floors:
		var floor_tile_position = floor_.world_to_map(tile_position + floor_to_tiles[floor_].index * Vector2(0, 8) - Vector2(0, 8))
		if floor_tile_position in floor_to_tiles[floor_].tiles:
			return floor_to_tiles[floor_].index
	push_error("We found a tile position that doesn't belong to any tilemap")
	push_error("{}".format(tile_position))


func _process(delta):
	if Engine.editor_hint:
		if Input.is_action_just_pressed("ui_home"):
			for floor_ in get_children():
				floor_.create_tile_mappings()
			cleanup()
			
