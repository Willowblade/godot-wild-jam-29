extends Node2D

onready var floor_to_tiles = {}
onready var floors = get_children()
onready var reversed_floors = floors.duplicate(true)


func _ready():
	reversed_floors.invert()
	
	var i = 0
	for floor_ in floors:
		# create a hashmap for easy access later.
		floor_to_tiles[floor_] = {
			"index": i,
			"tiles": {}
		}
		for tile in floor_.get_used_cells():
			floor_to_tiles[floor_].tiles[tile] = null
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
		var floor_tile_position = floor_.world_to_map(tile_position + floor_to_tiles[floor_].index * Vector2(0, -8))
		if floor_tile_position in floor_to_tiles[floor_].tiles:
			return floor_to_tiles[floor_].index
	push_error("We found a tile position that doesn't belong to any tilemap")
	push_error("{}".format(tile_position))
