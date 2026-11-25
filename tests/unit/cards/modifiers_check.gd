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
	quit(0 if failed.is_empty() else 1)


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
	return _run_items()


func _item(id: String, effect: Dictionary) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id
	item.effects.append(effect)
	return item


## Passive items: each reader, the second take ignored, and the second_chance flag.
func _run_items() -> String:
	var mods := PlayerModifiers.new(null)
	var changes: Array[int] = [0, 0]
	mods.items_changed.connect(func() -> void: changes[0] += 1)
	mods.changed.connect(func() -> void: changes[1] += 1)
	if not is_equal_approx(mods.tower_range_factor(), 1.0) or mods.tower_cost(50) != 50 or mods.gold_per_kill(15) != 15 or not is_equal_approx(mods.crystal_damage_factor(), 1.0):
		return "item_readers_default"
	var bourse: ItemDef = _item("bourse_percee", {"type": "gold_per_kill_mult", "value": 1.2})
	var plans: ItemDef = _item("plans_ingenieur", {"type": "tower_cost_mult", "value": 0.8})
	var oeil: ItemDef = _item("oeil_de_faucon", {"type": "tower_range_bonus", "value": 0.2})
	var bouclier: ItemDef = _item("bouclier_cristal", {"type": "crystal_damage_reduction", "value": 0.15})
	var pansement: ItemDef = _item("pansement_dore", {"type": "hero_heal_per_wave", "value": 10})
	var seconde: ItemDef = _item("seconde_chance", {"type": "second_chance", "hp_fraction": 0.3})
	for item: ItemDef in [bourse, plans, oeil, bouclier, pansement, seconde, bourse]:
		mods.take_item(item)  # The last one is a second take of the same item.
	if mods.gold_per_kill(15) != 18:
		return "gold_per_kill_item"
	if mods.tower_cost(50) != 40:
		return "tower_cost_item"
	if not is_equal_approx(mods.tower_cost_factor(), 0.8) or not is_equal_approx(mods.upgrade_cost_factor(), 0.8):
		return "tower_cost_factors_item"
	if not is_equal_approx(mods.tower_range_factor(), 1.2):
		return "tower_range_factor_item"
	if not is_equal_approx(mods.crystal_damage_factor(), 0.85):
		return "crystal_damage_factor_item"
	if not is_equal_approx(mods.hero_heal_per_wave(), 10.0):
		return "hero_heal_per_wave_item"
	if not mods.owns_item("bourse_percee") or mods.owns_item("lunette"):
		return "owns_item"
	if mods.owned_items().size() != 6:
		return "owned_items_second_take_ignored"
	if changes[0] != 6 or changes[1] != 6:
		return "items_changed_signals"
	if not mods.has_flag(&"second_chance") or not is_equal_approx(mods.flag_value(&"second_chance", "hp_fraction"), 0.3):
		return "flag_second_chance"
	mods.take(_card("ingenieur_chevronne", {"type": "upgrade_cost_mult", "value": 0.75}))
	if not is_equal_approx(mods.tower_cost_factor(), 0.8) or not is_equal_approx(mods.upgrade_cost_factor(), 0.6):
		return "upgrade_cost_factor_card"
	var heavy := PlayerModifiers.new(null)
	for i: int in 3:
		heavy.take_item(_item("shield_%d" % i, {"type": "crystal_damage_reduction", "value": 0.5}))
	if not is_equal_approx(heavy.crystal_damage_factor(), 0.1):
		return "crystal_damage_floor"
	return ""
