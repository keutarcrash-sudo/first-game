## Tuning values of the towers (story 004, towers T1, towers T2a). Loaded once from a
## JSON file: the shared blocks [code]designation[/code], [code]reserve[/code] (prices),
## [code]freeze[/code] (freeze rules) and [code]chain[/code] (chain-reaction cap), the
## [code]towers[/code] section (tower id -> [TowerDef]: label, behaviour, base_cost,
## range, radius, sheet, height_px, optional colours, the behaviour values and the
## branches) and [code]starting_unlocked[/code] (tower ids buildable from the start).
## Every required value must be a positive number; any error returns [code]null[/code]
## and names the file and the key.
## Units: cost in gold, range / radius / distances in pixels, speed in pixels per
## second, intervals in seconds, slow_factor a fraction of the normal enemy speed.
class_name TowerStats
extends RefCounted

const DESIGNATION_KEYS := ["click_margin"]
const RESERVE_KEYS := ["price_step"]
const FREEZE_KEYS := ["dwell", "duration", "cooldown", "frozen_vulnerability"]
const CHAIN_KEYS := ["max_per_frame"]
## Keys every tower carries, whatever its behaviour.
const TOWER_NUMBER_KEYS := ["base_cost", "range", "radius", "height_px"]
## Tower keys that are not values of the behaviour.
const TOWER_META_KEYS := ["label", "behaviour", "base_cost", "range", "radius", "sheet", "height_px", "color", "icon_color", "branches"]
## Known behaviours: behaviour -> the values its towers must carry.
const BEHAVIOUR_KEYS := {
	"shooter": ["damage", "fire_interval", "bullet_speed", "bullet_radius", "bullet_max_range"],
	"frost_aura": ["slow_factor"],
}
## Branches and keys a behaviour's code reads: behaviour -> branch id -> keys
## ([code]label[/code] is a string, the others positive numbers).
const BRANCH_KEYS := {
	"shooter": {
		"incendiaire": ["label", "burn_duration", "burn_dps", "card_duration_mult", "l3_explosion_radius", "l3_explosion_damage"],
		"perforant": ["label", "pierce_total", "l3_shots", "l3_spread_degrees"],
	},
	"frost_aura": {
		"blizzard": ["label", "range_mult", "dwell", "l3_wet_duration"],
		"eclats": ["label", "shard_radius", "shard_damage", "l3_shard_freeze"],
	},
}
## Number of upgrade costs: level 1 -> 2, then level 2 -> 3.
const UPGRADE_COUNT := 2

## Tower ids buildable from the start of a run, in file order.
var starting_unlocked: Array[StringName] = []
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

var _defs: Array[TowerDef] = []
var _by_id: Dictionary = {}  # StringName -> TowerDef.


## Every tower type, in file order.
func defs() -> Array[TowerDef]:
	return _defs.duplicate()


## The tower type [param id], or [code]null[/code] if unknown.
func def_of(id: StringName) -> TowerDef:
	return _by_id.get(id) as TowerDef


## Base price in gold of a tower of [param kind] (0 if unknown).
func cost_of(kind: StringName) -> int:
	var def: TowerDef = def_of(kind)
	return 0 if def == null else def.base_cost


## Body radius in pixels of a tower of [param kind] (0 if unknown).
func radius_of(kind: StringName) -> float:
	var def: TowerDef = def_of(kind)
	return 0.0 if def == null else def.radius


## Branch ids of a tower of [param kind], in file order.
func branch_ids(kind: StringName) -> Array[StringName]:
	var def: TowerDef = def_of(kind)
	if def == null:
		var none: Array[StringName] = []
		return none
	return def.branch_ids()


