## Tuning values for the crystal's path (étape 1 — le cristal qui avance).
## Read from the "path" object of assets/data/waves.json. Every key is
## required and must be a positive number.
class_name PathSettings
extends RefCounted

const REQUIRED_KEYS := ["segment_length", "max_turn_degrees", "margin"]

## Length in pixels of each straight segment of the path.
var segment_length: float
## Largest heading change between two segments, in degrees (at most 180).
var max_turn_degrees: float
## Distance in pixels the path keeps from the arena edges.
var margin: float


## Validates the [code]path[/code] object [param data] (read from the file
## [param path]). Returns [code]null[/code] and prints an error naming the file
## and the faulty key if anything is wrong.
static func from_dict(data: Variant, path: String) -> PathSettings:
	if not data is Dictionary:
		push_error("PathSettings: key 'path' in '%s' must be an object." % path)
		return null
	for key: String in REQUIRED_KEYS:
		if not data.has(key):
			push_error("PathSettings: key 'path.%s' is missing in '%s'." % [key, path])
			return null
		var value: Variant = data[key]
		if not (value is float or value is int) or value <= 0:
			push_error("PathSettings: key 'path.%s' in '%s' must be a positive number (got %s)." % [key, path, value])
			return null
	if float(data["max_turn_degrees"]) > 180.0:
		push_error("PathSettings: key 'path.max_turn_degrees' in '%s' must be at most 180 (got %s)." % [path, data["max_turn_degrees"]])
		return null
	var settings := PathSettings.new()
	settings.segment_length = data["segment_length"]
	settings.max_turn_degrees = data["max_turn_degrees"]
	settings.margin = data["margin"]
	return settings
