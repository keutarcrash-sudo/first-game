## Screen shake and hit-stop (passe graphique 1). One instance, created by main.gd.
## The shake moves the camera through [method GameCamera.set_shake_offset]; the
## strongest active shake wins and it fades out over its duration. The hit-stop
## sets [code]Engine.time_scale[/code] for a duration of REAL seconds and is
## ignored outside COMBAT or while the tree is paused. The time scale is always
## put back to 1.0 on leaving COMBAT and when this node leaves the tree.
class_name ImpactFeedback
extends Node

var _stats: ImpactStats
var _camera: GameCamera
var _state: GameState
var _rng := RandomNumberGenerator.new()
var _shake_strength := 0.0
var _shake_duration := 0.0
var _shake_end := 0.0  # Real time (seconds) at which the active shake ends.
var _hitstop_active := false
var _last_hitstop := -INF  # Real time (seconds) of the last accepted hit-stop.
var _hitstop_id := 0  # Tells a stale hit-stop timer from the current one.
var _crystal_hp := -1.0


## Gives the values, the camera to shake and the game state (phase).
func setup(stats: ImpactStats, camera: GameCamera, state: GameState) -> void:
	_stats = stats
	_camera = camera
	_state = state
	# Keeps fading the shake while the tree is paused (defeat), so it never stays stuck.
	process_mode = Node.PROCESS_MODE_ALWAYS
	state.phase_changed.connect(_on_phase_changed.unbind(1))


## Listens to the enemies added under [param enemies_parent]: a heavy kill
## ([signal Enemy.died_heavy]) triggers a hit-stop and a small shake.
func watch_enemies(enemies_parent: Node) -> void:
	enemies_parent.child_entered_tree.connect(_on_enemy_added)


## Small shake each time [param crystal] loses hit points.
func watch_crystal(crystal: Crystal) -> void:
	_crystal_hp = crystal.current_hp
	crystal.health_changed.connect(_on_crystal_health_changed)


## Shakes the screen: [param kind] is [code]&"small"[/code] or [code]&"big"[/code]. The strongest active shake wins.
func shake(kind: StringName) -> void:
	if _stats == null or not _stats.has_shake(kind):
		push_error("ImpactFeedback: unknown shake '%s'." % kind)
		return
	var strength: float = _stats.shake_strength(kind)
	if _is_shaking() and strength < _current_strength():
		return
	_shake_strength = strength
	_shake_duration = _stats.shake_duration(kind)
	_shake_end = _now() + _shake_duration


## Slows the game for a very short real time. Does nothing when one is already
## running, outside COMBAT, when the tree is paused, or when the previous one
## started less than [code]min_interval[/code] real seconds ago.
func hitstop() -> void:
	if _stats == null or _hitstop_active or _state.phase != GameState.Phase.COMBAT:
		return
	var tree: SceneTree = get_tree()
	if tree == null or tree.paused:
		return
	if _now() - _last_hitstop < _stats.hitstop_min_interval:
		return
	_last_hitstop = _now()
	_hitstop_active = true
	_hitstop_id += 1
	Engine.time_scale = _stats.hitstop_time_scale
	# always_process, physics = false, ignore_time_scale = true: counts real seconds.
	tree.create_timer(_stats.hitstop_duration, true, false, true).timeout.connect(_end_hitstop.bind(_hitstop_id))


func _process(_delta: float) -> void:
	if _hitstop_active and get_tree().paused:
		_restore_time_scale()
	if _camera == null:
		return
	if not _is_shaking():
		if _shake_strength > 0.0:
			_shake_strength = 0.0
			_camera.set_shake_offset(Vector2.ZERO)
		return
	var amplitude: float = _current_strength()
	_camera.set_shake_offset(Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * amplitude)


func _exit_tree() -> void:
	_restore_time_scale()


func _on_phase_changed() -> void:
	if _state.phase == GameState.Phase.COMBAT:
		return
	_restore_time_scale()
	_shake_strength = 0.0
	if _camera != null:
		_camera.set_shake_offset(Vector2.ZERO)


func _on_enemy_added(node: Node) -> void:
	var enemy := node as Enemy
	if enemy != null:
		enemy.died_heavy.connect(_on_enemy_died_heavy)


func _on_enemy_died_heavy() -> void:
	hitstop()
	shake(&"small")


func _on_crystal_health_changed(current_hp: float, _max_hp: float) -> void:
	if current_hp < _crystal_hp:
		shake(&"small")
	_crystal_hp = current_hp


func _end_hitstop(id: int) -> void:
	if id == _hitstop_id:
		_restore_time_scale()


func _restore_time_scale() -> void:
	_hitstop_active = false
	Engine.time_scale = 1.0


func _is_shaking() -> bool:
	return _shake_strength > 0.0 and _now() < _shake_end


## Strength left: fades linearly to 0 over the shake's duration.
func _current_strength() -> float:
	return _shake_strength * clampf((_shake_end - _now()) / _shake_duration, 0.0, 1.0)


## Real time in seconds (not slowed by the hit-stop).
func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
