## Casts the active abilities of the chosen specialization (étape 3a): right click,
## A, E and R, in COMBAT only. Owns the cooldowns. An ability type not handled in
## [method _cast] does nothing. Display listens to [signal cooldowns_changed].
class_name AbilityCaster
extends Node

## Emitted when a cooldown changes its displayed second, and after a cast.
signal cooldowns_changed

const ACTIONS := {
	&"primary": &"ability_primary",
	&"a": &"ability_a",
	&"e": &"ability_e",
	&"r": &"ability_r",
}

const ARROW_RAIN_COLOR := Color(1.0, 0.95, 0.6)
const PUDDLE_COLOR := Color(0.55, 0.85, 1.0)
const HUNTER_EYE_COLOR := Color(1.0, 0.9, 0.1)
const HUNTER_EYE_RING_GAP := 8.0  # Pixels between the hero's body and the yellow outline.
const HUNTER_EYE_RING_WIDTH := 3.0
const HUNTER_EYE_RING_POINTS := 32
const TIDAL_FLASH_COLOR := Color(0.55, 0.85, 1.0, 0.6)
const TIDAL_FLASH_DURATION := 0.3
const BURST_RADIUS := 55.0  # Star size of the ability onomatopoeias.
const BURST_BIG_RADIUS := 90.0  # Star size of the tidal wave.
const BURST_ARROW_OFFSET := 50.0  # Pixels in front of the hero for the piercing arrow burst.
const BURST_EYE_OFFSET := 30.0  # Pixels above the hero's body for the hunter eye burst.
const BURST_WAVE_RATIO := 0.5  # The wave burst sits at this fraction of its range.
const ARCHER_BURST_COLOR := Color(1.0, 0.89, 0.23)
const FIRE_BURST_COLOR := Color(1.0, 0.54, 0.12)
const WATER_BURST_COLOR := Color(0.1, 0.89, 1.0)

var _state: GameState
var _hero: Hero
var _enemies: Node2D
var _bullets: Node2D
var _field_rect: Rect2
var _modifiers: PlayerModifiers
var _rules: ProcRules
var _abilities: Dictionary = {}  # { slot: AbilityDef }
var _cooldowns: Dictionary = {}  # { slot: seconds left }
var _cooldown_totals: Dictionary = {}  # { slot: full cooldown (cards included) set at the last cast }
var _unlocked: Dictionary = {}  # { slot: true } for the slots that can be cast
var _wet_dash_radius := 0.0  # > 0 while a dash_wet jump is in progress.
var _wet_dash_done: Dictionary = {}  # { enemy instance id: true } already soaked by this jump
var _eye_left := 0.0  # Seconds of Œil du chasseur remaining; 0 = not active.
var _impact: ImpactFeedback  # Optional: shake and hit-stop for fireball and meteor.
var _eye_ring: Node2D  # Yellow outline around the hero while the eye is active.


## Gives the caster what the abilities need: [param bullets] is where projectiles are
## added, [param enemies] the enemies' parent, [param field_rect] the field.
func setup(state: GameState, hero: Hero, enemies: Node2D, bullets: Node2D, field_rect: Rect2, modifiers: PlayerModifiers, rules: ProcRules) -> void:
	_state = state
	_hero = hero
	_enemies = enemies
	_bullets = bullets
	_field_rect = field_rect
	_modifiers = modifiers
	_rules = rules
	state.phase_changed.connect(_on_phase_changed)


## Gives the caster the feedback node handed to the explosions (fireball, meteor). Optional.
func set_impact(impact: ImpactFeedback) -> void:
	_impact = impact


## Sets the abilities of the chosen specialization, [code]{ slot: AbilityDef }[/code].
## All start ready, except A, E and R which start locked (the right click is open).
func equip(abilities: Dictionary) -> void:
	_abilities = abilities
	_cooldowns.clear()
	_cooldown_totals.clear()
	_unlocked.clear()
	for slot: StringName in abilities:
		_cooldowns[slot] = 0.0
		if not AbilityCatalog.UNLOCK_SLOTS.has(slot):
			_unlocked[slot] = true
	cooldowns_changed.emit()


