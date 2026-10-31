## Combo rules (story 005, design/game-brief.md MVP feature 6): data-driven
## "if the target has state X, damage from source Y is multiplied" rules.
## Pure logic: it never touches the scene tree, the caller passes the target's
## states in. Rules come from a JSON file (see [method load_from_file]); adding a
## combo is a data change only. Nothing here knows about any specific state or source.
class_name ProcRules
extends RefCounted

const COMBO_KEYS := ["id", "display_name", "source", "requires_state", "damage_multiplier"]

## Outcome of [method resolve].
class Result extends RefCounted:
	## Total damage multiplier, exactly 1.0 when no combo triggered.
	var multiplier := 1.0
	## Ids of the combos that triggered.
	var combo_ids: Array[String] = []

var _combos: Array[Dictionary] = []
var _inactive: Dictionary = {}  # Ids of combos not unlocked yet.


## Finds the combos that apply to damage coming from [param source] on a target
## whose states are answered by [param has_state] (a [Callable] taking a
## [StringName] and returning a bool).
## Stacking rule: bonuses ADD, they do not multiply. The total multiplier is
## 1 + sum(multiplier_i - 1) over the triggered combos, so x3 and x2 together
## give x4, not x6. No triggered combo gives exactly 1.0.
func resolve(source: StringName, has_state: Callable) -> Result:
	var result := Result.new()
	var bonus := 0.0
	for combo: Dictionary in _combos:
		if _inactive.has(combo["id"]):
			continue
		if StringName(combo["source"]) != source:
			continue
		if not has_state.call(StringName(combo["requires_state"])):
			continue
		bonus += float(combo["damage_multiplier"]) - 1.0
		result.combo_ids.append(combo["id"])
	if not result.combo_ids.is_empty():
		result.multiplier = 1.0 + bonus
	return result


## Switches on the combo [param combo_id] if it was loaded with
## [code]"active_at_start": false[/code]. Does nothing for an active or unknown id.
func activate(combo_id: String) -> void:
	_inactive.erase(combo_id)


## True if a combo with [param combo_id] exists in the loaded file, active or not.
func has_combo(combo_id: String) -> bool:
	for combo: Dictionary in _combos:
		if combo["id"] == combo_id:
			return true
	return false


## Reads and validates the JSON file at [param path] (an object with a "combos"
## list). Returns [code]null[/code] and prints an error naming the file and the
## faulty key if anything is wrong.
static func load_from_file(path: String) -> ProcRules:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("ProcRules: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.get("combos") is Array:
		push_error("ProcRules: '%s' must be a JSON object with a 'combos' list." % path)
		return null
	var rules := ProcRules.new()
	var seen: Dictionary = {}
	for i: int in data["combos"].size():
		var combo: Variant = data["combos"][i]
		if not combo is Dictionary:
			push_error("ProcRules: 'combos[%d]' in '%s' must be an object." % [i, path])
			return null
		for key: String in COMBO_KEYS:
			if not combo.has(key):
				push_error("ProcRules: key 'combos[%d].%s' is missing in '%s'." % [i, key, path])
				return null
			var value: Variant = combo[key]
			if key == "damage_multiplier":
				if not (value is float or value is int) or value <= 0:
					push_error("ProcRules: key 'combos[%d].damage_multiplier' in '%s' must be a number above 0 (got %s)." % [i, path, value])
					return null
			elif not value is String or (value as String).strip_edges().is_empty():
				push_error("ProcRules: key 'combos[%d].%s' in '%s' must be a non-empty string (got %s)." % [i, key, path, value])
				return null
		if seen.has(combo["id"]):
			push_error("ProcRules: key 'combos[%d].id' in '%s' is a duplicate ('%s')." % [i, path, combo["id"]])
			return null
		seen[combo["id"]] = true
		# Optional key, true when absent: false means a card must unlock the combo.
		if combo.has("active_at_start"):
			if not combo["active_at_start"] is bool:
				push_error("ProcRules: key 'combos[%d].active_at_start' in '%s' must be true or false (got %s)." % [i, path, combo["active_at_start"]])
				return null
			if not combo["active_at_start"]:
				rules._inactive[combo["id"]] = true
		rules._combos.append(combo)
	return rules
