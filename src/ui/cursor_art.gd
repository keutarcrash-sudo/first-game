## Pixel art of the hardware mouse cursors (combat crosshair and menu arrow), drawn in
## code from the settings in cursor.json. Pure logic: it only builds Images.
class_name CursorArt
extends RefCounted

## Largest and smallest cursor image side accepted (the system refuses cursors above 128).
const MAX_SIZE: int = 128
const MIN_SIZE: int = 8

var _size: int = 0
var _color: Color = Color.WHITE
var _hover_color: Color = Color.WHITE
var _outline: Color = Color.BLACK
var _arm_length: int = 0
var _gap: int = 0
var _hover_gap: int = 0
var _thickness: int = 0
var _outline_px: int = 0
var _dot_radius: int = 0
var _arrow_size: int = 0
var _arrow_color: Color = Color.WHITE
var _arrow_outline: Color = Color.BLACK
var _arrow_outline_px: int = 0
var _arrow_shadow_offset: int = 0

## Seconds between two "is the mouse over an enemy" checks.
var hover_check_interval: float = 0.1


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> CursorArt:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("CursorArt: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	return from_data(JSON.parse_string(text), path)


## Validates already-parsed JSON [param data] ([param source] names the file in errors).
## Returns [code]null[/code] and prints an error on the first problem.
static func from_data(data: Variant, source: String) -> CursorArt:
	if not data is Dictionary:
		push_error("CursorArt: '%s' must be a JSON object." % source)
		return null
	var d: Dictionary = data
	var r := CursorArt.new()
	if not d.get("crosshair") is Dictionary or not d.get("arrow") is Dictionary:
		push_error("CursorArt: keys 'crosshair' and 'arrow' in '%s' must be objects." % source)
		return null
	var c: Dictionary = d["crosshair"]
	var a: Dictionary = d["arrow"]
	for pair: Array in [["crosshair", c], ["arrow", a]]:
		var section: Dictionary = pair[1]
		var size: Variant = section.get("size")
		if not _is_number(size) or size < MIN_SIZE or size > MAX_SIZE:
			push_error("CursorArt: key '%s.size' in '%s' must be a number in [%d, %d]." % [pair[0], source, MIN_SIZE, MAX_SIZE])
			return null
	for key: String in ["color", "hover_color", "outline"]:
		if not _is_color(c.get(key)):
			push_error("CursorArt: key 'crosshair.%s' in '%s' must be a valid #rrggbb color." % [key, source])
			return null
	for key: String in ["color", "outline"]:
		if not _is_color(a.get(key)):
			push_error("CursorArt: key 'arrow.%s' in '%s' must be a valid #rrggbb color." % [key, source])
			return null
	for key: String in ["arm_length", "thickness"]:
		if not _is_number(c.get(key)) or c[key] < 1:
			push_error("CursorArt: key 'crosshair.%s' in '%s' must be a number >= 1." % [key, source])
			return null
	for key: String in ["gap", "hover_gap", "outline_px", "dot_radius"]:
		if not _is_number(c.get(key)) or c[key] < 0:
			push_error("CursorArt: key 'crosshair.%s' in '%s' must be a number >= 0." % [key, source])
			return null
	for key: String in ["outline_px", "shadow_offset"]:
		if not _is_number(a.get(key)) or a[key] < 0:
			push_error("CursorArt: key 'arrow.%s' in '%s' must be a number >= 0." % [key, source])
			return null
	if not _is_number(d.get("hover_check_interval")) or d["hover_check_interval"] <= 0:
		push_error("CursorArt: key 'hover_check_interval' in '%s' must be a positive number." % source)
		return null
	r._size = int(c["size"])
	r._color = Color(c["color"] as String)
	r._hover_color = Color(c["hover_color"] as String)
	r._outline = Color(c["outline"] as String)
	r._arm_length = int(c["arm_length"])
	r._gap = int(c["gap"])
	r._hover_gap = int(c["hover_gap"])
	r._thickness = int(c["thickness"])
	r._outline_px = int(c["outline_px"])
	r._dot_radius = int(c["dot_radius"])
	r._arrow_size = int(a["size"])
	r._arrow_color = Color(a["color"] as String)
	r._arrow_outline = Color(a["outline"] as String)
	r._arrow_outline_px = int(a["outline_px"])
	r._arrow_shadow_offset = int(a["shadow_offset"])
	r.hover_check_interval = float(d["hover_check_interval"])
	return r


## Crosshair image (size x size). Geometry, with c = size / 2 the center pixel, g the gap
## (hover_gap when [param hover]), o = outline_px, t = thickness: four colored arms of
## arm_length pixels start at c + g + o from the center (right arm: x in [c+g+o, c+g+o+len-1],
## y in [c - t/2, c - t/2 + t - 1]; the others mirror it), plus a colored dot of radius
## dot_radius at (c, c). Black shapes are the same shapes grown by o (dot: distance < r + o),
## drawn first; pixels outside the image are clipped. The rest is transparent.
func crosshair(hover: bool) -> Image:
	var img: Image = Image.create_empty(_size, _size, false, Image.FORMAT_RGBA8)
	var c: int = _size / 2
	var inner: int = (_hover_gap if hover else _gap) + _outline_px
	var half: int = _thickness / 2
	var arms: Array[Rect2i] = [
		Rect2i(c + inner, c - half, _arm_length, _thickness),
		Rect2i(c - inner - _arm_length + 1, c - half, _arm_length, _thickness),
		Rect2i(c - half, c + inner, _thickness, _arm_length),
		Rect2i(c - half, c - inner - _arm_length + 1, _thickness, _arm_length),
	]
	var fill: Color = _hover_color if hover else _color
	var outer_r: int = _dot_radius + _outline_px
	for arm: Rect2i in arms:
		_fill_rect(img, arm.grow(_outline_px), _outline)
	for dy: int in range(-outer_r, outer_r + 1):
		for dx: int in range(-outer_r, outer_r + 1):
			if dx * dx + dy * dy < outer_r * outer_r:
				_set(img, c + dx, c + dy, _outline)
	for arm: Rect2i in arms:
		_fill_rect(img, arm, fill)
	for dy: int in range(-_dot_radius, _dot_radius + 1):
		for dx: int in range(-_dot_radius, _dot_radius + 1):
			if dx * dx + dy * dy <= _dot_radius * _dot_radius:
				_set(img, c + dx, c + dy, fill)
	return img


## Hotspot of the crosshair: its exact center pixel.
func crosshair_hotspot() -> Vector2:
	return Vector2(_size / 2, _size / 2)


## Arrow image (size x size). With o = outline_px and L = 0.6 * size, the pointer is the
## triangle tip (o, o), (o, o + L), (o + 0.62 L, o + 0.62 L) (a vertical edge and a 45 degree
## edge, tilted pointer). Drawn back to front: shadow (outline color at half alpha, the grown
## shape shifted by shadow_offset), black outline (pixels whose center is within o of the
## triangle), then the colored triangle. Pixel centers are x + 0.5, y + 0.5.
func arrow() -> Image:
	var img: Image = Image.create_empty(_arrow_size, _arrow_size, false, Image.FORMAT_RGBA8)
	var o: float = float(_arrow_outline_px)
	var length: float = 0.6 * _arrow_size
	var tip := Vector2(o, o)
	var down := Vector2(o, o + length)
	var side := Vector2(o + 0.62 * length, o + 0.62 * length)
	var shadow: Color = Color(_arrow_outline, 0.5)
	var shift := Vector2(_arrow_shadow_offset, _arrow_shadow_offset)
	for y: int in _arrow_size:
		for x: int in _arrow_size:
			var p := Vector2(x + 0.5, y + 0.5)
			if _triangle_distance(p - shift, tip, down, side) <= o:
				img.set_pixel(x, y, shadow)
	for y: int in _arrow_size:
		for x: int in _arrow_size:
			var p := Vector2(x + 0.5, y + 0.5)
			var dist: float = _triangle_distance(p, tip, down, side)
			if dist <= 0.0:
				img.set_pixel(x, y, _arrow_color)
			elif dist <= o:
				img.set_pixel(x, y, _arrow_outline)
	return img


## Hotspot of the arrow: its tip, at (outline_px, outline_px).
func arrow_hotspot() -> Vector2:
	return Vector2(_arrow_outline_px, _arrow_outline_px)


## 0 if [param p] is inside triangle abc (edges included), else the distance to its nearest edge.
static func _triangle_distance(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> float:
	var s1: float = (b - a).cross(p - a)
	var s2: float = (c - b).cross(p - b)
	var s3: float = (a - c).cross(p - c)
	if (s1 >= 0.0 and s2 >= 0.0 and s3 >= 0.0) or (s1 <= 0.0 and s2 <= 0.0 and s3 <= 0.0):
		return 0.0
	var best: float = INF
	for seg: Array in [[a, b], [b, c], [c, a]]:
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1])
		best = minf(best, p.distance_to(q))
	return best


static func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	var clipped: Rect2i = rect.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if clipped.has_area():
		img.fill_rect(clipped, color)


static func _set(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


static func _is_number(value: Variant) -> bool:
	return value is float or value is int


static func _is_color(value: Variant) -> bool:
	return value is String and (value as String).begins_with("#") and (value as String).is_valid_html_color()