## Value [param key] of branch [param branch] of a tower of [param kind], or
## [code]null[/code] if the tower, the branch or the key does not exist.
func branch_value(kind: StringName, branch: StringName, key: String) -> Variant:
	var def: TowerDef = def_of(kind)
	return null if def == null else def.branch_value(branch, key)


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
	var designation: Dictionary = _read_section(data, "designation", DESIGNATION_KEYS, path)
	if designation.is_empty():
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
	var defs_read: Array[TowerDef] = _read_towers(data, path)
	if defs_read.is_empty():
		return null
	var stats := TowerStats.new()
	for def: TowerDef in defs_read:
		stats._defs.append(def)
		stats._by_id[def.id] = def
	var unlocked: Variant = data.get("starting_unlocked")
	if not unlocked is Array or (unlocked as Array).is_empty():
		push_error("TowerStats: key 'starting_unlocked' in '%s' must be a non-empty array of tower ids." % path)
		return null
	for tower_id: Variant in unlocked:
		if not tower_id is String or not stats._by_id.has(StringName(tower_id as String)):
			push_error("TowerStats: key 'starting_unlocked' in '%s' names an unknown tower (%s)." % [path, tower_id])
			return null
		stats.starting_unlocked.append(StringName(tower_id as String))
	stats.designation_click_margin = designation["click_margin"]
	stats.price_step = int(reserve["price_step"])
	stats.upgrade_costs = costs_read
	stats.freeze_dwell = freeze["dwell"]
	stats.freeze_duration = freeze["duration"]
	stats.freeze_cooldown = freeze["cooldown"]
	stats.frozen_vulnerability = freeze["frozen_vulnerability"]
	stats.chain_max_per_frame = int(chain["max_per_frame"])
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


## Returns the validated [code]towers[/code] section as [TowerDef]s in file order,
## or an empty array after printing an error.
static func _read_towers(data: Dictionary, path: String) -> Array[TowerDef]:
	var result: Array[TowerDef] = []
	if not data.get("towers") is Dictionary or (data["towers"] as Dictionary).is_empty():
		push_error("TowerStats: section 'towers' is missing or empty in '%s'." % path)
		return result
	var section: Dictionary = data["towers"]
	var seen_branches: Dictionary = {}  # Branch id -> "towers.<id>" that declared it first.
	for tower_id: String in section:
		var def: TowerDef = _read_tower(tower_id, section[tower_id], path, seen_branches)
		if def == null:
			result.clear()
			return result
		result.append(def)
	return result


## Validates tower [param tower_id]; returns [code]null[/code] after printing an error.
## [param seen_branches] collects the branch ids of the towers read so far (see [method _read_branches]).
static func _read_tower(tower_id: String, raw: Variant, path: String, seen_branches: Dictionary) -> TowerDef:
	var where: String = "towers.%s" % tower_id
	if not raw is Dictionary:
		push_error("TowerStats: key '%s' in '%s' must be an object." % [where, path])
		return null
	var tower: Dictionary = raw
	for key: String in ["label", "behaviour", "sheet"]:
		if not tower.get(key) is String or (tower[key] as String).is_empty():
			push_error("TowerStats: key '%s.%s' in '%s' must be a non-empty string." % [where, key, path])
			return null
	var behaviour: String = tower["behaviour"]
	if not BEHAVIOUR_KEYS.has(behaviour):
		push_error("TowerStats: key '%s.behaviour' in '%s' names an unknown behaviour '%s'." % [where, path, behaviour])
		return null
	var def := TowerDef.new()
	def.id = StringName(tower_id)
	def.label = tower["label"]
	def.behaviour = StringName(behaviour)
	def.sheet_path = tower["sheet"]
	for key: String in tower:
		if TOWER_META_KEYS.has(key):
			continue
		var value: Variant = tower[key]
		if not (value is float or value is int) or value <= 0:
			push_error("TowerStats: key '%s.%s' in '%s' must be a positive number (got %s)." % [where, key, path, value])
			return null
		def.values[key] = value
	for key: String in TOWER_NUMBER_KEYS + (BEHAVIOUR_KEYS[behaviour] as Array):
		var value: Variant = tower.get(key)
		if value == null:
			push_error("TowerStats: key '%s.%s' is missing in '%s'." % [where, key, path])
			return null
		if not (value is float or value is int) or value <= 0:
			push_error("TowerStats: key '%s.%s' in '%s' must be a positive number (got %s)." % [where, key, path, value])
			return null
	if not _is_whole(tower["base_cost"], where + ".base_cost", path):
		return null
	if def.values.has("slow_factor") and float(def.values["slow_factor"]) > 1.0:
		push_error("TowerStats: key '%s.slow_factor' in '%s' must be at most 1 (got %s)." % [where, path, def.values["slow_factor"]])
		return null
	def.base_cost = int(tower["base_cost"])
	def.range = tower["range"]
	def.radius = tower["radius"]
	def.height_px = tower["height_px"]
	if tower.has("color"):
		if not _is_color(tower["color"]):
			push_error("TowerStats: key '%s.color' in '%s' must be an array of 3 numbers in [0, 1]." % [where, path])
			return null
		def.color = _to_color(tower["color"])
	def.icon_color = def.color
	if tower.has("icon_color"):
		if not _is_color(tower["icon_color"]):
			push_error("TowerStats: key '%s.icon_color' in '%s' must be an array of 3 numbers in [0, 1]." % [where, path])
			return null
		def.icon_color = _to_color(tower["icon_color"])
	def.branches = _read_branches(tower.get("branches"), where, behaviour, path, seen_branches)
	if def.branches.is_empty():
		return null
	return def


