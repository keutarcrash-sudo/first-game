## Wave difficulty curve (story 002). Loaded once from a JSON file: a list of
## hand-tuned first waves, then a growth rule applied to the last listed wave
## for every wave after it, so waves go on indefinitely.
class_name WaveCurve
extends RefCounted

const WAVE_KEYS := ["enemy_count", "hp_multiplier", "spawn_interval"]
const GROWTH_KEYS := [
	"enemy_count_per_wave", "hp_multiplier_per_wave",
	"spawn_interval_factor", "min_spawn_interval",
]

## Seconds before the first wave starts.
var first_wave_delay: float

var _waves: Array[Dictionary] = []
var _enemy_count_per_wave: float
var _hp_multiplier_per_wave: float
var _spawn_interval_factor: float
var _min_spawn_interval: float


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> WaveCurve:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("WaveCurve: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("WaveCurve: '%s' is not a valid JSON object." % path)
		return null
	if not _is_number(data.get("first_wave_delay"), false):
		push_error("WaveCurve: key 'first_wave_delay' in '%s' is missing or not a positive number." % path)
		return null
	var waves: Variant = data.get("waves")
	if not waves is Array or waves.is_empty():
		push_error("WaveCurve: key 'waves' in '%s' must be a non-empty list." % path)
		return null
	var curve := WaveCurve.new()
	for i: int in waves.size():
		var wave: Variant = waves[i]
		if not wave is Dictionary:
			push_error("WaveCurve: 'waves[%d]' in '%s' must be an object." % [i, path])
			return null
		for key: String in WAVE_KEYS:
			if not _is_number(wave.get(key), false):
				push_error("WaveCurve: key '%s' of 'waves[%d]' in '%s' is missing or not a positive number." % [key, i, path])
				return null
		curve._waves.append({
			"enemy_count": roundi(wave["enemy_count"]),
			"hp_multiplier": float(wave["hp_multiplier"]),
			"spawn_interval": float(wave["spawn_interval"]),
		})
	var growth: Variant = data.get("growth")
	if not growth is Dictionary:
		push_error("WaveCurve: key 'growth' in '%s' must be an object." % path)
		return null
	for key: String in GROWTH_KEYS:
		if not _is_number(growth.get(key), key.ends_with("_per_wave")):
			push_error("WaveCurve: key 'growth.%s' in '%s' is missing or not a valid number." % [key, path])
			return null
	if growth["enemy_count_per_wave"] <= 0 and growth["hp_multiplier_per_wave"] <= 0 and growth["spawn_interval_factor"] >= 1.0:
		push_error("WaveCurve: 'growth' in '%s' must make waves harder (more enemies, more HP or a faster spawn)." % path)
		return null
	curve.first_wave_delay = data["first_wave_delay"]
	curve._enemy_count_per_wave = growth["enemy_count_per_wave"]
	curve._hp_multiplier_per_wave = growth["hp_multiplier_per_wave"]
	curve._spawn_interval_factor = growth["spawn_interval_factor"]
	curve._min_spawn_interval = growth["min_spawn_interval"]
	return curve


## Returns the parameters of wave [param wave_number] (1-based) as a Dictionary
## with the keys [code]enemy_count[/code] (int), [code]hp_multiplier[/code] and
## [code]spawn_interval[/code] (seconds between two spawns).
func get_wave(wave_number: int) -> Dictionary:
	var index: int = wave_number - 1
	if index < _waves.size():
		return _waves[index]
	var steps: int = index - _waves.size() + 1
	var last: Dictionary = _waves[_waves.size() - 1]
	return {
		"enemy_count": roundi(last["enemy_count"] + _enemy_count_per_wave * steps),
		"hp_multiplier": last["hp_multiplier"] + _hp_multiplier_per_wave * steps,
		"spawn_interval": maxf(last["spawn_interval"] * pow(_spawn_interval_factor, steps), _min_spawn_interval),
	}


## A number, strictly positive unless [param allow_zero] is set (then zero or more).
static func _is_number(value: Variant, allow_zero: bool) -> bool:
	if not (value is float or value is int):
		return false
	return value >= 0 if allow_zero else value > 0