## True when the ability in [param slot] exists and can be cast (not locked).
func is_unlocked(slot: StringName) -> bool:
	return _unlocked.has(slot)


## Unlocks the ability in [param slot] (ready at once). Does nothing when there is none.
func unlock(slot: StringName) -> void:
	if not _abilities.has(slot):
		return
	_unlocked[slot] = true
	cooldowns_changed.emit()


## The first of A, E, R that exists and is still locked; [code]&""[/code] when none.
func next_locked_slot() -> StringName:
	for slot: StringName in AbilityCatalog.UNLOCK_SLOTS:
		if _abilities.has(slot) and not _unlocked.has(slot):
			return slot
	return &""


## The ability in [param slot], or [code]null[/code] when there is none.
func ability(slot: StringName) -> AbilityDef:
	return _abilities.get(slot) as AbilityDef


## Seconds left before the ability in [param slot] can be cast again (0 when ready or absent).
func cooldown_left(slot: StringName) -> float:
	return float(_cooldowns.get(slot, 0.0))


## Full cooldown of [param slot] as set at its last cast (cards included), so a clock
## can start full; 0 when it was never cast since [method equip].
func cooldown_total(slot: StringName) -> float:
	return float(_cooldown_totals.get(slot, 0.0))


## True while the game is in COMBAT, the only phase where cooldowns run.
func is_in_combat() -> bool:
	return _state != null and _state.phase == GameState.Phase.COMBAT


## Leaving COMBAT cancels a jump in progress and its pending effects (flame trail, soaking).
func _on_phase_changed(phase: GameState.Phase) -> void:
	if phase == GameState.Phase.COMBAT:
		return
	if _hero != null:
		_hero.cancel_dash()
		for connection: Dictionary in _hero.dash_finished.get_connections():
			_hero.dash_finished.disconnect(connection["callable"])
	_wet_dash_radius = 0.0
	_wet_dash_done.clear()
	_end_hunter_eye()
	if _hero != null and _hero.archer_weapon() != null:
		_hero.archer_weapon().clear_forced_crit()  # A pending Roulade crit does not outlive the combat.


func _unhandled_input(event: InputEvent) -> void:
	if _state == null or _state.phase != GameState.Phase.COMBAT:
		return
	for slot: StringName in ACTIONS:
		if not event.is_action_pressed(ACTIONS[slot]):
			continue
		if _hero != null and _hero.is_dashing():
			return  # No cast, no cooldown, input not consumed while jumping.
		var def: AbilityDef = ability(slot)
		if def == null or not is_unlocked(slot) or cooldown_left(slot) > 0.0:
			return
		_cast(def)
		_cooldowns[slot] = def.cooldown * _modifiers.ability_cooldown_factor(def.id)
		_cooldown_totals[slot] = _cooldowns[slot]
		get_viewport().set_input_as_handled()
		cooldowns_changed.emit()
		return


func _physics_process(delta: float) -> void:
	if _wet_dash_radius > 0.0:
		_soak_near_hero()
	if _eye_left > 0.0:
		_tick_hunter_eye(delta)
	if _state == null or _state.phase != GameState.Phase.COMBAT:
		return
	var changed := false
	for slot: StringName in _cooldowns:
		var before: float = _cooldowns[slot]
		if before <= 0.0:
			continue
		var after: float = maxf(before - delta, 0.0)
		_cooldowns[slot] = after
		if ceili(after) != ceili(before):
			changed = true
	if changed:
		cooldowns_changed.emit()


