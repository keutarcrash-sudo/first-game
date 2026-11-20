## Logic check for HeroHealth. Run with:
## godot --headless -s res://tests/unit/hero/hero_health_check.gd
## Prints "HERO_HEALTH OK" or "HERO_HEALTH FAIL: <name>" then quits.
extends SceneTree

const MAX_HP := 100.0
const INVULNERABILITY := 0.5
const HIT := 25.0
const JUMP_HIT := 10.0
const BONUS_MAX := 25.0
const REGEN := 2.0
const RESCUE_FRACTION := 0.3  # Seconde chance (étape 5a spec §8).
const OVERKILL_HIT := 150.0
const AFTER_RESCUE_HIT := 40.0


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("HERO_HEALTH OK")
	else:
		print("HERO_HEALTH FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var health := HeroHealth.new(MAX_HP, INVULNERABILITY)
	if not health.take_hit(HIT, false) or not is_equal_approx(health.current, MAX_HP - HIT):
		return "first hit removes hit points"
	if not health.is_invulnerable():
		return "invulnerable after a hit"
	if health.take_hit(HIT, false):
		return "second hit refused while invulnerable"
	health.tick(INVULNERABILITY)
	if health.is_invulnerable():
		return "invulnerability ends"
	if health.take_hit(JUMP_HIT, true) or not is_equal_approx(health.current, MAX_HP - HIT):
		return "hit during a jump ignored"
	if not health.take_hit(HIT, false):
		return "hit after invulnerability accepted"
	health.heal(1000.0)
	if not is_equal_approx(health.current, MAX_HP):
		return "heal capped at max"
	health.add_max(BONUS_MAX)
	if not is_equal_approx(health.max_hp, MAX_HP + BONUS_MAX) or not is_equal_approx(health.current, MAX_HP + BONUS_MAX):
		return "add_max raises max and heals"
	# take_hit(0) is ignored: no change, no invulnerability, no signal.
	var zero := HeroHealth.new(MAX_HP, INVULNERABILITY)
	var zero_signals: Array[int] = [0]
	zero.changed.connect(func(_c: float, _m: float) -> void: zero_signals[0] += 1)
	if zero.take_hit(0.0, false) or zero.is_invulnerable() or zero_signals[0] != 0:
		return "zero hit ignored"
	# Regeneration: +REGEN per second after a hit, capped at max.
	var regen := HeroHealth.new(MAX_HP, INVULNERABILITY)
	regen.set_regen(REGEN)
	regen.take_hit(HIT, false)
	regen.tick(1.0)
	if not is_equal_approx(regen.current, MAX_HP - HIT):
		return "regen inactive: no heal"
	regen.set_regen_active(true)
	regen.tick(1.0)
	if not is_equal_approx(regen.current, MAX_HP - HIT + REGEN):
		return "regen adds per second"
	regen.tick(1000.0)
	if not is_equal_approx(regen.current, MAX_HP):
		return "regen capped at max"
	var deaths: Array[int] = [0]
	var fatal := HeroHealth.new(MAX_HP, INVULNERABILITY)
	fatal.died.connect(func() -> void: deaths[0] += 1)
	fatal.take_hit(MAX_HP, false)
	fatal.tick(INVULNERABILITY)
	fatal.take_hit(HIT, false)
	fatal.tick(INVULNERABILITY)
	fatal.take_hit(HIT, false)
	if deaths[0] != 1 or fatal.current != 0.0:
		return "died emitted once at 0"
	fatal.heal(HIT)
	fatal.set_regen(REGEN)
	fatal.set_regen_active(true)
	fatal.tick(1.0)
	if fatal.current != 0.0:
		return "no heal or regen after death"
	return _run_rescue()


## Seconde chance: a fatal hit (even an overkill) leaves the hero at max_hp × fraction, once per game.
func _run_rescue() -> String:
	var saved := HeroHealth.new(MAX_HP, INVULNERABILITY)
	var rescues: Array[int] = [0]
	var saved_deaths: Array[int] = [0]
	saved.rescued.connect(func() -> void: rescues[0] += 1)
	saved.died.connect(func() -> void: saved_deaths[0] += 1)
	if saved.has_rescue():
		return "no rescue before arm_rescue"
	saved.arm_rescue(RESCUE_FRACTION)
	if not saved.has_rescue():
		return "rescue armed"
	if not saved.take_hit(OVERKILL_HIT, false):
		return "fatal hit with rescue accepted"
	if not is_equal_approx(saved.current, MAX_HP * RESCUE_FRACTION):
		return "rescue leaves max_hp × fraction"
	if rescues[0] != 1 or saved_deaths[0] != 0:
		return "rescue emits rescued, not died"
	if not saved.is_invulnerable() or saved.has_rescue():
		return "rescue grants invulnerability and is used up"
	saved.arm_rescue(RESCUE_FRACTION)
	if saved.has_rescue():
		return "arm_rescue after use does not re-arm"
	saved.tick(INVULNERABILITY)
	saved.take_hit(AFTER_RESCUE_HIT, false)
	if saved_deaths[0] != 1 or rescues[0] != 1 or saved.current != 0.0:
		return "second fatal hit kills"
	return ""
