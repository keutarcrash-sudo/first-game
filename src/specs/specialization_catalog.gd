## Every specialization of the game, loaded from assets/data/specializations.json
## (story 008). Pure logic, no scene tree. Adding a specialization with an
## existing weapon type is a data change only; a new weapon type is added to
## [constant WEAPON_NUMBER_KEYS] and built in [method Hero.equip].
class_name SpecializationCatalog
extends RefCounted

const TEXT_KEYS := ["id", "display_name", "description", "stats_line"]
## Weapon types known to the code, with the numeric keys each one needs (all above 0).
const WEAPON_NUMBER_KEYS := {
	"arrows": ["fire_rate", "damage", "range", "pierce", "crit_chance", "crit_multiplier", "mark_duration"],
	"fire_bolts": ["fire_rate", "damage", "range", "pierce", "burn_duration", "burn_damage_per_second"],
	"water_jets": ["fire_rate", "damage", "range", "pierce", "wet_duration"],
}

## All specializations, in file order (the order of the choice screen).
var specs: Array[SpecializationDef] = []


## Reads and validates the JSON file at [param path]. Combo ids must exist in
## [param rules]. Returns [code]null[/code] and prints an error naming the file
## and the faulty key if anything is wrong.
static func load_from_file(path: String, rules: ProcRules) -> SpecializationCatalog:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("SpecializationCatalog: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.get("specializations") is Array or (data["specializations"] as Array).is_empty():
		push_error("SpecializationCatalog: '%s' must be a JSON object with a non-empty 'specializations' list." % path)
		return null
	var catalog := SpecializationCatalog.new()
	var any_at_start := false
	for i: int in data["specializations"].size():
		var spec: SpecializationDef = _parse_spec(data["specializations"][i], "specializations[%d]" % i, path, rules)
		if spec == null:
			return null
		if catalog.has_spec(spec.id):
			push_error("SpecializationCatalog: key 'specializations[%d].id' in '%s' is a duplicate ('%s')." % [i, path, spec.id])
			return null
		any_at_start = any_at_start or spec.available_at_start
		catalog.specs.append(spec)
	if not any_at_start:
		push_error("SpecializationCatalog: in '%s', at least one specialization must have 'available_at_start': true." % path)
		return null
	return catalog


static func _parse_spec(raw: Variant, where: String, path: String, rules: ProcRules) -> SpecializationDef:
	if not raw is Dictionary:
		push_error("SpecializationCatalog: '%s' in '%s' must be an object." % [where, path])
		return null
	for key: String in TEXT_KEYS:
		if not raw.get(key) is String or (raw[key] as String).strip_edges().is_empty():
			push_error("SpecializationCatalog: key '%s.%s' in '%s' must be a non-empty string." % [where, key, path])
			return null
	if not raw.get("available_at_start") is bool:
		push_error("SpecializationCatalog: key '%s.available_at_start' in '%s' must be true or false." % [where, path])
		return null
	var weapon: Variant = raw.get("weapon")
	if not weapon is Dictionary or not WEAPON_NUMBER_KEYS.has(weapon.get("type")):
		push_error("SpecializationCatalog: key '%s.weapon.type' in '%s' must be a known weapon type (%s)." % [where, path, str(WEAPON_NUMBER_KEYS.keys())])
		return null
	for key: String in WEAPON_NUMBER_KEYS[weapon["type"]]:
		var value: Variant = weapon.get(key)
		if not (value is float or value is int) or value <= 0:
			push_error("SpecializationCatalog: key '%s.weapon.%s' in '%s' must be a number above 0 (got %s)." % [where, key, path, value])
			return null
	if not raw.get("combo_ids") is Array:
		push_error("SpecializationCatalog: key '%s.combo_ids' in '%s' must be a list of combo ids." % [where, path])
		return null
	var spec := SpecializationDef.new()
	var freeze: Variant = raw.get("freeze")
	if freeze != null:
		# Optional (story 009): the « trempé + glace = gelé » conversion the frost tower applies with this specialization.
		if not freeze is Dictionary:
			push_error("SpecializationCatalog: key '%s.freeze' in '%s' must be an object with 'duration' and 'cooldown'." % [where, path])
			return null
		for key: String in ["duration", "cooldown"]:
			var value: Variant = freeze.get(key)
			if not (value is float or value is int) or value <= 0:
				push_error("SpecializationCatalog: key '%s.freeze.%s' in '%s' must be a number above 0 (got %s)." % [where, key, path, value])
				return null
		spec.freeze_duration = float(freeze["duration"])
		spec.freeze_cooldown = float(freeze["cooldown"])
	for combo_id: Variant in raw["combo_ids"]:
		if not combo_id is String or not rules.has_combo(combo_id):
			push_error("SpecializationCatalog: key '%s.combo_ids' in '%s' must list ids of combos in procs.json (got %s)." % [where, path, combo_id])
			return null
		spec.combo_ids.append(combo_id)
	spec.id = raw["id"]
	spec.display_name = raw["display_name"]
	spec.description = raw["description"]
	spec.stats_line = raw["stats_line"]
	spec.available_at_start = raw["available_at_start"]
	spec.weapon_type = weapon["type"]
	spec.weapon = weapon
	return spec


## True when a specialization with id [param spec_id] exists.
func has_spec(spec_id: String) -> bool:
	for spec: SpecializationDef in specs:
		if spec.id == spec_id:
			return true
	return false


## The specializations the player may choose: those available at start plus
## those whose id is in [param unlocked_ids] (from the skill tree), in file order.
func unlocked(unlocked_ids: PackedStringArray) -> Array[SpecializationDef]:
	var found: Array[SpecializationDef] = []
	for spec: SpecializationDef in specs:
		if spec.available_at_start or unlocked_ids.has(spec.id):
			found.append(spec)
	return found
