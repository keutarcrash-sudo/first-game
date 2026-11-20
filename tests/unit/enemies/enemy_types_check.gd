## Logic check for EnemyTypes (count formula and validation). Run with:
## godot --headless -s res://tests/unit/enemies/enemy_types_check.gd
## Prints "ENEMY TYPES OK" or "ENEMY TYPES FAIL: <name>" then quits (exit 1 on failure).
extends SceneTree

const TYPES_PATH := "res://assets/data/enemy_types.json"
const GOBLIN_BASE := 7  # Stands for the wave's own enemy_count.


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("ENEMY TYPES OK")
	else:
		print("ENEMY TYPES FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var types: EnemyTypes = EnemyTypes.load_from_file(TYPES_PATH)
	if types == null:
		return "the shipped enemy_types.json loads"
	if types.all().size() != 3:
		return "three types shipped"
	var cases: Array = [
		["goblin", 1, GOBLIN_BASE], ["goblin", 9, GOBLIN_BASE],
		["kamikaze", 2, 0], ["kamikaze", 3, 1], ["kamikaze", 4, 2], ["kamikaze", 5, 3],
		["artilleur", 4, 0], ["artilleur", 5, 1], ["artilleur", 6, 1], ["artilleur", 7, 2],
	]
	for c: Array in cases:
		var got: int = types.count_for(c[0], c[1], GOBLIN_BASE)
		if got != c[2]:
			return "count_for(%s, wave %d) = %d, expected %d" % [c[0], c[1], got, c[2]]
	# Validation: each broken file must be refused.
	var good: Dictionary = {"id": "k", "hp_mult": 1.0, "speed_mult": 1.0, "sheet": "res://x", "height_px": 84.0,
		"behaviour": "kamikaze", "start_wave": 3, "base_count": 1, "fuse": 0.6, "radius": 90.0, "crystal_damage": 20.0, "hero_damage": 25.0}
	if EnemyTypes.from_data({"types": [good]}, "test") == null:
		return "a valid type is accepted"
	var broken: Array = [
		["missing fuse", func(d: Dictionary) -> void: d.erase("fuse")],
		["negative hp_mult", func(d: Dictionary) -> void: d["hp_mult"] = -1.0],
		["unknown behaviour", func(d: Dictionary) -> void: d["behaviour"] = "fly"],
		["start_wave 0", func(d: Dictionary) -> void: d["start_wave"] = 0],
		["base_count -2", func(d: Dictionary) -> void: d["base_count"] = -2],
		["empty id", func(d: Dictionary) -> void: d["id"] = ""],
	]
	for b: Array in broken:
		var copy: Dictionary = good.duplicate()
		(b[1] as Callable).call(copy)
		if EnemyTypes.from_data({"types": [copy]}, "test") != null:
			return "refuses: %s" % b[0]
	if EnemyTypes.from_data({"types": [good, good]}, "test") != null:
		return "refuses duplicate ids"
	if EnemyTypes.from_data([], "test") != null:
		return "refuses a non-object file"
	return ""
