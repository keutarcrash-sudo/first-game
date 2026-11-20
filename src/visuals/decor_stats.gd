## Tuning values of the neon decor (assets/data/decor.json). Every key is
## required; validated on load.
class_name DecorStats
extends RefCounted

const _POSITIVE_KEYS: Array[String] = ["count", "min_spacing", "crystal_clearance", "path_clearance"]

## Number of pieces to place on the field.
var count: int
## Minimum distance in pixels between two pieces.
var min_spacing: float
## Minimum distance in pixels between a piece and the crystal's start.
var crystal_clearance: float
## Pieces closer than this many pixels to the wave path are hidden.
var path_clearance: float
## Distance in pixels kept free between a piece and the field edge (0 or more).
var edge_margin: float
## Sheet folders (res://...) of the pieces, one entry per variant.
var piece_sheets: PackedStringArray = PackedStringArray()
## On-screen height in pixels of each piece's whole cell, same order as [member piece_sheets].
var piece_heights: PackedFloat32Array = PackedFloat32Array()


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> DecorStats:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("DecorStats: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("DecorStats: '%s' is not a valid JSON object." % path)
		return null
	for key: String in _POSITIVE_KEYS:
		var value: Variant = data.get(key)
		if not (value is float or value is int) or value <= 0:
			push_error("DecorStats: key '%s' in '%s' must be a positive number (got %s)." % [key, path, value])
			return null
	var margin: Variant = data.get("edge_margin")
	if not (margin is float or margin is int) or margin < 0:
		push_error("DecorStats: key 'edge_margin' in '%s' must be a number of 0 or more (got %s)." % [path, margin])
		return null
	var pieces: Variant = data.get("pieces")
	if not pieces is Array or (pieces as Array).is_empty():
		push_error("DecorStats: key 'pieces' is missing or empty in '%s'." % path)
		return null
	var stats := DecorStats.new()
	stats.count = int(data["count"])
	stats.min_spacing = float(data["min_spacing"])
	stats.crystal_clearance = float(data["crystal_clearance"])
	stats.path_clearance = float(data["path_clearance"])
	stats.edge_margin = float(margin)
	for i: int in (pieces as Array).size():
		var entry: Variant = pieces[i]
		if not entry is Dictionary or not entry.get("sheet") is String or (entry["sheet"] as String).is_empty():
			push_error("DecorStats: key 'pieces[%d].sheet' must be a folder path in '%s'." % [i, path])
			return null
		var height: Variant = entry.get("height_px")
		if not (height is float or height is int) or height <= 0:
			push_error("DecorStats: key 'pieces[%d].height_px' must be a positive number in '%s'." % [i, path])
			return null
		stats.piece_sheets.append(entry["sheet"])
		stats.piece_heights.append(float(height))
	return stats
