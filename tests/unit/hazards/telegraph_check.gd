## Logic check for the TelegraphZone helpers. Run with:
## godot --headless -s res://tests/unit/hazards/telegraph_check.gd
## Prints "TELEGRAPH OK" or "TELEGRAPH FAIL: <name>" then quits.
extends SceneTree

const CENTER := Vector2(10.0, 20.0)
const RADIUS := 100.0
const BODY_RADIUS := 20.0


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("TELEGRAPH OK")
	else:
		print("TELEGRAPH FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var edge: Vector2 = CENTER + Vector2(RADIUS + BODY_RADIUS, 0.0)
	if not TelegraphZone.hits_body(CENTER, RADIUS, edge, BODY_RADIUS):
		return "hits_body true when body overlaps the edge exactly"
	if TelegraphZone.hits_body(CENTER, RADIUS, edge + Vector2(1.0, 0.0), BODY_RADIUS):
		return "hits_body false just beyond"
	if not TelegraphZone.hits_body(CENTER, RADIUS, CENTER, BODY_RADIUS):
		return "hits_body true at the centre"
	var point_edge: Vector2 = CENTER + Vector2(0.0, RADIUS)
	if not TelegraphZone.hits_point(CENTER, RADIUS, point_edge):
		return "hits_point true at distance = radius"
	if TelegraphZone.hits_point(CENTER, RADIUS, point_edge + Vector2(0.0, 1.0)):
		return "hits_point false beyond"
	return ""
