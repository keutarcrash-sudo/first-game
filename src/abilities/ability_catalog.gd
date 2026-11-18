## Every ability of the game, loaded from assets/data/abilities.json (étape 3a).
## Pure logic, no scene tree. A new ability type is added to
## [constant TYPE_NUMBER_KEYS] and implemented where abilities are cast.
class_name AbilityCatalog
extends RefCounted

## Ability types known to the code, with the numeric keys each one needs (all above 0).
const TYPE_NUMBER_KEYS := {
	"piercing_arrow": ["damage", "speed", "range", "radius"],
	"fireball": ["damage", "explosion_radius", "speed", "range", "radius"],
	"water_wave": ["damage", "angle_degrees", "range", "push_distance", "push_duration"],
	"dash_crit": ["distance", "duration"],
	"dash_fire_trail": ["distance", "duration", "trail_width", "trail_duration"],
	"dash_wet": ["distance", "duration", "wet_radius"],
	"arrow_rain": ["radius", "max_range", "duration", "tick_interval", "damage"],
	"fire_wall": ["length", "thickness", "max_range", "duration"],
	"puddle": ["radius", "max_range", "duration", "slow_factor"],
	"hunter_eye": ["duration"],
	"meteor": ["radius", "max_range", "delay", "damage"],
	"tidal_wave": ["freeze_duration"],
}
## The input slots an ability may use.
const SLOTS: Array[StringName] = [&"primary", &"a", &"e", &"r"]
const TEXT_KEYS := ["id", "spec_id", "slot", "display_name", "description", "type"]
## The slots unlocked during a game, in unlock order (matches [member unlock_after_waves]).
const UNLOCK_SLOTS: Array[StringName] = [&"a", &"e", &"r"]

## All abilities, in file order.
var abilities: Array[AbilityDef] = []
## Waves to complete before the A, E and R abilities are offered (3 strictly increasing integers above 0).
var unlock_after_waves: PackedInt32Array = PackedInt32Array()


## Reads and validates the JSON file at [param path]. Each [code]spec_id[/code]
## must exist in [param specs]. Returns [code]null[/code] and prints an error
## naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String, specs: SpecializationCatalog) -> AbilityCatalog:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("AbilityCatalog: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.get("abilities") is Array or (data["abilities"] as Array).is_empty():
		push_error("AbilityCatalog: '%s' must be a JSON object with a non-empty 'abilities' list." % path)
		return null
	var raw_waves: Variant = data.get("unlock_after_waves")
	if not raw_waves is Array or (raw_waves as Array).size() != UNLOCK_SLOTS.size():
		push_error("AbilityCatalog: key 'unlock_after_waves' in '%s' must be a list of %d integers." % [path, UNLOCK_SLOTS.size()])
		return null
	var catalog := AbilityCatalog.new()
	var previous := 0
	for wave: Variant in raw_waves:
		if not (wave is int or (wave is float and wave == floorf(wave))) or int(wave) <= previous:
			push_error("AbilityCatalog: key 'unlock_after_waves' in '%s' must hold strictly increasing integers above 0 (got %s)." % [path, str(raw_waves)])
			return null
		previous = int(wave)
		catalog.unlock_after_waves.append(previous)
	for i: int in data["abilities"].size():
		var ability: AbilityDef = _parse_ability(data["abilities"][i], "abilities[%d]" % i, path, specs)
		if ability == null:
			return null
		if catalog.for_spec(ability.spec_id).has(ability.slot):
			push_error("AbilityCatalog: key '%s' in '%s' duplicates slot '%s' of specialization '%s'." % ["abilities[%d]" % i, path, ability.slot, ability.spec_id])
			return null
		catalog.abilities.append(ability)
	return catalog


static func _parse_ability(raw: Variant, where: String, path: String, specs: SpecializationCatalog) -> AbilityDef:
	if not raw is Dictionary:
		push_error("AbilityCatalog: '%s' in '%s' must be an object." % [where, path])
		return null
	for key: String in TEXT_KEYS:
		if not raw.get(key) is String or (raw[key] as String).strip_edges().is_empty():
			push_error("AbilityCatalog: key '%s.%s' in '%s' must be a non-empty string." % [where, key, path])
			return null
	if not specs.has_spec(raw["spec_id"]):
		push_error("AbilityCatalog: key '%s.spec_id' in '%s' must be the id of a specialization in specializations.json (got '%s')." % [where, path, raw["spec_id"]])
		return null
	if not SLOTS.has(StringName(raw["slot"])):
		push_error("AbilityCatalog: key '%s.slot' in '%s' must be one of %s (got '%s')." % [where, path, str(SLOTS), raw["slot"]])
		return null
	var cooldown: Variant = raw.get("cooldown")
	if not (cooldown is float or cooldown is int) or cooldown <= 0:
		push_error("AbilityCatalog: key '%s.cooldown' in '%s' must be a number above 0 (got %s)." % [where, path, cooldown])
		return null
	if not TYPE_NUMBER_KEYS.has(raw["type"]):
		push_error("AbilityCatalog: key '%s.type' in '%s' must be a known ability type (%s)." % [where, path, str(TYPE_NUMBER_KEYS.keys())])
		return null
	var values: Variant = raw.get("values")
	if not values is Dictionary:
		push_error("AbilityCatalog: key '%s.values' in '%s' must be an object." % [where, path])
		return null
	for key: String in TYPE_NUMBER_KEYS[raw["type"]]:
		var value: Variant = values.get(key)
		if not (value is float or value is int) or value <= 0:
			push_error("AbilityCatalog: key '%s.values.%s' in '%s' must be a number above 0 (got %s)." % [where, key, path, value])
			return null
	var ability := AbilityDef.new()
	ability.id = raw["id"]
	ability.spec_id = raw["spec_id"]
	ability.slot = StringName(raw["slot"])
	ability.display_name = raw["display_name"]
	ability.description = raw["description"]
	ability.cooldown = float(cooldown)
	ability.type = raw["type"]
	ability.values = values
	return ability


## The abilities of specialization [param spec_id], as [code]{ slot: AbilityDef }[/code].
func for_spec(spec_id: String) -> Dictionary:
	var found: Dictionary = {}
	for ability: AbilityDef in abilities:
		if ability.spec_id == spec_id:
			found[ability.slot] = ability
	return found
