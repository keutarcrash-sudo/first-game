## Tuning values for the cannon and frost towers (story 004,
## design/game-brief.md MVP feature 4). Loaded once from a JSON file with one
## object per tower; every value is required and must be a positive number.
## Units: cost in gold, range / radius / bullet_* distances in pixels, speed in
## pixels per second, fire_interval in seconds, slow_factor a fraction of the
## normal enemy speed (0.45 = 45 % speed).
class_name TowerStats
extends RefCounted

## The two tower types the player can build.
enum Kind { CANNON, FROST }

const CANNON_KEYS := [
	"cost", "range", "radius", "damage", "fire_interval",
	"bullet_speed", "bullet_radius", "bullet_max_range",
]
const FROST_KEYS := ["cost", "range", "radius", "slow_factor"]
const DESIGNATION_KEYS := ["click_margin"]

## Cannon price, in gold.
var cannon_cost: int
## Distance in pixels within which the cannon picks a target.
var cannon_range: float
## Cannon body radius, in pixels (drawing and placement footprint).
var cannon_radius: float
## Damage of one cannon shot.
var cannon_damage: float
## Seconds between two cannon shots.
var cannon_fire_interval: float
## Cannon shot speed, in pixels per second.
var cannon_bullet_speed: float
## Cannon shot radius, in pixels. Keep it small relative to the enemy radius so a shot cannot tunnel through.
var cannon_bullet_radius: float
## Distance in pixels after which a cannon shot disappears.
var cannon_bullet_max_range: float
## Frost tower price, in gold.
var frost_cost: int
## Distance in pixels within which the frost tower slows enemies.
var frost_range: float
## Frost tower body radius, in pixels (drawing and placement footprint).
var frost_radius: float
## Fraction of normal speed kept by a slowed enemy, in ]0, 1].
var frost_slow_factor: float
## Extra distance in pixels around an enemy's body within which a left click designates it.
var designation_click_margin: float


## Price in gold of a tower of [param kind].
func cost_of(kind: Kind) -> int:
	return cannon_cost if kind == Kind.CANNON else frost_cost


## Body radius in pixels of a tower of [param kind].
func radius_of(kind: Kind) -> float:
	return cannon_radius if kind == Kind.CANNON else frost_radius


## Range in pixels of a tower of [param kind].
func range_of(kind: Kind) -> float:
	return cannon_range if kind == Kind.CANNON else frost_range


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> TowerStats:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("TowerStats: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("TowerStats: '%s' is not a valid JSON object." % path)
		return null
	var cannon: Dictionary = _read_section(data, "cannon", CANNON_KEYS, path)
	var frost: Dictionary = _read_section(data, "frost", FROST_KEYS, path)
	var designation: Dictionary = _read_section(data, "designation", DESIGNATION_KEYS, path)
	if cannon.is_empty() or frost.is_empty() or designation.is_empty():
		return null
	if frost["slow_factor"] > 1.0:
		push_error("TowerStats: key 'frost.slow_factor' in '%s' must be at most 1 (got %s)." % [path, frost["slow_factor"]])
		return null
	var stats := TowerStats.new()
	stats.cannon_cost = int(cannon["cost"])
	stats.cannon_range = cannon["range"]
	stats.cannon_radius = cannon["radius"]
	stats.cannon_damage = cannon["damage"]
	stats.cannon_fire_interval = cannon["fire_interval"]
	stats.cannon_bullet_speed = cannon["bullet_speed"]
	stats.cannon_bullet_radius = cannon["bullet_radius"]
	stats.cannon_bullet_max_range = cannon["bullet_max_range"]
	stats.frost_cost = int(frost["cost"])
	stats.frost_range = frost["range"]
	stats.frost_radius = frost["radius"]
	stats.frost_slow_factor = frost["slow_factor"]
	stats.designation_click_margin = designation["click_margin"]
	return stats


## Returns the validated object [param section] of [param data], or an empty
## dictionary after printing an error.
static func _read_section(data: Dictionary, section: String, keys: Array, path: String) -> Dictionary:
	if not data.get(section) is Dictionary:
		push_error("TowerStats: section '%s' is missing in '%s'." % [section, path])
		return {}
	var values: Dictionary = data[section]
	for key: String in keys:
		if not values.has(key):
			push_error("TowerStats: key '%s.%s' is missing in '%s'." % [section, key, path])
			return {}
		var value: Variant = values[key]
		if not (value is float or value is int) or value <= 0:
			push_error("TowerStats: key '%s.%s' in '%s' must be a positive number (got %s)." % [section, key, path, value])
			return {}
		if key == "cost" and value != floorf(value):
			push_error("TowerStats: key '%s.cost' in '%s' must be a whole number (got %s)." % [section, path, value])
			return {}
	return values
