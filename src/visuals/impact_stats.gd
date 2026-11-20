## Screen shake and hit-stop values (assets/data/impact.json, passe graphique 1).
## Every key is required; strengths and durations must be positive numbers and
## the hit-stop time scale must be above 0 and at most 1, and its min_interval
## (real seconds between two hit-stops) at least 0.
class_name ImpactStats
extends RefCounted

const _KINDS: Array[String] = ["small", "big"]

## Hit-stop length in real seconds.
var hitstop_duration: float
## Value of [code]Engine.time_scale[/code] during a hit-stop.
var hitstop_time_scale: float
## Minimum real seconds between two accepted hit-stops.
var hitstop_min_interval: float

var _strengths: Dictionary = {}
var _durations: Dictionary = {}


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> ImpactStats:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("ImpactStats: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("ImpactStats: '%s' is not a valid JSON object." % path)
		return null
	var stats := ImpactStats.new()
	var shake: Variant = data.get("shake")
	if not shake is Dictionary:
		push_error("ImpactStats: key 'shake' is missing in '%s'." % path)
		return null
	for kind: String in _KINDS:
		var entry: Variant = (shake as Dictionary).get(kind)
		if not entry is Dictionary:
			push_error("ImpactStats: key 'shake.%s' is missing in '%s'." % [kind, path])
			return null
		for field: String in ["strength", "duration"]:
			var value: Variant = (entry as Dictionary).get(field)
			if not (value is float or value is int) or value <= 0:
				push_error("ImpactStats: key 'shake.%s.%s' must be a positive number in '%s'." % [kind, field, path])
				return null
		stats._strengths[StringName(kind)] = float(entry["strength"])
		stats._durations[StringName(kind)] = float(entry["duration"])
	var hitstop: Variant = data.get("hitstop")
	if not hitstop is Dictionary:
		push_error("ImpactStats: key 'hitstop' is missing in '%s'." % path)
		return null
	var duration: Variant = (hitstop as Dictionary).get("duration")
	if not (duration is float or duration is int) or duration <= 0:
		push_error("ImpactStats: key 'hitstop.duration' must be a positive number in '%s'." % path)
		return null
	var scale: Variant = (hitstop as Dictionary).get("time_scale")
	if not (scale is float or scale is int) or scale <= 0 or scale > 1:
		push_error("ImpactStats: key 'hitstop.time_scale' must be above 0 and at most 1 in '%s'." % path)
		return null
	var min_interval: Variant = (hitstop as Dictionary).get("min_interval")
	if not (min_interval is float or min_interval is int) or min_interval < 0:
		push_error("ImpactStats: key 'hitstop.min_interval' must be a number of at least 0 in '%s'." % path)
		return null
	stats.hitstop_duration = float(duration)
	stats.hitstop_time_scale = float(scale)
	stats.hitstop_min_interval = float(min_interval)
	return stats


## Whether [param kind] ([code]&"small"[/code] or [code]&"big"[/code]) is a known shake.
func has_shake(kind: StringName) -> bool:
	return _strengths.has(kind)


## Peak offset in pixels of the shake [param kind].
func shake_strength(kind: StringName) -> float:
	return _strengths[kind]


## Length in real seconds of the shake [param kind].
func shake_duration(kind: StringName) -> float:
	return _durations[kind]
