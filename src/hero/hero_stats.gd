## Tuning values for the hero, its projectiles and the field (story 001,
## design/game-brief.md MVP feature 1). Loaded once from a JSON file;
## every value is required and must be a positive number.
class_name HeroStats
extends RefCounted

const REQUIRED_KEYS := [
	"hero_speed", "hero_radius", "fire_rate",
	"bullet_damage", "bullet_speed", "bullet_max_range", "bullet_radius",
	"arena_width", "arena_height",
]

## Hero movement speed, in pixels per second.
var hero_speed: float
## Hero body radius, in pixels (collision and drawing).
var hero_radius: float
## Automatic fire rate, in shots per second.
var fire_rate: float
## Damage dealt by one projectile.
var bullet_damage: float
## Projectile speed, in pixels per second.
var bullet_speed: float
## Distance in pixels a projectile travels before it disappears.
var bullet_max_range: float
## Projectile radius, in pixels (collision and drawing).
var bullet_radius: float
## Field size, in pixels.
var arena_size: Vector2


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> HeroStats:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("HeroStats: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("HeroStats: '%s' is not a valid JSON object." % path)
		return null
	for key: String in REQUIRED_KEYS:
		if not data.has(key):
			push_error("HeroStats: key '%s' is missing in '%s'." % [key, path])
			return null
		var value: Variant = data[key]
		if not (value is float or value is int) or value <= 0:
			push_error("HeroStats: key '%s' in '%s' must be a positive number (got %s)." % [key, path, value])
			return null
	var stats := HeroStats.new()
	stats.hero_speed = data["hero_speed"]
	stats.hero_radius = data["hero_radius"]
	stats.fire_rate = data["fire_rate"]
	stats.bullet_damage = data["bullet_damage"]
	stats.bullet_speed = data["bullet_speed"]
	stats.bullet_max_range = data["bullet_max_range"]
	stats.bullet_radius = data["bullet_radius"]
	stats.arena_size = Vector2(data["arena_width"], data["arena_height"])
	return stats
