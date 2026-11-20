## Draws one animation of a [SpriteSheet] in the direction the object faces.
## The anchor of the current cell sits on the node position (or, with
## [code]center_body[/code], the middle of the root cell does). The scale is
## height_px / root cell height for every animation, so bigger cells (death,
## roll) are drawn bigger, not shrunk.
class_name DirectionalSprite
extends Node2D

## Emitted when a non-looping animation reaches its last frame.
signal animation_finished(anim_name: StringName)

## Multiplies the image colour (for example a translucent placement preview).
var tint: Color = Color.WHITE:
	set(value):
		tint = value
		queue_redraw()

## Multiplies how fast the animation advances (1 = the sheet's fps, 0 = frozen
## on the current frame). [method play] resets it to 1 when it starts an animation.
var speed_scale: float = 1.0

var _sheet: SpriteSheet
var _scale: float = 1.0
var _body_shift_y: float = 0.0  # Downward shift when the body is centred on the position.
var _current: StringName = &""
var _direction: int = 0
var _facing_angle: float = 0.0
var _time: float = 0.0
var _finished: bool = false


func _init() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_time += delta * speed_scale
	var duration: float = float(_sheet.frame_count(_current)) / _sheet.fps(_current)
	if not _sheet.loops(_current) and _time >= duration:
		_finished = true
		set_process(false)
		queue_redraw()
		animation_finished.emit(_current)
		return
	queue_redraw()


func _draw() -> void:
	if _sheet == null or _current == &"":
		return
	var tex: Texture2D = _sheet.texture(_current)
	var cell: Vector2i = _sheet.cell_of(_current)
	var src := Rect2(_frame() * cell.x, _direction * cell.y, cell.x, cell.y)
	var dest := Rect2(-_sheet.anchor_of(_current) * _scale + Vector2(0.0, _body_shift_y), Vector2(cell) * _scale)
	draw_texture_rect_region(tex, dest, src, tint)


## Sets the sheet to draw and the on-screen height in pixels of the whole
## root cell. Stops any running animation. Keeps the last facing angle and
## re-applies it to the new sheet's direction count. With [param center_body]
## the image is shifted down so that the vertical middle of the root cell sits on
## the node position (the body is then centred on the collision shape); the
## default keeps the feet anchored (decor).
func setup(sheet: SpriteSheet, height_px: float, center_body: bool = false) -> void:
	_sheet = sheet
	_scale = height_px / float(sheet.cell.y)
	_body_shift_y = (sheet.anchor.y - sheet.cell.y * 0.5) * _scale if center_body else 0.0
	_current = &""
	_time = 0.0
	_finished = false
	_direction = SpriteSheet.direction_index(_facing_angle, sheet.directions)
	set_process(false)
	queue_redraw()


## Plays [param anim_name]. Does nothing if it already plays, unless
## [param restart] is true. Unknown names are reported and ignored.
func play(anim_name: StringName, restart: bool = false) -> void:
	if _sheet == null or not _sheet.has_animation(anim_name):
		push_error("DirectionalSprite: unknown animation '%s'." % anim_name)
		return
	if anim_name == _current and not restart:
		return
	_current = anim_name
	speed_scale = 1.0
	_time = 0.0
	_finished = false
	set_process(not _sheet.loops(anim_name) or _sheet.frame_count(anim_name) > 1)
	queue_redraw()


## Name of the current animation ([code]&""[/code] before the first play).
func current() -> StringName:
	return _current


## Turns toward [param angle] (radians, as [method Vector2.angle]).
func set_facing(angle: float) -> void:
	_facing_angle = angle
	if _sheet == null:
		return
	var index: int = SpriteSheet.direction_index(angle, _sheet.directions)
	if index != _direction:
		_direction = index
		queue_redraw()


func _frame() -> int:
	var count: int = _sheet.frame_count(_current)
	var raw: int = int(_time * _sheet.fps(_current))
	if _sheet.loops(_current):
		return raw % count
	return mini(raw, count - 1)
