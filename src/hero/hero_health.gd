## The hero's hit points (étape 4, design/gdd étape 4 spec §5). Pure logic, no node:
## a hit removes hit points and starts a short invulnerability; a jump (dash) is
## invulnerable too; at 0 the hero is dead, once. Regeneration is 0 unless a card
## sets it with [method set_regen] (there is no automatic healing).
class_name HeroHealth
extends RefCounted

## Emitted when the hit points or the maximum change.
signal changed(current: float, max_hp: float)
## Emitted once, when the hit points reach 0.
signal died

## Current hit points (0 = dead).
var current: float
## Maximum hit points.
var max_hp: float

var _invulnerability := 0.0  # Seconds of invulnerability granted by a hit.
var _invulnerable_left := 0.0
var _regen_per_second := 0.0
var _dead := false


## Starts full at [param max_hp]; a hit grants [param invulnerability] seconds of protection.
func _init(max_hp: float, invulnerability: float) -> void:
	self.max_hp = max_hp
	current = max_hp
	_invulnerability = invulnerability


## Applies a hit of [param amount]. Returns false (nothing happens) when the hero is
## dead, [param dashing] (jumping) or still invulnerable. Otherwise removes the hit
## points, arms the invulnerability, emits [signal changed], and [signal died] once at 0.
func take_hit(amount: float, dashing: bool) -> bool:
	if _dead or dashing or _invulnerable_left > 0.0 or amount <= 0.0:
		return false
	current = maxf(current - amount, 0.0)
	_invulnerable_left = _invulnerability
	changed.emit(current, max_hp)
	if current <= 0.0:
		_dead = true
		died.emit()
	return true


## Lowers the invulnerability by [param delta] seconds and applies the regeneration.
func tick(delta: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	if _regen_per_second > 0.0 and not _dead and current < max_hp:
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


## True while a recent hit still protects the hero.
func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0
