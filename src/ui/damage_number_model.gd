## Pure logic of the floating damage numbers: settings loaded from damage_numbers.json,
## grouping of repeated damage (burn, area) per enemy, lifetime, cap and fade.
## No node and no drawing: the caller passes the time [code]now[/code] (seconds) in.
class_name DamageNumberModel
extends RefCounted

## Sources whose damage is summed per enemy and shown once per group interval.
## &"tower_dot" is the towers' continuous damage (flamethrower cone, towers T2a), shown in its own colour.
const GROUPED_SOURCES: Array[StringName] = [&"burn", &"area", &"tower_dot"]
const COLOR_KEYS: Array[String] = ["hero", "cannon", "burn", "tower_dot", "crit"]
## Sources drawn in their own colour; any other source uses the hero colour.
const OWN_COLOR_SOURCES: Array[StringName] = [&"cannon", &"burn", &"tower_dot"]

## When false, [method report] creates nothing.
var enabled: bool = true
var font_size: int = 22
var crit_font_size: int = 32
var lifetime: float = 0.7
var rise_px: float = 34.0
var group_interval: float = 0.5
var jitter_px: float = 12.0
var max_on_screen: int = 60

var _colors: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _now: float = 0.0
## Live numbers: { text, color, font_size, base, born }.
var _live: Array[Dictionary] = []
## enemy key (int) -> { source (StringName) -> { amount, first, position } }.
var _groups: Dictionary = {}


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> DamageNumberModel:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("DamageNumberModel: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	return from_data(JSON.parse_string(text), path)


## Validates already-parsed JSON [param data] ([param source] names the file in errors).
## Returns [code]null[/code] and prints an error on the first problem.
static func from_data(data: Variant, source: String) -> DamageNumberModel:
	if not data is Dictionary:
		push_error("DamageNumberModel: '%s' must be a JSON object." % source)
		return null
	var d: Dictionary = data
	var m := DamageNumberModel.new()
	if not d.get("enabled") is bool:
		push_error("DamageNumberModel: key 'enabled' in '%s' must be a boolean." % source)
		return null
	m.enabled = d["enabled"]
	if not d.get("colors") is Dictionary:
		push_error("DamageNumberModel: key 'colors' in '%s' must be an object." % source)
		return null
	for key: String in COLOR_KEYS:
		var value: Variant = (d["colors"] as Dictionary).get(key)
		if not _is_color(value):
			push_error("DamageNumberModel: key 'colors.%s' in '%s' must be a valid #rrggbb color." % [key, source])
			return null
		m._colors[StringName(key)] = Color(value as String)
	for key: String in ["font_size", "crit_font_size", "max_on_screen"]:
		if not _is_number(d.get(key)) or d[key] < 1 or d[key] != floorf(d[key]):
			push_error("DamageNumberModel: key '%s' in '%s' must be an integer >= 1." % [key, source])
			return null
	for key: String in ["lifetime", "group_interval"]:
		if not _is_number(d.get(key)) or d[key] <= 0:
			push_error("DamageNumberModel: key '%s' in '%s' must be a positive number." % [key, source])
			return null
	for key: String in ["rise_px", "jitter_px"]:
		if not _is_number(d.get(key)) or d[key] < 0:
			push_error("DamageNumberModel: key '%s' in '%s' must be a number >= 0." % [key, source])
			return null
	m.font_size = int(d["font_size"])
	m.crit_font_size = int(d["crit_font_size"])
	m.max_on_screen = int(d["max_on_screen"])
	m.lifetime = float(d["lifetime"])
	m.group_interval = float(d["group_interval"])
	m.rise_px = float(d["rise_px"])
	m.jitter_px = float(d["jitter_px"])
	return m


## Sets the random generator used for the position jitter (inject a seeded one in tests).
func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng


## Reports [param amount] damage dealt to enemy [param key] at [param position].
## Hero, cannon and critical hits show at once; burn, area and tower_dot damage is summed per
## enemy and source until [method advance] (or [method flush]) shows it.
func report(key: int, position: Vector2, amount: float, source: StringName, crit: bool, now: float) -> void:
	if not enabled:
		return
	_now = maxf(_now, now)
	if crit or not GROUPED_SOURCES.has(source):
		_spawn(position, amount, source, crit, now)
		return
	var per_enemy: Dictionary = _groups.get(key, {})
	var group: Dictionary = per_enemy.get(source, { "amount": 0.0, "first": now, "position": position })
	group["amount"] = float(group["amount"]) + amount
	group["position"] = position
	per_enemy[source] = group
	_groups[key] = per_enemy


## The enemy [param key] died at [param position]: shows its pending sums now
## (those of at least 0.5) so they are not lost.
func flush(key: int, position: Vector2, now: float) -> void:
	if not enabled:
		return
	_now = maxf(_now, now)
	var per_enemy: Dictionary = _groups.get(key, {})
	for source: StringName in per_enemy:
		var group: Dictionary = per_enemy[source]
		if float(group["amount"]) >= 0.5:
			_spawn(position, float(group["amount"]), source, false, now)
	_groups.erase(key)


## Moves the clock to [param now]: shows the sums whose interval is over (and that
## reached 1), then drops the numbers older than the lifetime.
func advance(now: float) -> void:
	_now = maxf(_now, now)
	var empty_keys: Array = []
	for key: int in _groups:
		var per_enemy: Dictionary = _groups[key]
		var done: Array[StringName] = []
		for source: StringName in per_enemy:
			var group: Dictionary = per_enemy[source]
			if _now - float(group["first"]) >= group_interval and float(group["amount"]) >= 1.0:
				_spawn(group["position"], float(group["amount"]), source, false, _now)
				done.append(source)
		for source: StringName in done:
			per_enemy.erase(source)
		if per_enemy.is_empty():
			empty_keys.append(key)
	for key: int in empty_keys:
		_groups.erase(key)
	var kept: Array[Dictionary] = []
	for n: Dictionary in _live:
		if _now - float(n["born"]) < lifetime:
			kept.append(n)
	_live = kept


## Forgets every number and every pending sum.
func clear() -> void:
	_live.clear()
	_groups.clear()


## Numbers to draw: { text, color, font_size, position, age }; the position already
## includes the rise ([member rise_px] * age / lifetime) and the jitter fixed at creation.
func numbers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n: Dictionary in _live:
		var age: float = maxf(_now - float(n["born"]), 0.0)
		out.append({
			"text": n["text"],
			"color": n["color"],
			"font_size": n["font_size"],
			"position": (n["base"] as Vector2) + Vector2(0.0, -rise_px * age / lifetime),
			"age": age,
		})
	return out


## Opacity at [param age] seconds: 1 for the first half of the lifetime, then a fade to 0.
func alpha(age: float) -> float:
	var half: float = lifetime * 0.5
	if age <= half:
		return 1.0
	return clampf(1.0 - (age - half) / half, 0.0, 1.0)


func _spawn(position: Vector2, amount: float, source: StringName, crit: bool, now: float) -> void:
	var shown: int = maxi(roundi(amount), 1)
	var color_key: StringName = &"crit" if crit else (source if OWN_COLOR_SOURCES.has(source) else &"hero")
	var jitter := Vector2(
		_rng.randf_range(-jitter_px, jitter_px),
		_rng.randf_range(-jitter_px, jitter_px) * 0.5)
	_live.append({
		"text": ("%d!" if crit else "%d") % shown,
		"color": _colors[color_key],
		"font_size": crit_font_size if crit else font_size,
		"base": position + jitter,
		"born": now,
	})
	while _live.size() > max_on_screen:
		_live.remove_at(0)


static func _is_number(value: Variant) -> bool:
	return value is float or value is int


static func _is_color(value: Variant) -> bool:
	return value is String and (value as String).begins_with("#") and (value as String).is_valid_html_color()
