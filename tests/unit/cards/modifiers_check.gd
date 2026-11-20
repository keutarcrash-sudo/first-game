## Logic check for PlayerModifiers card effects. Run with:
## godot --headless -s res://tests/unit/cards/modifiers_check.gd
## Prints "MODIFIERS OK" or "MODIFIERS FAIL: <name>" then quits.
extends SceneTree


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("MODIFIERS OK")
	else:
		print("MODIFIERS FAIL: %s" % failed)
	quit()


func _card(id: String, effect: Dictionary, rarity: StringName = &"common") -> CardDef:
	var card := CardDef.new()
	card.id = id
	card.display_name = id
	card.rarity = rarity
	card.effects.append(effect)
	return card


## Returns the name of the first failing check, or "" if all pass.
func _run() -> String:
	var mods := PlayerModifiers.new(null)  # No unlock_combo card is used here.
	var pas_leger: CardDef = _card("pas_leger", {"type": "move_speed_bonus", "value": 0.1})
	var jet: CardDef = _card("jet_puissant", {"type": "hero_damage_bonus", "value": 0.25})
	var aimant: CardDef = _card("aimant", {"type": "pickup_radius_mult", "value": 1.4})
	var esquive: CardDef = _card("esquive", {"type": "ability_cooldown_mult", "ability_id": "roulade", "value": 0.7})
	var pointe: CardDef = _card("pointe_acier", {"type": "ability_value_mult", "ability_id": "fleche_perforante", "key": "damage", "value": 1.5})
	var rafale: CardDef = _card("tir_en_rafale", {"type": "burst_on_crit", "chance": 0.3}, &"epic")
	for card: CardDef in [pas_leger, jet, aimant, esquive, esquive, pointe, rafale]:
		mods.take(card)
	if not is_equal_approx(mods.move_speed_factor(), 1.1):
		return "move_speed_factor"
	if not is_equal_approx(mods.hero_damage_multiplier(), 1.25):
		return "hero_damage_multiplier"
	if not is_equal_approx(mods.damage_multiplier(), 1.0):
		return "cannon_damage_unchanged"
	if not is_equal_approx(mods.pickup_radius_factor(), 1.4):
		return "pickup_radius_factor"
	if not is_equal_approx(mods.ability_cooldown_factor("roulade"), 0.4):
		return "cooldown_factor_two_stacks"
	if not is_equal_approx(mods.ability_cooldown_factor("glissade"), 1.0):
		return "cooldown_other_ability"
	if not is_equal_approx(mods.ability_value("fleche_perforante", "damage", 42.0), 63.0):
		return "ability_value_mult"
	if not mods.has_flag(&"burst_on_crit") or not is_equal_approx(mods.flag_value(&"burst_on_crit", "chance"), 0.3):
		return "flag_burst_on_crit"
	if mods.has_flag(&"ghost_arrows"):
		return "flag_off_by_default"
	if mods.took_legendary():
		return "no_legendary_yet"
	var floor_mods := PlayerModifiers.new(null)
	for i: int in 4:
		floor_mods.take(esquive)  # No max_stacks set on this test card: unlimited.
	if not is_equal_approx(floor_mods.ability_cooldown_factor("roulade"), 0.25):
		return "cooldown_floor"
	var surv := PlayerModifiers.new(null)
	var healed: Array[float] = []
	surv.hero_heal_requested.connect(func(amount: float) -> void: healed.append(amount))
	surv.take(_card("bandage", {"type": "hero_heal", "value": 30}))
	if healed.size() != 1 or not is_equal_approx(healed[0], 30.0):
		return "hero_heal_requested"
	var peau: CardDef = _card("peau_dure", {"type": "hero_max_hp_bonus", "value": 25}, &"uncommon")
	surv.take(peau)
	surv.take(peau)
	if not is_equal_approx(surv.hero_max_hp_bonus(), 50.0):
		return "hero_max_hp_bonus_two_stacks"
	surv.take(_card("regeneration", {"type": "hero_regen", "value": 1.0}, &"rare"))
	if not is_equal_approx(surv.hero_regen(), 1.0):
		return "hero_regen"
	surv.take(_card("vampirisme", {"type": "hero_heal_on_kill", "value": 1.0}, &"epic"))
	if not is_equal_approx(surv.hero_heal_on_kill(), 1.0):
		return "hero_heal_on_kill"
	return ""