## Casts [param base_def] with its numeric values and cooldown read through the cards ([method PlayerModifiers.ability_value]).
func _cast(base_def: AbilityDef) -> void:
	var def: AbilityDef = _with_card_values(base_def)
	match def.type:
		"piercing_arrow":
			_cast_piercing_arrow(def)
		"fireball":
			_cast_fireball(def)
		"water_wave":
			_cast_water_wave(def)
		"arrow_rain":
			_cast_arrow_rain(def)
		"fire_wall":
			_cast_fire_wall(def)
		"puddle":
			_cast_puddle(def)
		"dash_crit":
			_cast_dash_crit(def)
		"dash_fire_trail":
			_cast_dash_fire_trail(def)
		"dash_wet":
			_cast_dash_wet(def)
		"hunter_eye":
			_cast_hunter_eye(def)
		"meteor":
			_cast_meteor(def)
		"tidal_wave":
			_cast_tidal_wave(def)


## A copy of [param def] whose values include the card bonuses at the time of the cast.
func _with_card_values(def: AbilityDef) -> AbilityDef:
	var copy := AbilityDef.new()
	copy.id = def.id
	copy.spec_id = def.spec_id
	copy.slot = def.slot
	copy.display_name = def.display_name
	copy.description = def.description
	copy.cooldown = def.cooldown
	copy.type = def.type
	for key: String in def.values:
		copy.values[key] = _modifiers.ability_value(def.id, key, float(def.values[key]))
	return copy


## The mouse position brought back to [param max_range] from the hero, then into the field
## shrunk by [param margin] on every side, so a zone of that half-size stays inside the field.
func _target_point(max_range: float, margin: float) -> Vector2:
	var origin: Vector2 = _hero.global_position
	var point: Vector2 = _hero.get_global_mouse_position()
	if point.distance_to(origin) > max_range:
		point = origin + (point - origin).normalized() * max_range
	var low: Vector2 = _field_rect.position + Vector2(margin, margin)
	var high: Vector2 = _field_rect.end - Vector2(margin, margin)
	# A field smaller than the zone: aim at its centre.
	var centre: Vector2 = _field_rect.get_center()
	var x: float = clampf(point.x, low.x, high.x) if low.x <= high.x else centre.x
	var y: float = clampf(point.y, low.y, high.y) if low.y <= high.y else centre.y
	return Vector2(x, y)


func _cast_arrow_rain(def: AbilityDef) -> void:
	var radius: float = float(def.values["radius"])
	var zone := GroundZone.new()
	zone.setup_circle(radius, float(def.values["duration"]), ARROW_RAIN_COLOR, _state, _enemies)
	# One tick counter per zone, shared by all the enemies it hits.
	var tick := {"left": 0.0, "frame": -1, "fire": false}
	zone.enemy_inside.connect(_on_arrow_rain_enemy_inside.bind(tick, float(def.values["tick_interval"]), float(def.values["damage"])))
	_bullets.add_child(zone)
	zone.global_position = _target_point(float(def.values["max_range"]), radius)
	_burst(zone.global_position, "ZIP ZIP !", ARCHER_BURST_COLOR, BURST_RADIUS, &"small")


## Hits every enemy in the zone for [param damage] each [param interval] seconds (first hit at once).
func _on_arrow_rain_enemy_inside(enemy: Enemy, delta: float, tick: Dictionary, interval: float, damage: float) -> void:
	var frame: int = Engine.get_physics_frames()
	if tick["frame"] != frame:
		tick["frame"] = frame
		tick["left"] = float(tick["left"]) - delta
		tick["fire"] = float(tick["left"]) <= 0.0
		if tick["fire"]:
			tick["left"] = float(tick["left"]) + interval
	if tick["fire"]:
		enemy.take_damage(damage * _modifiers.hero_damage_multiplier(), true, &"area")  # Summed per enemy on screen.


