## Look and feel settings of the ability bar, loaded from ability_bar.json, plus the
## pure formulas (band height, breathing, pop, cooldown fraction) the bar draws with.
class_name AbilityBarStyle
extends RefCounted

const ROLES: Array[StringName] = [&"primary", &"a", &"e", &"r"]
## Positive numbers read as floats, in file key order.
const POSITIVE_KEYS: Array[String] = [
	"disc_diameter", "spacing", "outline_px", "name_font_size", "key_font_size", "cooldown_font_size",
]

## Role (StringName) -> Color of an unlocked disc.
var role_colors: Dictionary = {}
var locked_color: Color = Color.WHITE
## Role (StringName) -> key label text.
var key_labels: Dictionary = {}
var disc_diameter: float = 0.0
var spacing: float = 0.0
var outline_px: float = 0.0
var shadow_offset: Vector2 = Vector2.ZERO
var glow_alpha: float = 0.0
var name_font_size: int = 0
var key_font_size: int = 0
var cooldown_font_size: int = 0
var name_gap: float = 0.0
var bottom_margin: float = 0.0
var band_margin: float = 0.0
var breath_period: float = 1.0
var breath_amount: float = 0.0
var pop_duration: float = 1.0
var pop_scale_max: float = 1.0


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> AbilityBarStyle:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("AbilityBarStyle: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	return from_data(JSON.parse_string(text), path)


## Validates already-parsed JSON [param data] ([param source] names the file in errors).
## Returns [code]null[/code] and prints an error on the first problem.
static func from_data(data: Variant, source: String) -> AbilityBarStyle:
	if not data is Dictionary:
		push_error("AbilityBarStyle: '%s' must be a JSON object." % source)
		return null
	var d: Dictionary = data
	var r := AbilityBarStyle.new()
	for key: String in ["role_colors", "key_labels"]:
		if not d.get(key) is Dictionary:
			push_error("AbilityBarStyle: key '%s' in '%s' must be an object." % [key, source])
			return null
		for role: StringName in ROLES:
			var value: Variant = (d[key] as Dictionary).get(String(role))
			if key == "role_colors":
				if not _is_color(value):
					push_error("AbilityBarStyle: key 'role_colors.%s' in '%s' must be a valid #rrggbb color." % [role, source])
					return null
				r.role_colors[role] = Color(value as String)
			else:
				if not value is String or (value as String).is_empty():
					push_error("AbilityBarStyle: key 'key_labels.%s' in '%s' must be a non-empty string." % [role, source])
					return null
				r.key_labels[role] = value
	if not _is_color(d.get("locked_color")):
		push_error("AbilityBarStyle: key 'locked_color' in '%s' must be a valid #rrggbb color." % source)
		return null
	r.locked_color = Color(d["locked_color"] as String)
	for key: String in POSITIVE_KEYS:
		if not _is_number(d.get(key)) or d[key] <= 0:
			push_error("AbilityBarStyle: key '%s' in '%s' must be a positive number." % [key, source])
			return null
	r.disc_diameter = float(d["disc_diameter"])
	r.spacing = float(d["spacing"])
	r.outline_px = float(d["outline_px"])
	r.name_font_size = int(d["name_font_size"])
	r.key_font_size = int(d["key_font_size"])
	r.cooldown_font_size = int(d["cooldown_font_size"])
	for key: String in ["name_gap", "bottom_margin", "band_margin"]:
		if not _is_number(d.get(key)) or d[key] < 0:
			push_error("AbilityBarStyle: key '%s' in '%s' must be a number >= 0." % [key, source])
			return null
	r.name_gap = float(d["name_gap"])
	r.bottom_margin = float(d["bottom_margin"])
	r.band_margin = float(d["band_margin"])
	var offset: Variant = d.get("shadow_offset")
	if not offset is Array or (offset as Array).size() != 2 or not _is_number(offset[0]) or not _is_number(offset[1]):
		push_error("AbilityBarStyle: key 'shadow_offset' in '%s' must be [x, y] numbers." % source)
		return null
	r.shadow_offset = Vector2(float(offset[0]), float(offset[1]))
	if not _is_number(d.get("glow_alpha")) or d["glow_alpha"] < 0 or d["glow_alpha"] > 1:
		push_error("AbilityBarStyle: key 'glow_alpha' in '%s' must be a number in [0, 1]." % source)
		return null
	r.glow_alpha = float(d["glow_alpha"])
	if not d.get("breath") is Dictionary:
		push_error("AbilityBarStyle: key 'breath' in '%s' must be an object." % source)
		return null
	var breath: Dictionary = d["breath"]
	if not _is_number(breath.get("period")) or breath["period"] <= 0:
		push_error("AbilityBarStyle: key 'breath.period' in '%s' must be a positive number." % source)
		return null
	if not _is_number(breath.get("amount")) or breath["amount"] < 0:
		push_error("AbilityBarStyle: key 'breath.amount' in '%s' must be a number >= 0." % source)
		return null
	r.breath_period = float(breath["period"])
	r.breath_amount = float(breath["amount"])
	if not d.get("pop") is Dictionary:
		push_error("AbilityBarStyle: key 'pop' in '%s' must be an object." % source)
		return null
	var pop: Dictionary = d["pop"]
	if not _is_number(pop.get("duration")) or pop["duration"] <= 0:
		push_error("AbilityBarStyle: key 'pop.duration' in '%s' must be a positive number." % source)
		return null
	if not _is_number(pop.get("scale")) or pop["scale"] < 1:
		push_error("AbilityBarStyle: key 'pop.scale' in '%s' must be a number >= 1." % source)
		return null
	r.pop_duration = float(pop["duration"])
	r.pop_scale_max = float(pop["scale"])
	return r


## Color of the unlocked disc of [param slot]; the locked color (and an error) if unknown.
func color_of(slot: StringName) -> Color:
	if not role_colors.has(slot):
		push_error("AbilityBarStyle: unknown slot '%s'." % slot)
		return locked_color
	return role_colors[slot]


## Height of the bottom band the bar occupies: margin + disc + name gap + name line + band margin.
func bottom_band_height() -> float:
	return bottom_margin + disc_diameter + name_gap + name_font_size * 1.2 + band_margin


## Idle breathing scale at [param time] seconds: 1 to 1 + amount, one cycle per period.
func breath_scale(time: float) -> float:
	return 1.0 + breath_amount * (0.5 - 0.5 * cos(TAU * time / breath_period))


## Pop scale [param since_ready] seconds after a cooldown ends: eases out from the
## pop scale to 1, and is 1 once the duration is over or before it starts.
func pop_scale(since_ready: float) -> float:
	if since_ready < 0.0 or since_ready >= pop_duration:
		return 1.0
	var left: float = 1.0 - since_ready / pop_duration
	return 1.0 + (pop_scale_max - 1.0) * left * left


## White flash alpha of the pop: 1 at the start, 0 at the end of the duration (and outside it).
func pop_flash(since_ready: float) -> float:
	if since_ready < 0.0 or since_ready >= pop_duration:
		return 0.0
	return 1.0 - since_ready / pop_duration


## Dark share of the cooldown clock: left / total clamped to [0, 1]; 0 if total <= 0.
static func cooldown_fraction(left: float, total: float) -> float:
	if total <= 0.0:
		return 0.0
	return clampf(left / total, 0.0, 1.0)


static func _is_number(value: Variant) -> bool:
	return value is float or value is int


static func _is_color(value: Variant) -> bool:
	return value is String and (value as String).begins_with("#") and (value as String).is_valid_html_color()
