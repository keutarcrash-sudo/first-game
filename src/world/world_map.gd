## One world's map (étape 5a, spec §6): columns of places read left to right, from
## the start (linked to every place of column 0) to the final-wave flag (every
## place of the last column leads to it). Pure data, built by WorldMapGenerator.
class_name WorldMap
extends RefCounted

const SHOP: StringName = &"shop"
const TREASURE: StringName = &"treasure"
const REST: StringName = &"rest"
## Every place type, in a fixed order.
const TYPES: Array[StringName] = [SHOP, TREASURE, REST]

## One entry per column; each column is an [code]Array[Dictionary][/code] of places
## [code]{ "type": StringName, "links": PackedInt32Array }[/code]. [code]links[/code]
## holds indexes in the next column, ascending; the last column's links are empty
## (its places lead to the final-wave flag).
var columns: Array = []


## Builds one place entry of [member columns].
static func make_place(type: StringName, links: PackedInt32Array) -> Dictionary:
	return { "type": type, "links": links }


## Number of places in column [param column].
func size_of(column: int) -> int:
	return (columns[column] as Array).size()


## Type of place [param index] of column [param column] (one of [constant TYPES]).
func type_of(column: int, index: int) -> StringName:
	var place: Dictionary = (columns[column] as Array)[index]
	return place["type"]


## Indexes in the next column that place [param index] of column [param column] leads to.
func links_of(column: int, index: int) -> PackedInt32Array:
	var place: Dictionary = (columns[column] as Array)[index]
	return place["links"]


## Every path from the start to the flag, as one place index per column.
## Expects a well-formed map (see [method WorldMapGenerator.is_valid]).
func paths() -> Array[PackedInt32Array]:
	var result: Array[PackedInt32Array] = []
	if columns.is_empty():
		return result
	for index: int in size_of(0):
		_collect(0, index, PackedInt32Array(), result)
	return result


func _collect(column: int, index: int, prefix: PackedInt32Array, result: Array[PackedInt32Array]) -> void:
	var path: PackedInt32Array = prefix.duplicate()
	path.append(index)
	if column == columns.size() - 1:
		result.append(path)
		return
	for next: int in links_of(column, index):
		_collect(column + 1, next, path, result)