func _cast_fire_wall(def: AbilityDef) -> void:
	var half: float = float(def.values["length"]) * 0.5
	var centre: Vector2 = _target_point(float(def.values["max_range"]), half)
	var aim: Vector2 = centre - _hero.global_position
	var direction: Vector2 = aim.normalized() if aim != Vector2.ZERO else _direction_to_mouse()
	var along := Vector2(-direction.y, direction.x) * half
	var zone := GroundZone.new()
	zone.setup_segment(centre - along, centre + along, float(def.values["thickness"]), float(def.values["duration"]), Hero.FIRE_BOLT_COLOR, _state, _enemies)
	zone.enemy_inside.connect(_on_trail_enemy_inside)  # Same burn as the flame trail.
	_bullets.add_child(zone)
	_burst(centre, "FWOOSH !", FIRE_BURST_COLOR, BURST_RADIUS, &"small")


func _cast_puddle(def: AbilityDef) -> void:
	var radius: float = float(def.values["radius"])
	var zone := GroundZone.new()
	zone.setup_circle(radius, float(def.values["duration"]), PUDDLE_COLOR, _state, _enemies)
	zone.enemy_inside.connect(_on_puddle_enemy_inside.bind(float(def.values["slow_factor"])))
	_bullets.add_child(zone)
	zone.global_position = _target_point(float(def.values["max_range"]), radius)
	_burst(zone.global_position, "PLOUF !", WATER_BURST_COLOR, BURST_RADIUS)


func _on_puddle_enemy_inside(enemy: Enemy, _delta: float, slow_factor: float) -> void:
	var weapon: ElementalWeapon = _hero.elemental_weapon()
	if weapon != null:
		enemy.apply_wet(weapon.wet_duration())
	enemy.apply_slow(slow_factor)


func _direction_to_mouse() -> Vector2:
	var to_mouse: Vector2 = _hero.get_global_mouse_position() - _hero.global_position
	return to_mouse.normalized() if to_mouse != Vector2.ZERO else Vector2.RIGHT


## Direction of a jump: the movement keys if held, else toward the mouse.
func _dash_direction() -> Vector2:
	var move: Vector2 = _hero.move_direction()
	return move.normalized() if move != Vector2.ZERO else _direction_to_mouse()


func _cast_dash_crit(def: AbilityDef) -> void:
	if _hero.is_dashing():
		return
	_hero.dash(_dash_direction(), float(def.values["distance"]), float(def.values["duration"]))
	var weapon: ArcherWeapon = _hero.archer_weapon()
	if weapon != null:
		weapon.force_next_crit()


func _cast_dash_fire_trail(def: AbilityDef) -> void:
	if _hero.is_dashing():
		return
	var start: Vector2 = _hero.global_position
	_hero.dash_finished.connect(_on_fire_dash_finished.bind(start, def), CONNECT_ONE_SHOT)
	_hero.dash(_dash_direction(), float(def.values["distance"]), float(def.values["duration"]))


func _on_fire_dash_finished(start: Vector2, def: AbilityDef) -> void:
	var zone := GroundZone.new()
	zone.setup_segment(start, _hero.global_position, float(def.values["trail_width"]), float(def.values["trail_duration"]), Hero.FIRE_BOLT_COLOR, _state, _enemies)
	zone.enemy_inside.connect(_on_trail_enemy_inside)
	_bullets.add_child(zone)


func _on_trail_enemy_inside(enemy: Enemy, _delta: float) -> void:
	var weapon: ElementalWeapon = _hero.elemental_weapon()
	if weapon == null:
		return
	enemy.apply_burn(weapon.burn_duration(), weapon.burn_damage_per_second())


func _cast_dash_wet(def: AbilityDef) -> void:
	if _hero.is_dashing():
		return
	_wet_dash_radius = float(def.values["wet_radius"])
	_wet_dash_done.clear()
	_hero.dash_finished.connect(_on_wet_dash_finished, CONNECT_ONE_SHOT)
	_hero.dash(_dash_direction(), float(def.values["distance"]), float(def.values["duration"]))
	_soak_near_hero()


func _on_wet_dash_finished() -> void:
	_soak_near_hero()
	_wet_dash_radius = 0.0
	_wet_dash_done.clear()


