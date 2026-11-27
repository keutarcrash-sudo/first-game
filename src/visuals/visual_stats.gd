## Which sprite sheet folder each object uses and how tall it is on screen
## (assets/data/visuals.json). Every key is required. Enemy sheets and heights live in
## enemy_types.json, tower sheets and heights in towers.json ([TowerDef]).
class_name VisualStats
extends RefCounted

const _HEIGHT_KEYS: Array[String] = ["hero", "crystal"]

## Sheet folder of the crystal cart.
var crystal_sheet: String

var _heroes: Dictionary = {}
var _heights: Dictionary = {}


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> VisualStats:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("VisualStats: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("VisualStats: '%s' is not a valid JSON object." % path)
		return null
	var stats := VisualStats.new()
	var heroes: Variant = data.get("hero")
	if not heroes is Dictionary or not (heroes as Dictionary).has("default"):
		push_error("VisualStats: key 'hero' (with a 'default' entry) is missing in '%s'." % path)
		return null
	for spec_id: String in heroes:
		if not heroes[spec_id] is String or (heroes[spec_id] as String).is_empty():
			push_error("VisualStats: key 'hero.%s' must be a folder path in '%s'." % [spec_id, path])
			return null
		stats._heroes[spec_id] = heroes[spec_id]
	for key: String in ["crystal"]:
		if not data.get(key) is String or (data[key] as String).is_empty():
			push_error("VisualStats: key '%s' must be a folder path in '%s'." % [key, path])
			return null
	stats.crystal_sheet = data["crystal"]
	var heights: Variant = data.get("cell_height_px")
	if not heights is Dictionary:
		push_error("VisualStats: key 'cell_height_px' is missing in '%s'." % path)
		return null
	for key: String in _HEIGHT_KEYS:
		var value: Variant = heights.get(key)
		if not (value is float or value is int) or value <= 0:
			push_error("VisualStats: key 'cell_height_px.%s' must be a positive number in '%s'." % [key, path])
			return null
		stats._heights[key] = float(value)
	return stats


## Sheet folder for the hero spec [param spec_id]; falls back to "default".
func hero_sheet(spec_id: String) -> String:
	return _heroes.get(spec_id, _heroes["default"])


## On-screen height in pixels of the whole cell for [param key]
## (hero, crystal). 0 if unknown.
func height(key: String) -> float:
	if not _heights.has(key):
		push_error("VisualStats: unknown height key '%s'." % key)
		return 0.0
	return _heights[key]
