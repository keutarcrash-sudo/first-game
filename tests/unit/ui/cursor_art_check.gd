## Logic check for CursorArt. Run with:
## godot --headless -s res://tests/unit/ui/cursor_art_check.gd
## Prints "CURSOR_ART OK" or "CURSOR_ART FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/cursor.json"
const CYAN := Color("#19e3ff")
const PINK := Color("#ff2e88")
const GAP: int = 6  # crosshair.gap in the real file


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("CURSOR_ART OK")
	else:
		print("CURSOR_ART FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var art: CursorArt = CursorArt.load_from_file(PATH)
	if art == null:
		return "real file loads"
	if not is_equal_approx(art.hover_check_interval, 0.1):
		return "hover_check_interval is 0.1"
	# Crosshair 40x40, center pixel (20, 20).
	var cross: Image = art.crosshair(false)
	if cross.get_size() != Vector2i(40, 40):
		return "crosshair is 40x40"
	if art.crosshair_hotspot() != Vector2(20, 20):
		return "crosshair hotspot is (20, 20)"
	if not cross.get_pixel(20, 20).is_equal_approx(CYAN):
		return "center pixel is the crosshair color"
	if not art.crosshair(true).get_pixel(20, 20).is_equal_approx(PINK):
		return "center pixel is pink on hover"
	# Right arm colored x in [28, 38] (c + gap + outline_px = 26 + 2), y in [19, 21].
	if cross.get_pixel(20 + GAP + 2, 20).a < 0.99:
		return "arm pixel is opaque"
	# Gap: arm outline starts at x = 26 and the dot outline stops at distance < 4, so x = 24 is empty.
	if cross.get_pixel(20 + GAP - 2, 20).a > 0.01:
		return "gap pixel is transparent"
	for corner: Vector2i in [Vector2i(0, 0), Vector2i(39, 0), Vector2i(0, 39), Vector2i(39, 39)]:
		if cross.get_pixel(corner.x, corner.y).a > 0.01:
			return "crosshair corner %s is transparent" % corner
	# Arrow 36x36: tip (3, 3); (5, 10) is inside the triangle (colored).
	var arrow: Image = art.arrow()
	if arrow.get_size() != Vector2i(36, 36):
		return "arrow is 36x36"
	var tip: Vector2 = art.arrow_hotspot()
	if tip != Vector2(3, 3):
		return "arrow hotspot is (3, 3)"
	if arrow.get_pixel(int(tip.x), int(tip.y)).a < 0.99:
		return "arrow hotspot pixel is opaque"
	if not arrow.get_pixel(5, 10).is_equal_approx(Color("#ffe14d")):
		return "arrow body pixel is the arrow color"
	if arrow.get_pixel(35, 0).a > 0.01:
		return "arrow far corner is transparent"
	return _run_invalid()


## Each broken copy of the real file must be refused (null).
func _run_invalid() -> String:
	var base: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not base is Dictionary:
		return "real file parses"
	var checks: Array[Array] = [
		["crosshair", "size", 129, "size > 128 refused"],
		["crosshair", "size", 7, "size < 8 refused"],
		["arrow", "size", 129, "arrow size > 128 refused"],
		["crosshair", "color", "not-a-color", "invalid color refused"],
	]
	for check: Array in checks:
		var copy: Dictionary = (base as Dictionary).duplicate(true)
		(copy[check[0]] as Dictionary)[check[1]] = check[2]
		if CursorArt.from_data(copy, "invalid") != null:
			return check[3]
	var bad_interval: Dictionary = (base as Dictionary).duplicate(true)
	bad_interval["hover_check_interval"] = 0.0
	if CursorArt.from_data(bad_interval, "invalid") != null:
		return "hover_check_interval <= 0 refused"
	return ""