## Soaks, once each, the enemies within the jump's wet radius of the hero.
func _soak_near_hero() -> void:
	var weapon: ElementalWeapon = _hero.elemental_weapon()
	if weapon == null or _enemies == null:
		return
	for child: Node in _enemies.get_children():
		var enemy := child as Enemy
		if enemy == null or enemy.is_queued_for_deletion() or _wet_dash_done.has(enemy.get_instance_id()):
			continue
		if enemy.global_position.distance_to(_hero.global_position) <= _wet_dash_radius + enemy.radius():
			_wet_dash_done[enemy.get_instance_id()] = true
			enemy.apply_wet(weapon.wet_duration())


func _cast_fireball(def: AbilityDef) -> void:
	var weapon: ElementalWeapon = _hero.elemental_weapon()
	var burn_duration: float = weapon.burn_duration() if weapon != null else 0.0
	var burn_dps: float = weapon.burn_damage_per_second() if weapon != null else 0.0
	var fireball := Fireball.new()
	fireball.setup(def, _direction_to_mouse(), _field_rect, _enemies, float(def.values["damage"]) * _modifiers.hero_damage_multiplier(), burn_duration, burn_dps)
	fireball.set_impact(_impact)
	_bullets.add_child(fireball)
	fireball.global_position = _hero.global_position


func _cast_water_wave(def: AbilityDef) -> void:
	var weapon: ElementalWeapon = _hero.elemental_weapon()
	var wet_duration: float = weapon.wet_duration() if weapon != null else 0.0
	var wave := WaterWave.new()
	wave.setup(def, _direction_to_mouse(), _enemies, float(def.values["damage"]) * _modifiers.hero_damage_multiplier(), wet_duration, _field_rect)
	_bullets.add_child(wave)
	wave.global_position = _hero.global_position
	var direction: Vector2 = _direction_to_mouse()
	_burst(_hero.global_position + direction * float(def.values["range"]) * BURST_WAVE_RATIO, "SPLASH !", WATER_BURST_COLOR, BURST_RADIUS, &"small")


func _cast_piercing_arrow(def: AbilityDef) -> void:
	var to_mouse: Vector2 = _hero.get_global_mouse_position() - _hero.global_position
	var direction: Vector2 = to_mouse.normalized() if to_mouse != Vector2.ZERO else Vector2.RIGHT
	var weapon: ArcherWeapon = _hero.archer_weapon()
	var mark: float = weapon.mark_duration() if weapon != null else 0.0
	var arrow := PiercingArrow.new()
	arrow.setup(def, direction, _field_rect, float(def.values["damage"]) * _modifiers.hero_damage_multiplier(), mark)
	_bullets.add_child(arrow)
	arrow.global_position = _hero.global_position
	_burst(_hero.global_position + direction * BURST_ARROW_OFFSET, "TCHAK !", ARCHER_BURST_COLOR, BURST_RADIUS, &"small")


## Enemies alive inside the rectangle the camera shows now (the viewport rectangle
## brought back to world space by the inverse canvas transform).
func _enemies_on_screen() -> Array[Enemy]:
	var result: Array[Enemy] = []
	if _enemies == null or not is_inside_tree():
		return result
	var viewport := get_viewport()
	var screen_rect: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	for child: Node in _enemies.get_children():
		var enemy := child as Enemy
		if enemy != null and not enemy.is_queued_for_deletion() and screen_rect.has_point(enemy.global_position):
			result.append(enemy)
	return result


## Œil du chasseur: every normal shot is critical and every enemy on screen stays marked
## for [code]duration[/code] seconds. Casting again restarts the timer.
func _cast_hunter_eye(def: AbilityDef) -> void:
	var weapon: ArcherWeapon = _hero.archer_weapon()
	if weapon != null:
		weapon.set_always_crit(true)
	_eye_left = float(def.values["duration"])
	if _eye_ring == null or not is_instance_valid(_eye_ring):
		_eye_ring = Node2D.new()
		_eye_ring.draw.connect(_draw_eye_ring)
		_hero.add_child(_eye_ring)
	_mark_on_screen()
	_burst(_hero.global_position + Vector2(0.0, -(_hero.body_radius() + BURST_EYE_OFFSET)), "FOCUS !", ARCHER_BURST_COLOR, BURST_RADIUS)


