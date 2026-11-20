## Comic-book explosion (passe graphique 1): an 11-point star filled with halftone
## dots (yellow / pink), an expanding cyan ring and an onomatopoeia in white
## Bangers with a black outline, slightly tilted. Lasts [constant DURATION]
## seconds, then frees itself. Display only: takes no part in the game.
class_name PopBurst
extends Node2D

const DURATION := 0.6
const BRANCHES := 11
const INNER_RATIO := 0.62  # Inner radius of the star, as a fraction of the outer one.
const POP_TIME := 0.12  # Seconds the star takes to grow to full size.
const FADE_START := 0.7  # Fraction of the duration at which everything starts to fade.
const DOT_SPACING_RATIO := 0.2  # Dot grid spacing, as a fraction of the radius.
const DOT_RADIUS_RATIO := 0.06
const DOT_COLOR_A := Color(1.0, 0.92, 0.25)
const DOT_COLOR_B := Color(1.0, 0.35, 0.8)
const OUTLINE_COLOR := Color.BLACK
const OUTLINE_WIDTH := 4.0
const RING_COLOR := Color(0.2, 0.95, 1.0)
const RING_WIDTH := 5.0
const RING_POINTS := 48
const RING_END_RATIO := 1.5  # Ring radius at the end, as a fraction of the star radius.
const TILT := -0.14  # Radians.
const TEXT_OUTLINE := 8
const MIN_FONT_SIZE := 28
const MAX_FONT_SIZE := 72
const FONT_RATIO := 0.5  # Font size as a fraction of the radius, before clamping.

var _word := ""
var _color := Color.WHITE
var _radius := 40.0
var _age := 0.0
var _star := PackedVector2Array()


## Adds a burst to [param parent] at [param world_position]: [param word] is the
## onomatopoeia, [param color] the star fill, [param radius] the star size in pixels.
## Safe inside a physics callback (the node is added deferred).
static func spawn(parent: Node, world_position: Vector2, word: String, color: Color, radius: float) -> void:
	var host := parent as Node2D
	if host == null:
		return
	var burst := PopBurst.new()
	burst.setup(word, color, radius)
	burst.position = host.to_local(world_position)
	host.add_child.call_deferred(burst)


## Sets the [param word] shown, the star fill [param color] and the star [param radius] in pixels.
## Call before adding to the tree.
func setup(word: String, color: Color, radius: float) -> void:
	_word = word
	_color = color
	_radius = maxf(radius, 1.0)
	_star = PackedVector2Array()
	var points: int = BRANCHES * 2
	for i: int in points:
		var angle: float = TAU * float(i) / float(points) - PI / 2.0
		var r: float = 1.0 if i % 2 == 0 else INNER_RATIO
		_star.append(Vector2.from_angle(angle) * r)


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t: float = clampf(_age / DURATION, 0.0, 1.0)
	var fade: float = 1.0 - clampf((t - FADE_START) / (1.0 - FADE_START), 0.0, 1.0)
	var grow: float = lerpf(0.5, 1.0, clampf(_age / POP_TIME, 0.0, 1.0))
	var size: float = _radius * grow
	# Star: fill, halftone dots, black outline.
	var points := PackedVector2Array()
	for p: Vector2 in _star:
		points.append(p * size)
	draw_colored_polygon(points, Color(_color.r, _color.g, _color.b, fade))
	var spacing: float = size * DOT_SPACING_RATIO
	var reach: float = size * INNER_RATIO * 0.95
	var steps: int = ceili(reach / spacing)
	for gy: int in range(-steps, steps + 1):
		for gx: int in range(-steps, steps + 1):
			var spot := Vector2(gx, gy) * spacing
			if spot.length() > reach:
				continue
			var dot: Color = DOT_COLOR_A if (gx + gy) % 2 == 0 else DOT_COLOR_B
			draw_circle(spot, size * DOT_RADIUS_RATIO, Color(dot.r, dot.g, dot.b, 0.8 * fade))
	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, Color(OUTLINE_COLOR.r, OUTLINE_COLOR.g, OUTLINE_COLOR.b, fade), OUTLINE_WIDTH)
	# Expanding cyan ring.
	draw_arc(Vector2.ZERO, lerpf(_radius * 0.5, _radius * RING_END_RATIO, t), 0.0, TAU, RING_POINTS, Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, fade), RING_WIDTH)
	# Onomatopoeia.
	var font: Font = NeonFonts.title()
	if font == null:
		font = ThemeDB.fallback_font
	var font_size: int = clampi(roundi(_radius * FONT_RATIO), MIN_FONT_SIZE, MAX_FONT_SIZE)
	draw_set_transform(Vector2.ZERO, TILT, Vector2(grow, grow))
	var width: float = _radius * 2.0
	var at := Vector2(-width * 0.5, font_size * 0.35)
	draw_string_outline(font, at, _word, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, TEXT_OUTLINE, Color(0.0, 0.0, 0.0, fade))
	draw_string(font, at, _word, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color(1.0, 1.0, 1.0, fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
