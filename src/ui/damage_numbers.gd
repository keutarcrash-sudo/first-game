## Floating damage numbers above the enemies: draws what [DamageNumberModel] holds,
## in Bangers with a black outline, in real time (not slowed by the hit-stop).
## Enemies report the damage really removed; everything is cleared as soon as the
## phase leaves COMBAT (end of wave, build, card choice, map).
class_name DamageNumbers
extends Node2D

## Above the enemies, the bullets and the combo effects (none of them set a z_index).
const Z_INDEX_ABOVE_EFFECTS := 50

var _model: DamageNumberModel
var _font: Font
var _drawn: Array[Dictionary] = []


## Gives the node its [param model] and clears it whenever [param state] leaves COMBAT.
## Call once, before or right after adding the node to the tree.
func setup(model: DamageNumberModel, state: GameState) -> void:
	_model = model
	state.phase_changed.connect(_on_phase_changed)
	set_process(model.enabled)  # Switched off: no cost at all.


func _ready() -> void:
	z_index = Z_INDEX_ABOVE_EFFECTS
	_font = NeonFonts.title()


func _process(_delta: float) -> void:
	if _model == null:
		return
	_model.advance(_now())
	var had_numbers: bool = not _drawn.is_empty()
	_drawn = _model.numbers()
	if had_numbers or not _drawn.is_empty():
		queue_redraw()  # One more redraw after the last number goes, to erase it.


func _draw() -> void:
	if _font == null:
		return
	for n: Dictionary in _drawn:
		var text: String = n["text"]
		var size: int = n["font_size"]
		var color: Color = n["color"]
		var a: float = _model.alpha(float(n["age"]))
		var width: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var at: Vector2 = (n["position"] as Vector2) - Vector2(width * 0.5, 0.0)
		draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, NeonFonts.OUTLINE_SIZE, Color(0.0, 0.0, 0.0, a))
		draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color, a))


## Reports [param amount] damage really removed from [param enemy] (after Combustion).
## [param source]: &"hero", &"cannon", &"burn" or &"area"; [param crit] shows it in yellow with « ! ».
func report(enemy: Node2D, amount: float, source: StringName, crit: bool) -> void:
	if _model == null or not _model.enabled or amount <= 0.0:
		return
	_model.report(enemy.get_instance_id(), _head_position(enemy), amount, source, crit, _now())


## [param enemy] dies: its pending burn or area sum is shown now instead of being lost.
func flush(enemy: Node2D) -> void:
	if _model == null or not _model.enabled:
		return
	_model.flush(enemy.get_instance_id(), _head_position(enemy), _now())


## Just above the enemy's body, in this node's space.
func _head_position(enemy: Node2D) -> Vector2:
	var lift: float = (enemy as Enemy).radius() if enemy is Enemy else 0.0
	return to_local(enemy.global_position) - Vector2(0.0, lift)


## Real time in seconds: the hit-stop slows the game clock, not this one.
func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _on_phase_changed(phase: GameState.Phase) -> void:
	if phase != GameState.Phase.COMBAT and _model != null:
		_model.clear()
		_drawn.clear()
		queue_redraw()  # Erase now: a paused tree (defeat) would not run _process.
