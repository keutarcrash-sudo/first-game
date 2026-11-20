## Enemy types (étape 4, spec §6): multipliers against the goblin of defence_stats.json,
## behaviour, sprite sheet and wave count rule of each type, loaded from enemy_types.json.
## Every type is a Dictionary with the keys of the file; the behaviour-specific keys
## are validated here so the behaviour components can read them without checks.
class_name EnemyTypes
extends RefCounted

const BEHAVIOURS: Array[String] = ["contact", "kamikaze", "artillery"]
const COMMON_KEYS: Array[String] = ["hp_mult", "speed_mult", "height_px"]
## Names shown in the wave previews (étape 5a): singular and plural, non-empty strings.
const NAME_KEYS: Array[String] = ["display_name", "display_plural"]
const BEHAVIOUR_KEYS: Dictionary = {
	"contact": [],
	"kamikaze": ["fuse", "radius", "crystal_damage", "hero_damage"],
	"artillery": ["stand_off", "fire_interval", "telegraph", "radius", "aim_spread", "crystal_damage", "hero_damage"],
}
## base_count value meaning "the wave's own enemy_count from waves.json".
const WAVE_BASE_COUNT := -1

var _types: Array[Dictionary] = []


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> EnemyTypes:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("EnemyTypes: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	return from_data(JSON.parse_string(text), path)


## Validates already-parsed JSON [param data] ([param source] names the file in errors).
## Returns [code]null[/code] and prints an error on the first problem.
static func from_data(data: Variant, source: String) -> EnemyTypes:
	if not data is Dictionary or not (data as Dictionary).get("types") is Array:
		push_error("EnemyTypes: '%s' must be a JSON object with a 'types' array." % source)
		return null
	var result := EnemyTypes.new()
	var seen: Dictionary = {}
	var entries: Array = data["types"]
	if entries.is_empty():
		push_error("EnemyTypes: key 'types' in '%s' must not be empty." % source)
		return null
	for i: int in entries.size():
		var entry: Variant = entries[i]
		var where := "types[%d]" % i
		if not entry is Dictionary:
			push_error("EnemyTypes: key '%s' in '%s' must be an object." % [where, source])
			return null
		var type: Dictionary = entry
		if not type.get("id") is String or (type["id"] as String).is_empty() or seen.has(type["id"]):
			push_error("EnemyTypes: key '%s.id' in '%s' must be a unique non-empty string." % [where, source])
			return null
		seen[type["id"]] = true
		if not type.get("sheet") is String or (type["sheet"] as String).is_empty():
			push_error("EnemyTypes: key '%s.sheet' in '%s' must be a non-empty string." % [where, source])
			return null
		for key: String in NAME_KEYS:
			if not type.get(key) is String or (type[key] as String).is_empty():
				push_error("EnemyTypes: key '%s.%s' in '%s' must be a non-empty string." % [where, key, source])
				return null
		if not type.get("behaviour") is String or not BEHAVIOURS.has(type["behaviour"]):
			push_error("EnemyTypes: key '%s.behaviour' in '%s' must be one of %s." % [where, source, BEHAVIOURS])
			return null
		var keys: Array = COMMON_KEYS + (BEHAVIOUR_KEYS[type["behaviour"]] as Array)
		for key: String in keys:
			if not _is_number(type.get(key)) or type[key] <= 0:
				push_error("EnemyTypes: key '%s.%s' in '%s' must be a positive number." % [where, key, source])
				return null
		if not _is_number(type.get("start_wave")) or type["start_wave"] < 1:
			push_error("EnemyTypes: key '%s.start_wave' in '%s' must be a number >= 1." % [where, source])
			return null
		if not _is_number(type.get("base_count")) or (type["base_count"] < 0 and int(type["base_count"]) != WAVE_BASE_COUNT):
			push_error("EnemyTypes: key '%s.base_count' in '%s' must be >= 0 or %d." % [where, source, WAVE_BASE_COUNT])
			return null
		if type.has("per_wave") and (not _is_number(type["per_wave"]) or type["per_wave"] < 0):
			push_error("EnemyTypes: key '%s.per_wave' in '%s' must be a number >= 0." % [where, source])
			return null
		result._types.append(type)
	return result


## Every type, in file order.
func all() -> Array[Dictionary]:
	return _types


## The type with [param type_id], or an empty Dictionary when unknown.
func get_type(type_id: String) -> Dictionary:
	for type: Dictionary in _types:
		if type["id"] == type_id:
			return type
	return {}


## How many enemies of [param type_id] wave [param wave] holds: 0 before the type's
## start_wave, then base_count + floor(per_wave x (wave - start_wave)).
## A base_count of -1 means [param base_count] (the wave's own enemy_count).
func count_for(type_id: String, wave: int, base_count: int) -> int:
	var type: Dictionary = get_type(type_id)
	if type.is_empty():
		push_error("EnemyTypes: unknown type '%s'." % type_id)
		return 0
	var start: int = int(type["start_wave"])
	if wave < start:
		return 0
	var base: int = base_count if int(type["base_count"]) == WAVE_BASE_COUNT else int(type["base_count"])
	return base + floori(float(type.get("per_wave", 0.0)) * (wave - start))


## How many enemies of each type wave [param wave] holds (étape 5a, spec §8bis):
## type id -> count, in type order, each count [code]roundi(count_for x count_mult)[/code];
## types with no enemy are left out. [param count_mult] is 1 for a normal wave and
## [member WaveCurve.final_count_mult] for a world's final wave.
func composition(wave: int, base_count: int, count_mult: float) -> Dictionary:
	var result: Dictionary = {}
	for type: Dictionary in _types:
		var count: int = roundi(count_for(type["id"], wave, base_count) * count_mult)
		if count > 0:
			result[type["id"]] = count
	return result


## Text of [param counts] (a [method composition] result), e.g.
## "15 gobelins, 7 kamikazes, 1 artilleur": singular name for 1, plural otherwise.
func preview_text(counts: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for type_id: String in counts:
		var type: Dictionary = get_type(type_id)
		if type.is_empty():
			push_error("EnemyTypes: unknown type '%s'." % type_id)
			continue
		var count: int = counts[type_id]
		parts.append("%d %s" % [count, type["display_name"] if count == 1 else type["display_plural"]])
	return ", ".join(parts)


static func _is_number(value: Variant) -> bool:
	return value is float or value is int
