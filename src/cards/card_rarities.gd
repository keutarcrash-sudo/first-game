## The five card rarities and the reroll price, loaded from
## assets/data/card_rarities.json (spec « Cartes et lisibilité » §5.2 and §5.3).
## Pure data and formulas, no scene tree.
class_name CardRarities
extends RefCounted

## Rarity ids the file must list, from the most common to the rarest.
const IDS: Array[StringName] = [&"common", &"uncommon", &"rare", &"epic", &"legendary"]

var _order: Array[StringName] = []
var _labels: Dictionary = {}  # { id: String }
var _colors: Dictionary = {}  # { id: Color }
var _weights: Dictionary = {}  # { id: float }
var _growths: Dictionary = {}  # { id: float }
var _reroll_base := 0
var _reroll_step := 0


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> CardRarities:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("CardRarities: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.get("rarities") is Array:
		push_error("CardRarities: '%s' must be a JSON object with a 'rarities' list." % path)
		return null
	var raw_list: Array = data["rarities"]
	if raw_list.size() != IDS.size():
		push_error("CardRarities: key 'rarities' in '%s' must list the %d rarities %s in this order." % [path, IDS.size(), str(IDS)])
		return null
	var result := CardRarities.new()
	for i: int in raw_list.size():
		var raw: Variant = raw_list[i]
		var where := "rarities[%d]" % i
		if not raw is Dictionary or raw.get("id") != String(IDS[i]):
			push_error("CardRarities: key '%s.id' in '%s' must be '%s'." % [where, path, IDS[i]])
			return null
		for key: String in ["label", "color"]:
			if not raw.get(key) is String or (raw[key] as String).strip_edges().is_empty():
				push_error("CardRarities: key '%s.%s' in '%s' must be a non-empty string." % [where, key, path])
				return null
		if not Color.html_is_valid(raw["color"]):
			push_error("CardRarities: key '%s.color' in '%s' must be an HTML colour such as '#b8b8c8' (got '%s')." % [where, path, raw["color"]])
			return null
		var weight: Variant = raw.get("weight")
		if not (weight is float or weight is int) or weight <= 0:
			push_error("CardRarities: key '%s.weight' in '%s' must be a number above 0 (got %s)." % [where, path, weight])
			return null
		var growth: Variant = raw.get("growth")
		if not (growth is float or growth is int) or growth < 0:
			push_error("CardRarities: key '%s.growth' in '%s' must be a number of at least 0 (got %s)." % [where, path, growth])
			return null
		var id: StringName = IDS[i]
		result._order.append(id)
		result._labels[id] = raw["label"]
		result._colors[id] = Color.html(raw["color"])
		result._weights[id] = float(weight)
		result._growths[id] = float(growth)
	var reroll: Variant = data.get("reroll")
	if not reroll is Dictionary:
		push_error("CardRarities: key 'reroll' in '%s' must be an object." % path)
		return null
	for key: String in ["base_cost", "step"]:
		var value: Variant = reroll.get(key)
		if not (value is float or value is int) or value < 0 or value != floorf(value):
			push_error("CardRarities: key 'reroll.%s' in '%s' must be a whole number of at least 0 (got %s)." % [key, path, value])
			return null
	result._reroll_base = int(reroll["base_cost"])
	result._reroll_step = int(reroll["step"])
	return result


## The rarity ids, from the most common to the rarest.
func order() -> Array[StringName]:
	return _order.duplicate()


## True when [param rarity] is one of the five rarities.
func has_rarity(rarity: StringName) -> bool:
	return _weights.has(rarity)


## Draw weight of [param rarity] on wave [param wave]:
## [code]weight × (1 + growth × (wave − 1))[/code]; 0 for an unknown rarity.
func weight(rarity: StringName, wave: int) -> float:
	if not _weights.has(rarity):
		return 0.0
	return float(_weights[rarity]) * (1.0 + float(_growths[rarity]) * float(maxi(wave, 1) - 1))


## Frame colour of [param rarity]; white for an unknown rarity.
func color(rarity: StringName) -> Color:
	return _colors.get(rarity, Color.WHITE)


## Upper-case French label of [param rarity] (« COMMUNE », « ÉPIQUE »…); empty for an unknown rarity.
func label(rarity: StringName) -> String:
	return _labels.get(rarity, "")


## Price in gold of the next reroll after [param rerolls_done] rerolls on the same choice screen.
func reroll_cost(rerolls_done: int) -> int:
	return _reroll_base + _reroll_step * maxi(rerolls_done, 0)
