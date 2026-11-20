## The world in progress and the player's place on its map (étape 5a, spec §5).
## Wave numbers keep counting across worlds: with 8 waves per world, world 2 is
## waves 9 to 16 and its final wave is 16.
class_name WorldRun
extends RefCounted

## Current world, 1 at the start of a game.
var world: int = 1
## Map of the current world ([code]null[/code] until [method start_world]).
var map: WorldMap
## Column of the player's place; -1 = at the start, before column 0.
var column: int = -1
## Index of the player's place in [member column]; -1 at the start.
var node: int = -1
## Place index chosen in each column so far (the path travelled, for display).
var visited: PackedInt32Array = PackedInt32Array()

var _waves_per_world: int


## [param waves_per_world] comes from [member WaveCurve.waves_per_world] (at least 1).
func _init(waves_per_world: int) -> void:
	_waves_per_world = maxi(waves_per_world, 1)


## Shows [param new_map] and puts the player back at the start. Does not change
## [member world]: the caller increments it when a world ends.
func start_world(new_map: WorldMap) -> void:
	map = new_map
	column = -1
	node = -1
	visited = PackedInt32Array()


## Indexes, in the next column, of the places the player can enter now: all of
## column 0 from the start, the current place's links otherwise, none in the
## last column (or before a map is set).
func reachable() -> PackedInt32Array:
	if map == null or map.columns.is_empty():
		return PackedInt32Array()
	if column < 0:
		return PackedInt32Array(range(map.size_of(0)))
	if column >= map.columns.size() - 1:
		return PackedInt32Array()
	return map.links_of(column, node).duplicate()


## Moves the player to place [param index] of the next column. Returns
## [code]false[/code] and changes nothing if that place is not reachable.
func move_to(index: int) -> bool:
	if not reachable().has(index):
		return false
	column += 1
	node = index
	visited.append(index)
	return true


## World of wave [param wave] (1-based): waves 1 to 8 are world 1, 9 to 16 world 2.
func world_of(wave: int) -> int:
	return floori(float(wave - 1) / float(_waves_per_world)) + 1


## Rank of wave [param wave] in its world, 1 to waves_per_world (wave 9 -> 1).
func wave_in_world(wave: int) -> int:
	return (wave - 1) % _waves_per_world + 1


## True when wave [param wave] is the last of its world (8, 16, ...).
func is_final_wave(wave: int) -> bool:
	return wave % _waves_per_world == 0
