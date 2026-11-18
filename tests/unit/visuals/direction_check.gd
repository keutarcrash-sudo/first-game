## Logic check for SpriteSheet.direction_index. Run with:
## godot --headless -s res://tests/unit/visuals/direction_check.gd
## Prints "DIRECTION OK" or "DIRECTION FAIL: <name>" then quits.
extends SceneTree


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("DIRECTION OK")
	else:
		print("DIRECTION FAIL: %s" % failed)
	quit()


## Returns the name of the first failing check, or "" if all pass.
func _run() -> String:
	if SpriteSheet.direction_index(0.0, 8) != 0:
		return "right_is_0"
	if SpriteSheet.direction_index(PI / 2.0, 8) != 2:
		return "down_is_2"
	if SpriteSheet.direction_index(PI, 8) != 4:
		return "left_is_4"
	if SpriteSheet.direction_index(-PI / 2.0, 8) != 6:
		return "up_is_6"
	if SpriteSheet.direction_index(deg_to_rad(22.0), 8) != 0:
		return "22_degrees_is_0"
	if SpriteSheet.direction_index(deg_to_rad(23.0), 8) != 1:
		return "23_degrees_is_1"
	if SpriteSheet.direction_index(deg_to_rad(-170.0), 8) != 4:
		return "minus_170_degrees_is_4"
	if SpriteSheet.direction_index(1.0, 1) != 0:
		return "single_direction_is_0"
	return ""
