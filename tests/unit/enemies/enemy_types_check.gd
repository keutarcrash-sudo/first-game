## Logic check for EnemyTypes (count formula, wave composition and preview text, validation). Run with:
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
	var failed: String = _check_composition(types)
	if not failed.is_empty():
		return failed
	# Validation: each broken file must be refused.
	var good: Dictionary = {"id": "k", "hp_mult": 1.0, "speed_mult": 1.0, "sheet": "res://x", "height_px": 84.0,
		"display_name": "kamikaze", "display_plural": "kamikazes",
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
		["missing display_name", func(d: Dictionary) -> void: d.erase("display_name")],
		["empty display_plural", func(d: Dictionary) -> void: d["display_plural"] = ""],
		["numeric display_name", func(d: Dictionary) -> void: d["display_name"] = 3],
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


## Wave composition by type (étape 5a, spec §8bis) and its preview text.
func _check_composition(types: EnemyTypes) -> String:
	var wave_5: Dictionary = types.composition(5, 18, 1.0)
	if wave_5 != {"goblin": 18, "kamikaze": 3, "artilleur": 1}:
		return "composition(5, 18, 1.0) = %s" % wave_5
	if wave_5.keys() != ["goblin", "kamikaze", "artilleur"]:
		return "composition lists the types in file order"
	var final_mult := 1.5
	var wave_8: Dictionary = types.composition(8, 27, final_mult)
	if wave_8.size() != 3:
		return "composition(8, 27, 1.5) holds the three types"
	for type_id: String in ["goblin", "kamikaze", "artilleur"]:
		var expected: int = roundi(types.count_for(type_id, 8, 27) * final_mult)
		if wave_8.get(type_id) != expected:
			return "composition(8, 27, 1.5)[%s] = %s, expected %d" % [type_id, wave_8.get(type_id), expected]
	var wave_1: Dictionary = types.composition(1, 6, 1.0)
	if wave_1 != {"goblin": 6}:
		return "composition(1, 6, 1.0) holds only the goblins: %s" % wave_1
	var text: String = types.preview_text({"goblin": 15, "kamikaze": 7, "artilleur": 1})
	if text != "15 gobelins, 7 kamikazes, 1 artilleur":
		return "preview_text plural and singular: '%s'" % text
	text = types.preview_text({"goblin": 1, "kamikaze": 1, "artilleur": 2})
	if text != "1 gobelin, 1 kamikaze, 2 artilleurs":
		return "preview_text singular and plural: '%s'" % text
	return ""
