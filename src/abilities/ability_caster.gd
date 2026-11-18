## Casts the active abilities of the chosen specialization (étape 3a): right click,
## A, E and R, in COMBAT only. Owns the cooldowns. An ability type not handled in
## [method _cast] does nothing. Display listens to [signal cooldowns_changed].
class_name AbilityCaster
extends Node

## Emitted when a cooldown changes its displayed second, and after a cast.
signal cooldowns_changed

const FIRE_COLOR := Color(1.0, 0.55, 0.15)

const ACTIONS := {
	&"primary": &"ability_primary",
	&"a": &"ability_a",
	&"e": &"ability_e",
	&"r": &"ability_r",
}

var _state: GameState
var _hero: Hero
var _enemies: Node2D
var _bullets: Node2D
var _field_rect: Rect2
var _modifiers: PlayerModifiers
var _rules: ProcRules
var _abilities: Dictionary = {}  # { slot: AbilityDef }
var _cooldowns: Dictionary = {}  # { slot: seconds left }
var _unlocked: Dictionary = {}  # { slot: true } for the slots that can be cast
var _wet_dash_radius := 0.0  # > 0 while a dash_wet jump is in progress.
var _wet_dash_done: Dictionary = {}  # { enemy instance id: true } already soaked by this jump


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


## Sets the abilities of the chosen specialization, [code]{ slot: AbilityDef }[/code].
## All start ready, except A, E and R which start locked (the right click is open).
func equip(abilities: Dictionary) -> void:
	_abilities = abilities
	_cooldowns.clear()
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


func _unhandled_input(event: InputEvent) -> void:
	if _state == null or _state.phase != GameState.Phase.COMBAT:
		return
	for slot: StringName in ACTIONS:
		if not event.is_action_pressed(ACTIONS[slot]):
			continue
		var def: AbilityDef = ability(slot)
		if def == null or not is_unlocked(slot) or cooldown_left(slot) > 0.0:
			return
		_cast(def)
		_cooldowns[slot] = def.cooldown
		get_viewport().set_input_as_handled()
		cooldowns_changed.emit()
		return


func _physics_process(delta: float) -> void:
	if _wet_dash_radius > 0.0:
		_soak_near_hero()
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


func _cast(def: AbilityDef) -> void:
	match def.type:
		"piercing_arrow":
			_cast_piercing_arrow(def)
		"fireball":
			_cast_fireball(def)
		"water_wave":
			_cast_water_wave(def)


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
	zone.setup_segment(start, _hero.global_position, float(def.values["trail_width"]), float(def.values["trail_duration"]), FIRE_COLOR, _field_rect, _enemies)
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
	fireball.setup(def, _direction_to_mouse(), _field_rect, _enemies, float(def.values["damage"]) * _modifiers.damage_multiplier(), burn_duration, burn_dps)
	_bullets.add_child(fireball)
	fireball.global_position = _hero.global_position


func _cast_water_wave(def: AbilityDef) -> void:
	var weapon: ElementalWeapon = _hero.elemental_weapon()
	var wet_duration: float = weapon.wet_duration() if weapon != null else 0.0
	var wave := WaterWave.new()
	wave.setup(def, _direction_to_mouse(), _enemies, float(def.values["damage"]) * _modifiers.damage_multiplier(), wet_duration, _field_rect)
	_bullets.add_child(wave)
	wave.global_position = _hero.global_position


func _cast_piercing_arrow(def: AbilityDef) -> void:
	var to_mouse: Vector2 = _hero.get_global_mouse_position() - _hero.global_position
	var direction: Vector2 = to_mouse.normalized() if to_mouse != Vector2.ZERO else Vector2.RIGHT
	var weapon: ArcherWeapon = _hero.archer_weapon()
	var mark: float = weapon.mark_duration() if weapon != null else 0.0
	var arrow := PiercingArrow.new()
	arrow.setup(def, direction, _field_rect, float(def.values["damage"]) * _modifiers.damage_multiplier(), mark)
	_bullets.add_child(arrow)
	arrow.global_position = _hero.global_position
