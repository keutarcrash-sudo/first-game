## Logic check for HeroHealth. Run with:
## godot --headless -s res://tests/unit/hero/hero_health_check.gd
## Prints "HERO_HEALTH OK" or "HERO_HEALTH FAIL: <name>" then quits.
extends SceneTree

const MAX_HP := 100.0
const INVULNERABILITY := 0.5
const HIT := 25.0
const JUMP_HIT := 10.0
const BONUS_MAX := 25.0


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
	return ""