func _draw_eye_ring() -> void:
	_eye_ring.draw_arc(Vector2.ZERO, _hero.body_radius() + HUNTER_EYE_RING_GAP, 0.0, TAU, HUNTER_EYE_RING_POINTS, HUNTER_EYE_COLOR, HUNTER_EYE_RING_WIDTH)


func _tick_hunter_eye(delta: float) -> void:
	if _state == null or _state.phase != GameState.Phase.COMBAT:
		_end_hunter_eye()
		return
	_eye_left -= delta
	if _eye_left <= 0.0:
		_end_hunter_eye()
		return
	_mark_on_screen()


## Marks the enemies on screen for the time the eye has left (refreshed every frame).
func _mark_on_screen() -> void:
	for enemy: Enemy in _enemies_on_screen():
		enemy.extend_mark(_eye_left)


func _end_hunter_eye() -> void:
	_eye_left = 0.0
	if _hero != null:
		var weapon: ArcherWeapon = _hero.archer_weapon()
		if weapon != null:
			weapon.set_always_crit(false)
	if _eye_ring != null and is_instance_valid(_eye_ring):
		_eye_ring.queue_free()
	_eye_ring = null


func _cast_meteor(def: AbilityDef) -> void:
	var radius: float = float(def.values["radius"])
	var weapon: ElementalWeapon = _hero.elemental_weapon()
	var burn_duration: float = weapon.burn_duration() if weapon != null else 0.0
	var burn_dps: float = weapon.burn_damage_per_second() if weapon != null else 0.0
	var meteor := Meteor.new()
	meteor.setup(_state, radius, float(def.values["delay"]), float(def.values["damage"]) * _modifiers.hero_damage_multiplier(), burn_duration, burn_dps, _enemies)
	meteor.set_impact(_impact)
	_bullets.add_child(meteor)
	meteor.global_position = _target_point(float(def.values["max_range"]), radius)


## Raz-de-marée: soaks then freezes every enemy on screen, with a short light-blue flash.
func _cast_tidal_wave(def: AbilityDef) -> void:
	var weapon: ElementalWeapon = _hero.elemental_weapon()
	var wet_duration: float = weapon.wet_duration() if weapon != null else 0.0
	var freeze_duration: float = float(def.values["freeze_duration"])
	for enemy: Enemy in _enemies_on_screen():
		enemy.apply_wet(wet_duration)
		enemy.force_freeze(freeze_duration)
	_flash_screen()
	_burst(_hero.global_position, "SPLOOSH !", WATER_BURST_COLOR, BURST_BIG_RADIUS, &"big", true)


## A full-screen colour that fades out, on its own CanvasLayer (screen space).
func _flash_screen() -> void:
	var layer := CanvasLayer.new()
	var rect := ColorRect.new()
	rect.color = TIDAL_FLASH_COLOR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	layer.process_mode = Node.PROCESS_MODE_ALWAYS  # Fades and frees even if the tree pauses (defeat).
	add_child(layer)
	var tween := layer.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(rect, "modulate:a", 0.0, TIDAL_FLASH_DURATION)
	tween.tween_callback(layer.queue_free)


## Comic burst with [param word] at [param at]; optionally shakes the screen
## ([param shake_kind], empty = none) and triggers a hit-stop ([param stop]).
func _burst(at: Vector2, word: String, color: Color, radius: float, shake_kind: StringName = &"", stop: bool = false) -> void:
	PopBurst.spawn(_bullets, at, word, color, radius)
	if _impact == null:
		return
	if shake_kind != &"":
		_impact.shake(shake_kind)
	if stop:
		_impact.hitstop()
