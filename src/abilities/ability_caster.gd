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

var _state: GameState
var _hero: Hero
var _enemies: Node2D
var _bullets: Node2D
var _field_rect: Rect2
var _modifiers: PlayerModifiers
var _rules: ProcRules
var _abilities: Dictionary = {}  # { slot: AbilityDef }
var _cooldowns: Dictionary = {}  # { slot: seconds left }


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


## Sets the abilities of the chosen specialization, [code]{ slot: AbilityDef }[/code]. All start ready.
func equip(abilities: Dictionary) -> void:
	_abilities = abilities
	_cooldowns.clear()
	for slot: StringName in abilities:
		_cooldowns[slot] = 0.0
	cooldowns_changed.emit()


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
		if def == null or cooldown_left(slot) > 0.0:
			return
		_cast(def)
		_cooldowns[slot] = def.cooldown
		get_viewport().set_input_as_handled()
		cooldowns_changed.emit()
		return


func _physics_process(delta: float) -> void:
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
