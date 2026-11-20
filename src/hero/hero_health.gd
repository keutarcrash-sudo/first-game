## The hero's hit points (étape 4, design/gdd étape 4 spec §5). Pure logic, no node:
## a hit removes hit points and starts a short invulnerability; a jump (dash) is
## invulnerable too; at 0 the hero is dead, once, unless a rescue is armed
## ([method arm_rescue], item « Seconde chance », étape 5a spec §8). Regeneration is 0 unless a card
## sets it with [method set_regen] (there is no automatic healing).
class_name HeroHealth
extends RefCounted

## Emitted when the hit points or the maximum change.
signal changed(current: float, max_hp: float)
## Emitted once, when the hit points reach 0.
signal died
## Emitted once, when an armed rescue saves the hero from a fatal hit (instead of [signal died]).
signal rescued

## Current hit points (0 = dead).
var current: float
## Maximum hit points.
var max_hp: float

var _invulnerability := 0.0  # Seconds of invulnerability granted by a hit.
var _invulnerable_left := 0.0
var _regen_per_second := 0.0
var _regen_active := false
var _dead := false
var _rescue_fraction := 0.0  # Share of max_hp given back by the rescue.
var _rescue_armed := false
var _rescue_used := false


## Starts full at [param max_hp]; a hit grants [param invulnerability] seconds of protection.
func _init(max_hp: float, invulnerability: float) -> void:
	self.max_hp = max_hp
	current = max_hp
	_invulnerability = invulnerability


## Applies a hit of [param amount]. Returns false (nothing happens) when the hero is
## dead, [param dashing] (jumping) or still invulnerable. Otherwise removes the hit
## points, arms the invulnerability, emits [signal changed], and [signal died] once at 0.
## A fatal hit with a rescue armed (whatever the overkill) sets the hit points to
## max_hp × the rescue fraction instead, uses the rescue up and emits [signal rescued].
func take_hit(amount: float, dashing: bool) -> bool:
	if _dead or dashing or _invulnerable_left > 0.0 or amount <= 0.0:
		return false
	current = maxf(current - amount, 0.0)
	_invulnerable_left = _invulnerability
	if current <= 0.0 and _rescue_armed:
		_rescue_armed = false
		_rescue_used = true
		current = max_hp * _rescue_fraction
		changed.emit(current, max_hp)
		rescued.emit()
		return true
	changed.emit(current, max_hp)
	if current <= 0.0:
		_dead = true
		died.emit()
	return true


## Lowers the invulnerability by [param delta] seconds and applies the regeneration.
func tick(delta: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	if _regen_active and _regen_per_second > 0.0 and not _dead and current < max_hp:
		heal(_regen_per_second * delta)


## Restores [param amount] hit points, never above the maximum. Does nothing once dead.
func heal(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	var healed: float = minf(current + amount, max_hp)
	if healed == current:
		return
	current = healed
	changed.emit(current, max_hp)


## Raises the maximum by [param amount] and heals the hero by as much.
func add_max(amount: float) -> void:
	if amount <= 0.0:
		return
	max_hp += amount
	if not _dead:
		current += amount
	changed.emit(current, max_hp)


## Sets the regeneration, in hit points per second (0 = none).
func set_regen(per_second: float) -> void:
	_regen_per_second = maxf(per_second, 0.0)


## Switches the regeneration on (during waves) or off (between waves). Off at start.
func set_regen_active(active: bool) -> void:
	_regen_active = active


## True while a recent hit still protects the hero.
func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


## Arms a one-time rescue: the next fatal hit leaves the hero at max_hp × [param hp_fraction]
## instead of killing it. Once the rescue has been used (or the hero is dead), calling
## this again does nothing: there is one rescue per game.
func arm_rescue(hp_fraction: float) -> void:
	if _rescue_used or _dead or hp_fraction <= 0.0:
		return
	_rescue_fraction = hp_fraction
	_rescue_armed = true


## True while a rescue is armed and not used yet.
func has_rescue() -> bool:
	return _rescue_armed
