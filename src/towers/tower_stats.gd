## Tuning values for the cannon and frost towers (story 004,
## design/game-brief.md MVP feature 4). Loaded once from a JSON file with one
## object per tower; every value is required and must be a positive number.
## Units: cost in gold, range / radius / bullet_* distances in pixels, speed in
## pixels per second, fire_interval in seconds, slow_factor a fraction of the
## normal enemy speed (0.45 = 45 % speed).
## Towers T1 adds the reserve prices ([code]reserve[/code]), the freeze rules
## ([code]freeze[/code]), the chain-reaction cap ([code]chain[/code]) and the
## upgrade branches ([code]branches[/code]: tower key -> branch id -> values,
## each branch carrying a [code]label[/code] string and positive numbers).
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
const RESERVE_KEYS := ["price_step"]
const FREEZE_KEYS := ["dwell", "duration", "cooldown", "frozen_vulnerability"]
const CHAIN_KEYS := ["max_per_frame"]
## JSON key of each tower kind in the [code]branches[/code] section.
const KIND_KEYS := {Kind.CANNON: "cannon", Kind.FROST: "frost"}
## Keys every branch read by the code must carry: tower key -> branch id -> keys
## ([code]label[/code] is a string, the others positive numbers).
const BRANCH_KEYS := {
	"cannon": {
		"incendiaire": ["label", "burn_duration", "burn_dps", "card_duration_mult", "l3_explosion_radius", "l3_explosion_damage"],
		"perforant": ["label", "pierce_total", "l3_shots", "l3_spread_degrees"],
	},
	"frost": {
		"blizzard": ["label", "range_mult", "dwell", "l3_wet_duration"],
		"eclats": ["label", "shard_radius", "shard_damage", "l3_shard_freeze"],
	},
}
## Number of upgrade costs: level 1 -> 2, then level 2 -> 3.
const UPGRADE_COUNT := 2

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
## Extra base price, in gold, for each tower of the same kind already bought (free towers do not count).
var price_step: int
## Upgrade prices in gold: index 0 is level 1 -> 2, index 1 is level 2 -> 3.
var upgrade_costs: Array[int] = []
## Seconds an enemy must spend in at least one frost zone before it freezes.
var freeze_dwell: float
## Seconds a freeze lasts.
var freeze_duration: float
## Seconds after a freeze ends before the enemy can freeze again.
var freeze_cooldown: float
## Extra damage fraction taken by a frozen enemy (0.25 = +25 %).
var frozen_vulnerability: float
## Most chain effects (explosions, shards) resolved in one frame.
var chain_max_per_frame: int
## Upgrade branches: [enum Kind] -> { branch id (StringName) -> Dictionary of
## values }. Numbers are floats as read from JSON; [code]label[/code] is a String.
var branches: Dictionary = {}


## Price in gold of a tower of [param kind].
func cost_of(kind: Kind) -> int:
	return cannon_cost if kind == Kind.CANNON else frost_cost


## Body radius in pixels of a tower of [param kind].
func radius_of(kind: Kind) -> float:
	return cannon_radius if kind == Kind.CANNON else frost_radius


## Range in pixels of a tower of [param kind].
func range_of(kind: Kind) -> float:
	return cannon_range if kind == Kind.CANNON else frost_range


## Branch ids of a tower of [param kind], in file order.
func branch_ids(kind: Kind) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in (branches.get(kind, {}) as Dictionary):
		ids.append(id)
	return ids