## Returns the validated branches of a tower ([param where] names it) keyed by StringName,
## or an empty dictionary after printing an error. A tower needs at least one branch;
## every branch needs a non-empty [code]label[/code] string, and all its other values
## must be positive numbers. The branches and keys of [constant BRANCH_KEYS] for
## [param behaviour] are required. A branch id must be unique across all towers:
## [param seen_branches] (branch id -> tower key) holds those of the towers already read.
static func _read_branches(raw: Variant, where: String, behaviour: String, path: String, seen_branches: Dictionary) -> Dictionary:
	if not raw is Dictionary or (raw as Dictionary).is_empty():
		push_error("TowerStats: key '%s.branches' in '%s' must be a non-empty object." % [where, path])
		return {}
	var tower_branches: Dictionary = {}
	for id: String in raw:
		var branch_where: String = "%s.branches.%s" % [where, id]
		if seen_branches.has(id):
			push_error("TowerStats: key '%s' in '%s' reuses the branch id of '%s.branches.%s'; branch ids must be unique across all towers." % [branch_where, path, seen_branches[id], id])
			return {}
		seen_branches[id] = where
		var values: Variant = (raw as Dictionary)[id]
		if not values is Dictionary:
			push_error("TowerStats: key '%s' in '%s' must be an object." % [branch_where, path])
			return {}
		var label: Variant = (values as Dictionary).get("label")
		if not label is String or (label as String).is_empty():
			push_error("TowerStats: key '%s.label' in '%s' must be a non-empty string." % [branch_where, path])
			return {}
		for key: String in values:
			var value: Variant = values[key]
			if key != "label" and (not (value is float or value is int) or value <= 0):
				push_error("TowerStats: key '%s.%s' in '%s' must be a positive number (got %s)." % [branch_where, key, path, value])
				return {}
		tower_branches[StringName(id)] = values
	var required: Dictionary = BRANCH_KEYS.get(behaviour, {})
	for id: String in required:
		for key: String in required[id]:
			if not (tower_branches.get(StringName(id), {}) as Dictionary).has(key):
				push_error("TowerStats: key '%s.branches.%s.%s' is missing in '%s'." % [where, id, key, path])
				return {}
	return tower_branches


## True if [param value] is an array of 3 numbers between 0 and 1 (red, green, blue).
static func _is_color(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != 3:
		return false
	for channel: Variant in value:
		if not (channel is float or channel is int) or channel < 0 or channel > 1:
			return false
	return true


static func _to_color(value: Array) -> Color:
	return Color(float(value[0]), float(value[1]), float(value[2]))


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
	return values
