## Gold values (story 003, design/game-brief.md MVP feature 3; étape 2: gold lies
## on the ground). Loaded once from a JSON file. [code]starting_gold[/code] may
## be zero; the other keys must be positive numbers, and [code]gold_blink_time[/code]
## must be shorter than [code]gold_lifetime[/code].
class_name EconomyStats
extends RefCounted

## Gold the player owns at the start of the game.
var starting_gold: int
## Gold dropped on the ground by each enemy killed.
var gold_per_kill: int
## Seconds a gold coin stays on the ground before it disappears.
var gold_lifetime: float
## Seconds before disappearing during which a coin blinks.
var gold_blink_time: float
## Distance (pixels) from the hero at which a coin is picked up.
var pickup_radius: float


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
	for key: String in ["starting_gold", "gold_per_kill", "gold_lifetime", "gold_blink_time", "pickup_radius"]:
		var value: Variant = data.get(key)
		var is_valid: bool = value is float or value is int
		if is_valid:
			is_valid = value >= 0 if key == "starting_gold" else value > 0
		if not is_valid:
			var rule: String = "non-negative" if key == "starting_gold" else "positive"
			push_error("EconomyStats: key '%s' in '%s' must be a %s number (got %s)." % [key, path, rule, value])
			return null
	if float(data["gold_blink_time"]) >= float(data["gold_lifetime"]):
		push_error("EconomyStats: key 'gold_blink_time' in '%s' must be less than 'gold_lifetime' (got %s and %s)." % [path, data["gold_blink_time"], data["gold_lifetime"]])
		return null
	var stats := EconomyStats.new()
	stats.starting_gold = roundi(data["starting_gold"])
	stats.gold_per_kill = roundi(data["gold_per_kill"])
	stats.gold_lifetime = float(data["gold_lifetime"])
	stats.gold_blink_time = float(data["gold_blink_time"])
	stats.pickup_radius = float(data["pickup_radius"])
	return stats
