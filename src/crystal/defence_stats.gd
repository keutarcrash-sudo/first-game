## Tuning values for the crystal and the enemies (story 002,
## design/game-brief.md MVP feature 2). Loaded once from a JSON file;
## every value is required and must be a positive number.
class_name DefenceStats
extends RefCounted

const REQUIRED_KEYS := [
	"crystal_max_hp", "crystal_radius",
	"enemy_base_hp", "enemy_speed", "enemy_contact_damage", "enemy_radius",
	"spawn_margin", "hero_start_gap",
]

## Crystal hit points at the start of the game.
var crystal_max_hp: float
## Crystal radius, in pixels (drawing and contact distance).
var crystal_radius: float
## Enemy hit points before the wave multiplier.
var enemy_base_hp: float
## Enemy walking speed, in pixels per second.
var enemy_speed: float
## Damage an enemy deals to the crystal when it touches it.
var enemy_contact_damage: float
## Enemy radius, in pixels (collision, drawing, contact distance). Keep it
## above bullet_speed / 60 / 2 so a bullet cannot tunnel through an enemy.
var enemy_radius: float
## Distance in pixels between the arena edge and the enemy spawn line.
var spawn_margin: float
## Free space in pixels between the crystal and the hero's starting position.
var hero_start_gap: float


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> DefenceStats:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("DefenceStats: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("DefenceStats: '%s' is not a valid JSON object." % path)
		return null
	for key: String in REQUIRED_KEYS:
		if not data.has(key):
			push_error("DefenceStats: key '%s' is missing in '%s'." % [key, path])
			return null
		var value: Variant = data[key]
		if not (value is float or value is int) or value <= 0:
			push_error("DefenceStats: key '%s' in '%s' must be a positive number (got %s)." % [key, path, value])
			return null
	var stats := DefenceStats.new()
	stats.crystal_max_hp = data["crystal_max_hp"]
	stats.crystal_radius = data["crystal_radius"]
	stats.enemy_base_hp = data["enemy_base_hp"]
	stats.enemy_speed = data["enemy_speed"]
	stats.enemy_contact_damage = data["enemy_contact_damage"]
	stats.enemy_radius = data["enemy_radius"]
	stats.spawn_margin = data["spawn_margin"]
	stats.hero_start_gap = data["hero_start_gap"]
	return stats
