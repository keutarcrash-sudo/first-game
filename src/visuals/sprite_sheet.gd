## Sprite sheets of one object (hero, enemy, tower...), read from the
## sheet.json of a folder under assets/sprites/. Each animation is a PNG of
## frames x cell_w by directions x cell_h pixels: row = direction, column = frame.
## Direction k looks toward screen angle k * 360 / directions, clockwise from
## the right (same as Vector2.angle(), y down).
class_name SpriteSheet
extends RefCounted

## Default cell size in pixels (an animation may override it).
var cell: Vector2i
## Default anchor in pixels inside a cell: the point placed on the node position.
var anchor: Vector2
## Number of directions (rows) in every animation.
var directions: int

var _animations: Dictionary = {}


## Reads and validates [code]sheet.json[/code] in [param dir] and loads its
## textures. Returns [code]null[/code] and prints an error naming the file and
## the faulty key if anything is wrong.
static func load_from_dir(dir: String) -> SpriteSheet:
	var path: String = dir.path_join("sheet.json")
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("SpriteSheet: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("SpriteSheet: '%s' is not a valid JSON object." % path)
		return null
	var root: Dictionary = data
	var sheet := SpriteSheet.new()
	var root_cell: Vector2i = _read_cell(root, "cell", path)
	if root_cell == Vector2i.ZERO:
		return null
	sheet.cell = root_cell
	if not _is_pair(root.get("anchor")):
		push_error("SpriteSheet: key 'anchor' is missing or invalid in '%s'." % path)
		return null
	sheet.anchor = _to_vector2(root["anchor"])
	var dir_count: Variant = root.get("directions")
	if not _is_positive_int(dir_count):
		push_error("SpriteSheet: key 'directions' must be a positive integer in '%s'." % path)
		return null
	sheet.directions = int(dir_count)
	var anims: Variant = root.get("animations")
	if not anims is Dictionary or (anims as Dictionary).is_empty():
		push_error("SpriteSheet: key 'animations' is missing or empty in '%s'." % path)
		return null
	for anim_name: String in anims:
		var entry: Variant = anims[anim_name]
		var where: String = "animations.%s" % anim_name
		if not entry is Dictionary:
			push_error("SpriteSheet: key '%s' must be an object in '%s'." % [where, path])
			return null
		var anim: Dictionary = entry
		var file: Variant = anim.get("file")
		if not file is String or (file as String).is_empty():
			push_error("SpriteSheet: key '%s.file' is missing in '%s'." % [where, path])
			return null
		if not _is_positive_int(anim.get("frames")):
			push_error("SpriteSheet: key '%s.frames' must be a positive integer in '%s'." % [where, path])
			return null
		var fps_value: Variant = anim.get("fps")
		if not (fps_value is float or fps_value is int) or fps_value <= 0:
			push_error("SpriteSheet: key '%s.fps' must be a positive number in '%s'." % [where, path])
			return null
		if not anim.get("loop") is bool:
			push_error("SpriteSheet: key '%s.loop' must be a boolean in '%s'." % [where, path])
			return null
		var anim_cell: Vector2i = sheet.cell
		if anim.has("cell"):
			anim_cell = _read_cell(anim, "cell", path, where + ".")
			if anim_cell == Vector2i.ZERO:
				return null
		var anim_anchor: Vector2 = sheet.anchor
		if anim.has("anchor"):
			if not _is_pair(anim["anchor"]):
				push_error("SpriteSheet: key '%s.anchor' is invalid in '%s'." % [where, path])
				return null
			anim_anchor = _to_vector2(anim["anchor"])
		var png: String = dir.path_join(file as String)
		var tex: Texture2D = load(png) as Texture2D
		if tex == null:
			push_error("SpriteSheet: cannot load texture '%s' (key '%s.file' in '%s')." % [png, where, path])
			return null
		var frames: int = int(anim["frames"])
		var expected := Vector2i(frames * anim_cell.x, sheet.directions * anim_cell.y)
		if Vector2i(tex.get_size()) != expected:
			push_error("SpriteSheet: '%s' is %s px but '%s' expects %s px." % [png, Vector2i(tex.get_size()), path, expected])
			return null
		sheet._animations[StringName(anim_name)] = {
			"texture": tex,
			"frames": frames,
			"fps": float(fps_value),
			"loop": anim["loop"],
			"cell": anim_cell,
			"anchor": anim_anchor,
		}
	return sheet


## Index of the direction closest to [param angle] (radians, as
## [method Vector2.angle]). Always 0 when [param directions] is 1 or less.
static func direction_index(angle: float, directions: int) -> int:
	if directions <= 1:
		return 0
	var step: float = TAU / float(directions)
	return posmod(roundi(angle / step), directions)


## True if the sheet has an animation called [param name].
func has_animation(name: StringName) -> bool:
	return _animations.has(name)


## Number of frames of [param name] (0 if unknown).
func frame_count(name: StringName) -> int:
	return _lookup(name, "frames", 0)


## Playback speed of [param name], in frames per second (0 if unknown).
func fps(name: StringName) -> float:
	return _lookup(name, "fps", 0.0)


## True if [param name] loops (false if unknown).
func loops(name: StringName) -> bool:
	return _lookup(name, "loop", false)


## Texture of [param name] (null if unknown).
func texture(name: StringName) -> Texture2D:
	return _lookup(name, "texture", null)


## Cell size in pixels of [param name]; the root cell if it has no override.
func cell_of(name: StringName) -> Vector2i:
	return _lookup(name, "cell", cell)


## Anchor in pixels of [param name]; the root anchor if it has no override.
func anchor_of(name: StringName) -> Vector2:
	return _lookup(name, "anchor", anchor)


func _lookup(name: StringName, key: String, fallback: Variant) -> Variant:
	if not _animations.has(name):
		return fallback
	return (_animations[name] as Dictionary)[key]


static func _is_positive_int(value: Variant) -> bool:
	return (value is int and value > 0) or (value is float and value > 0.0 and value == floorf(value))


static func _is_pair(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != 2:
		return false
	for item: Variant in value:
		if not (item is int or item is float):
			return false
	return true


static func _to_vector2(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))


## Reads a positive integer [w, h] pair; returns Vector2i.ZERO after an error.
static func _read_cell(dict: Dictionary, key: String, path: String, prefix: String = "") -> Vector2i:
	var value: Variant = dict.get(key)
	if not _is_pair(value) or not _is_positive_int(value[0]) or not _is_positive_int(value[1]):
		push_error("SpriteSheet: key '%s%s' must be [width, height] of positive integers in '%s'." % [prefix, key, path])
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))
