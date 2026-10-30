## Gold values (story 003, design/game-brief.md MVP feature 3). Loaded once
## from a JSON file. [code]starting_gold[/code] may be zero; the other keys
## must be positive numbers.
class_name EconomyStats
extends RefCounted

## Gold the player owns at the start of the game.
var starting_gold: int
## Gold given for each enemy killed by hero fire.
var gold_per_kill: int
## Gold given when a wave is finished.
var gold_per_wave_bonus: int


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> EconomyStats:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("EconomyStats: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("EconomyStats: '%s' is not a valid JSON object." % path)
		return null
	for key: String in ["starting_gold", "gold_per_kill", "gold_per_wave_bonus"]:
		var value: Variant = data.get(key)
		var is_valid: bool = value is float or value is int
		if is_valid:
			is_valid = value >= 0 if key == "starting_gold" else value > 0
		if not is_valid:
			var rule: String = "non-negative" if key == "starting_gold" else "positive"
			push_error("EconomyStats: key '%s' in '%s' must be a %s number (got %s)." % [key, path, rule, value])
			return null
	var stats := EconomyStats.new()
	stats.starting_gold = roundi(data["starting_gold"])
	stats.gold_per_kill = roundi(data["gold_per_kill"])
	stats.gold_per_wave_bonus = roundi(data["gold_per_wave_bonus"])
	return stats