## Value [param key] of branch [param branch] of a tower of [param kind], or
## [code]null[/code] if the branch or the key does not exist.
func branch_value(kind: Kind, branch: StringName, key: String) -> Variant:
	var values: Dictionary = (branches.get(kind, {}) as Dictionary).get(branch, {})
	return values.get(key)


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> TowerStats:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("TowerStats: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	return from_data(JSON.parse_string(text), path)


## Validates already parsed JSON [param data]; [param path] names the source in
## error messages. Returns [code]null[/code] after an error if anything is wrong.
static func from_data(data: Variant, path: String) -> TowerStats:
	if not data is Dictionary:
		push_error("TowerStats: '%s' is not a valid JSON object." % path)
		return null
	var cannon: Dictionary = _read_section(data, "cannon", CANNON_KEYS, path)
	var frost: Dictionary = _read_section(data, "frost", FROST_KEYS, path)
	var designation: Dictionary = _read_section(data, "designation", DESIGNATION_KEYS, path)
	if cannon.is_empty() or frost.is_empty() or designation.is_empty():
		return null
	var reserve: Dictionary = _read_section(data, "reserve", RESERVE_KEYS, path)
	var freeze: Dictionary = _read_section(data, "freeze", FREEZE_KEYS, path)
	var chain: Dictionary = _read_section(data, "chain", CHAIN_KEYS, path)
	if reserve.is_empty() or freeze.is_empty() or chain.is_empty():
		return null
	if not _is_whole(reserve["price_step"], "reserve.price_step", path):
		return null
	if not _is_whole(chain["max_per_frame"], "chain.max_per_frame", path):
		return null
	var costs_read: Array[int] = _read_upgrade_costs(reserve, path)
	if costs_read.is_empty():
		return null
	var branches_read: Dictionary = _read_branches(data, path)
	if branches_read.is_empty():
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
	stats.price_step = int(reserve["price_step"])
	stats.upgrade_costs = costs_read
	stats.freeze_dwell = freeze["dwell"]
	stats.freeze_duration = freeze["duration"]
	stats.freeze_cooldown = freeze["cooldown"]
	stats.frozen_vulnerability = freeze["frozen_vulnerability"]
	stats.chain_max_per_frame = int(chain["max_per_frame"])
	stats.branches = branches_read
	return stats


## True if [param value] is a whole number; otherwise prints an error naming
## [param key] and returns false.
static func _is_whole(value: float, key: String, path: String) -> bool:
	if value == floorf(value):
		return true
	push_error("TowerStats: key '%s' in '%s' must be a whole number (got %s)." % [key, path, value])
	return false


## Returns [code]reserve.upgrade_costs[/code] as whole positive numbers, or an
## empty array after printing an error.
static func _read_upgrade_costs(reserve: Dictionary, path: String) -> Array[int]:
	var costs: Array[int] = []
	var raw: Variant = reserve.get("upgrade_costs")
	if not raw is Array or (raw as Array).size() != UPGRADE_COUNT:
		push_error("TowerStats: key 'reserve.upgrade_costs' in '%s' must be an array of %d prices (got %s)." % [path, UPGRADE_COUNT, raw])
		return costs
	for value: Variant in raw:
		if not (value is float or value is int) or value <= 0 or value != floorf(value):
			push_error("TowerStats: key 'reserve.upgrade_costs' in '%s' must hold positive whole numbers (got %s)." % [path, value])
			costs.clear()
			return costs
		costs.append(int(value))
	return costs


## Returns the validated [code]branches[/code] section keyed by [enum Kind], or
## an empty dictionary after printing an error. Every kind needs at least one
## branch; every branch needs a non-empty [code]label[/code] string, and all
## its other values must be positive numbers. The branches and keys of
## [constant BRANCH_KEYS] are required.
static func _read_branches(data: Dictionary, path: String) -> Dictionary:
	if not data.get("branches") is Dictionary:
		push_error("TowerStats: section 'branches' is missing in '%s'." % path)
		return {}
	var section: Dictionary = data["branches"]
	var result: Dictionary = {}
	for kind: Kind in KIND_KEYS:
		var kind_key: String = KIND_KEYS[kind]
		var raw: Variant = section.get(kind_key)
		if not raw is Dictionary or (raw as Dictionary).is_empty():
			push_error("TowerStats: key 'branches.%s' in '%s' must be a non-empty object." % [kind_key, path])
			return {}
		var kind_branches: Dictionary = {}
		for id: String in raw:
			var where: String = "branches.%s.%s" % [kind_key, id]
			var values: Variant = (raw as Dictionary)[id]
			if not values is Dictionary:
				push_error("TowerStats: key '%s' in '%s' must be an object." % [where, path])
				return {}
			var label: Variant = (values as Dictionary).get("label")
			if not label is String or (label as String).is_empty():
				push_error("TowerStats: key '%s.label' in '%s' must be a non-empty string." % [where, path])
				return {}
			for key: String in values:
				var value: Variant = values[key]
				if key != "label" and (not (value is float or value is int) or value <= 0):
					push_error("TowerStats: key '%s.%s' in '%s' must be a positive number (got %s)." % [where, key, path, value])
					return {}
			kind_branches[StringName(id)] = values
		var required: Dictionary = BRANCH_KEYS.get(kind_key, {})
		for id: String in required:
			for key: String in required[id]:
				if not (kind_branches.get(StringName(id), {}) as Dictionary).has(key):
					push_error("TowerStats: key 'branches.%s.%s.%s' is missing in '%s'." % [kind_key, id, key, path])
					return {}
		result[kind] = kind_branches
	return result


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
