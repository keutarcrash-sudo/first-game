## Logic check for CardPool rarity draw and reroll. Run with:
## godot --headless -s res://tests/unit/cards/rarity_draw_check.gd
## Prints "RARITY OK" or "RARITY FAIL: <name>" then quits.
extends SceneTree

const RARITIES_PATH := "res://assets/data/card_rarities.json"
const COPIES := 10  # Cards per rarity in the big catalog.


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("RARITY OK")
	else:
		print("RARITY FAIL: %s" % failed)
	quit()


func _card(id: String, rarity: StringName) -> CardDef:
	var card := CardDef.new()
	card.id = id
	card.display_name = id
	card.rarity = rarity
	return card


func _catalog(cards: Array[CardDef]) -> CardCatalog:
	var catalog := CardCatalog.new()
	catalog.offered_per_choice = 3
	catalog.cards = cards
	return catalog


func _big_cards() -> Array[CardDef]:
	var cards: Array[CardDef] = []
	for rarity: StringName in CardRarities.IDS:
		for i: int in COPIES:
			cards.append(_card("%s_%d" % [rarity, i], rarity))
	return cards


func _pool(cards: Array[CardDef], mods: PlayerModifiers, rarities: CardRarities, unlocked: Callable) -> CardPool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	return CardPool.new(_catalog(cards), mods, rng, PackedStringArray(), 0, "", rarities, unlocked)


## Returns the name of the first failing check, or "" if all pass.
func _run() -> String:
	var rarities: CardRarities = CardRarities.load_from_file(RARITIES_PATH)
	if rarities == null:
		return "load_rarities"
	var always := func(_id: String) -> bool: return true
	var never := func(_id: String) -> bool: return false

	# No duplicate within an offer, and a full offer when the pool is large.
	var pool: CardPool = _pool(_big_cards(), PlayerModifiers.new(null), rarities, always)
	for i: int in 200:
		var offer: Array[CardDef] = pool.draw(1)
		if offer.size() != 3:
			return "full_offer_size"
		var seen: Dictionary = {}
		for card: CardDef in offer:
			if seen.has(card.id):
				return "duplicate_in_offer"
			seen[card.id] = true

	# Once a legendary is taken, none is offered again.
	var mods := PlayerModifiers.new(null)
	var big: Array[CardDef] = _big_cards()
	mods.take(big[big.size() - 1])
	if not mods.took_legendary():
		return "fixture_took_legendary"
	var no_legend_pool: CardPool = _pool(big, mods, rarities, always)
	for i: int in 200:
		for card: CardDef in no_legend_pool.draw(5):
			if card.rarity == &"legendary":
				return "legendary_after_taken"

	# A pool of 2 cards gives an offer of 2.
	var small: Array[CardDef] = [_card("a", &"common"), _card("b", &"rare")]
	if _pool(small, PlayerModifiers.new(null), rarities, always).draw(1).size() != 2:
		return "small_pool_offer"

	# Ability card absent while the ability is locked, present once unlocked.
	var skill: CardDef = _card("skill", &"common")
	skill.requires_ability = "wave"
	var skill_cards: Array[CardDef] = [skill, _card("other", &"common")]
	for i: int in 50:
		for card: CardDef in _pool(skill_cards, PlayerModifiers.new(null), rarities, never).draw(1):
			if card.id == "skill":
				return "ability_card_while_locked"
	var unlocked_ids: Array[String] = []
	for card: CardDef in _pool(skill_cards, PlayerModifiers.new(null), rarities, always).draw(1):
		unlocked_ids.append(card.id)
	if not unlocked_ids.has("skill"):
		return "ability_card_when_unlocked"

	# requires_card: only once the other card has been taken.
	var base: CardDef = _card("base", &"common")
	var follow: CardDef = _card("follow", &"common")
	follow.requires_card = "base"
	var chain: Array[CardDef] = [base, follow]
	for card: CardDef in _pool(chain, PlayerModifiers.new(null), rarities, always).draw(1):
		if card.id == "follow":
			return "requires_card_before_taken"
	var chain_mods := PlayerModifiers.new(null)
	chain_mods.take(base)
	var after: Array[String] = []
	for card: CardDef in _pool(chain, chain_mods, rarities, always).draw(1):
		after.append(card.id)
	if not after.has("follow"):
		return "requires_card_after_taken"

	# Reroll price rises by one step per reroll and resets with begin_choice().
	var cost_pool: CardPool = _pool(_big_cards(), PlayerModifiers.new(null), rarities, always)
	cost_pool.begin_choice()
	var first_cost: int = cost_pool.reroll_cost()
	cost_pool.reroll(1)
	if cost_pool.reroll_cost() != rarities.reroll_cost(1) or cost_pool.reroll_cost() <= first_cost:
		return "reroll_cost_rises"
	cost_pool.begin_choice()
	if cost_pool.reroll_cost() != first_cost:
		return "reroll_cost_resets"

	# Wave 1: commons are about half of the cards (weight 50 out of 100).
	var stats_pool: CardPool = _pool(_big_cards(), PlayerModifiers.new(null), rarities, always)
	var commons := 0
	var total := 0
	for i: int in 2000:
		for card: CardDef in stats_pool.draw(1):
			total += 1
			if card.rarity == &"common":
				commons += 1
	var share: float = float(commons) / float(total)
	if share < 0.45 or share > 0.55:
		return "common_share_%f" % share
	return ""
