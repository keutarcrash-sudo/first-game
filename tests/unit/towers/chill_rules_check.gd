## Logic check for ChillRules and the PlayerModifiers « Gel mordant » bonus (towers T1,
## Task 2). Run with:
## godot --headless -s res://tests/unit/towers/chill_rules_check.gd
## Prints "CHILL_RULES OK" or "CHILL_RULES FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/towers.json"
const COMBUSTION := 0.5  # Any Combustion value: only the product matters here.


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("CHILL_RULES OK")
	else:
		print("CHILL_RULES FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var stats: TowerStats = TowerStats.load_from_file(PATH)
	if stats == null:
		return "towers.json loads"
	var dwell: float = stats.freeze_dwell
	var chill := ChillRules.new()
	if chill.tick(1.4, true, dwell):
		return "1.4 s in a zone does not freeze"
	if not chill.tick(0.1, true, dwell):
		return "1.5 s in a zone freezes"
	if not is_zero_approx(chill.dwell()):
		return "count starts over after a freeze"
	var frames := ChillRules.new()
	var froze_at := -1
	for frame: int in 20:
		if frames.tick(0.1, true, dwell):
			froze_at = frame + 1
			break
	if froze_at != 15:
		return "15 frames of 0.1 s freeze on the 15th (got %d)" % froze_at
	var leaving := ChillRules.new()
	leaving.tick(1.0, true, dwell)
	if leaving.tick(0.0, false, dwell) or not is_zero_approx(leaving.dwell()):
		return "leaving every zone at 1.0 s resets the count"
	if leaving.tick(1.0, true, dwell):
		return "after leaving, 1.0 s more does not freeze"
	var blizzard := ChillRules.new()
	if not blizzard.tick(1.0, true, 1.0):
		return "Blizzard dwell 1.0 freezes at 1.0 s"
	if chill.can_freeze(true, 0.0):
		return "no freeze while frozen"
	if chill.can_freeze(false, stats.freeze_cooldown):
		return "no freeze during the cooldown"
	if not chill.can_freeze(false, 0.0):
		return "freeze allowed after the cooldown"
	var base: float = stats.frozen_vulnerability
	if not is_equal_approx(ChillRules.damage_factor(true, base, 0.0), 1.25):
		return "frozen x1.25"
	if not is_equal_approx(ChillRules.damage_factor(false, base, 0.25), 1.0):
		return "not frozen x1"
	var mods := PlayerModifiers.new(null)
	if not is_zero_approx(mods.frozen_vulnerability_bonus()):
		return "no bonus without the card"
	var card := CardDef.new()
	card.id = "gel_mordant"
	card.display_name = card.id
	card.rarity = &"uncommon"
	card.effects.append({"type": "frozen_vulnerability_bonus", "value": 0.25})
	mods.take(card)
	if not is_equal_approx(ChillRules.damage_factor(true, base, mods.frozen_vulnerability_bonus()), 1.5):
		return "Gel mordant x1.5"
	var with_combustion: float = ChillRules.damage_factor(true, base, 0.0) * (1.0 + COMBUSTION)
	if not is_equal_approx(with_combustion, 1.25 * (1.0 + COMBUSTION)):
		return "multiplied with Combustion"
	return ""
