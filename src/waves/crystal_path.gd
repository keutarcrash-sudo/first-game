## The polyline the crystal follows during a wave (étape 1 — le cristal qui
## avance). Pure logic: no node, no scene. Generated once per wave from a
## seeded random number generator so it can be replayed and tested.
class_name CrystalPath
extends RefCounted

## How many random headings are tried before falling back to the centre.
const MAX_TRIES := 12

## Vertices of the path, in order. Always at least 2 points.
var points: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])


## Total length of the path in pixels (sum of the segment lengths).
func length() -> float:
	var total := 0.0
	for i: int in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total


## Position reached after walking [param distance] pixels along the path.
## [param distance] is clamped to [code][0, length()][/code].
func position_at(distance: float) -> Vector2:
	if distance <= 0.0:
		return points[0]
	var remaining := distance
	for i: int in range(1, points.size()):
		var seg_len: float = points[i - 1].distance_to(points[i])
		if remaining <= seg_len:
			if seg_len <= 0.0:
				return points[i]
			return points[i - 1].lerp(points[i], remaining / seg_len)
		remaining -= seg_len
	return end_point()


## Last point of the path.
func end_point() -> Vector2:
	return points[points.size() - 1]


## Builds a path of [param total_length] pixels starting at [param start]
## (clamped into [param bounds] shrunk by the margin). Each segment turns by at
## most [code]max_turn_degrees[/code] from the previous one and stays inside the
## shrunk bounds; when 12 tries fail, the segment heads back to the centre.
## A [param total_length] of 0 or less gives a path of two identical points.
static func generate(start: Vector2, total_length: float, bounds: Rect2, settings: PathSettings, rng: RandomNumberGenerator) -> CrystalPath:
	var inner: Rect2 = bounds.grow(-settings.margin)
	if inner.size.x < 0.0 or inner.size.y < 0.0:
		inner = Rect2(bounds.get_center(), Vector2.ZERO)
	var pos: Vector2 = start.clamp(inner.position, inner.end)
	var heading: float = rng.randf_range(0.0, TAU)
	var max_turn: float = deg_to_rad(settings.max_turn_degrees)
	var result := CrystalPath.new()
	var pts := PackedVector2Array([pos])
	var remaining: float = total_length
	while remaining > 0.0:
		var step: float = minf(settings.segment_length, remaining)
		var cand_heading: float = heading
		var cand: Vector2 = pos
		var accepted := false
		for _try: int in MAX_TRIES:
			cand_heading = heading + rng.randf_range(-max_turn, max_turn)
			cand = pos + Vector2.from_angle(cand_heading) * step
			if inner.has_point(cand):
				accepted = true
				break
		if not accepted:
			cand_heading = (inner.get_center() - pos).angle()
			cand = pos + Vector2.from_angle(cand_heading) * step
		heading = cand_heading
		pos = cand
		pts.append(pos)
		remaining -= step
	if pts.size() < 2:
		pts.append(pos)
	result.points = pts
	return result
