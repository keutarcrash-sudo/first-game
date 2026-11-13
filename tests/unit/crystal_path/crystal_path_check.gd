## Logic check for CrystalPath. Run with:
## godot --headless -s res://tests/unit/crystal_path/crystal_path_check.gd
## Prints "CRYSTAL_PATH OK" or "CRYSTAL_PATH FAIL: <name>" then quits.
extends SceneTree

const EPS := 0.001


func _init() -> void:
	var failed := _run()
	if failed.is_empty():
		print("CRYSTAL_PATH OK")
	else:
		print("CRYSTAL_PATH FAIL: %s" % failed)
	quit()


## Returns the name of the first failing check, or "" if all pass.
func _run() -> String:
	var bounds := Rect2(0, 0, 2400, 1600)
	var settings := PathSettings.new()
	settings.segment_length = 160.0
	settings.max_turn_degrees = 50.0
	settings.margin = 120.0
	var inner: Rect2 = bounds.grow(-120.0).grow(0.5)

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var path: CrystalPath = CrystalPath.generate(Vector2(1200, 800), 1500.0, bounds, settings, rng)
	if absf(path.length() - 1500.0) >= 0.5:
		return "length_matches"
	for p: Vector2 in path.points:
		if not inner.has_point(p):
			return "stays_inside"

	rng.seed = 12345
	var corner: CrystalPath = CrystalPath.generate(Vector2(130, 130), 2500.0, bounds, settings, rng)
	if absf(corner.length() - 2500.0) >= 0.5:
		return "corner_start"
	for p: Vector2 in corner.points:
		if not inner.has_point(p):
			return "corner_start"

	if not path.position_at(0.0).is_equal_approx(path.points[0]) \
			or not path.position_at(path.length()).is_equal_approx(path.end_point()) \
			or not path.position_at(-10.0).is_equal_approx(path.points[0]) \
			or not path.position_at(path.length() + 10.0).is_equal_approx(path.end_point()):
		return "position_at_ends"

	var manual := CrystalPath.new()
	manual.points = PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)])
	if manual.position_at(150.0).distance_to(Vector2(100, 50)) > EPS:
		return "position_at_middle"

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 777
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 777
	var a: CrystalPath = CrystalPath.generate(Vector2(1200, 800), 1500.0, bounds, settings, rng_a)
	var b: CrystalPath = CrystalPath.generate(Vector2(1200, 800), 1500.0, bounds, settings, rng_b)
	if a.points.size() != b.points.size():
		return "deterministic"
	for i: int in a.points.size():
		if a.points[i] != b.points[i]:
			return "deterministic"

	return ""
