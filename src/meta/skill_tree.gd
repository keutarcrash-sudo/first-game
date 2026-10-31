## Permanent upgrade tree and end-of-game points (story 007, design/game-brief.md
## MVP feature 7), loaded from assets/data/skill_tree.json. Pure logic: the
## rules (points formula, buy rules, bonuses of the owned upgrades) never touch
## the scene tree or files, the caller passes the [SaveProgress] in.
## To add an effect type, add it to [constant EFFECT_NUMBER_KEYS] and read it in
## the bonus functions below.
class_name SkillTree
extends RefCounted

## How an upgrade looks to the player, given the progression.
enum NodeState { OWNED, AVAILABLE, LOCKED, TOO_EXPENSIVE }

## Effect types known to the code, with the numeric keys each one needs (all above 0).
## [code]unlock_cards[/code] also needs a [code]card_ids[/code] list.
const EFFECT_NUMBER_KEYS := {
	"crystal_max_hp_bonus": ["value"],
	"starting_gold_bonus": ["value"],
	"start_card_choice": [],
	"unlock_cards": [],
	"cards_offered_bonus": ["value"],
}

## One upgrade of the tree, as described in the JSON file.
class Upgrade extends RefCounted:
	## Unique id (also the id stored in the save).
	var id: String
	## Name shown on the node.
	var display_name: String
	## Readable effect shown on the node.
	var description: String
	## Branch name; the defeat screen gives each branch a column.
	var branch: String
	## Price in points.
	var cost: int
	## Ids of the upgrades that must be owned first. They always come earlier in the file.
	var requires := PackedStringArray()
	## Effects: dictionaries with a "type" key and that type's values.
	var effects: Array[Dictionary] = []

## Points per wave finished during the game.
var points_per_wave_completed: int
## Kills needed for one point.
var kills_per_point: int
## Every upgrade, in file order (a node always comes after the ones it requires).
var upgrades: Array[Upgrade] = []

var _by_id: Dictionary = {}  # id -> Upgrade


## Reads and validates the JSON file at [param path]. Card ids used by
## [code]unlock_cards[/code] must exist in [param catalog]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String, catalog: CardCatalog) -> SkillTree:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("SkillTree: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.get("nodes") is Array:
		push_error("SkillTree: '%s' must be a JSON object with a 'nodes' list." % path)
		return null
	var tree := SkillTree.new()
	for key: String in ["points_per_wave_completed", "kills_per_point"]:
		var value: Variant = data.get(key)
		if not (value is float or value is int) or value < 1:
			push_error("SkillTree: key '%s' in '%s' must be a number of at least 1 (got %s)." % [key, path, value])
			return null
	tree.points_per_wave_completed = roundi(data["points_per_wave_completed"])
	tree.kills_per_point = roundi(data["kills_per_point"])
	for i: int in data["nodes"].size():
		var upgrade: Upgrade = _parse_upgrade(data["nodes"][i], i, path, tree, catalog)
		if upgrade == null:
			return null
		tree.upgrades.append(upgrade)
		tree._by_id[upgrade.id] = upgrade
	return tree


static func _parse_upgrade(raw: Variant, index: int, path: String, tree: SkillTree, catalog: CardCatalog) -> Upgrade:
	var where: String = "nodes[%d]" % index
	if not raw is Dictionary:
		push_error("SkillTree: '%s' in '%s' must be an object." % [where, path])
		return null
	for key: String in ["id", "display_name", "description", "branch"]:
		if not raw.get(key) is String or (raw[key] as String).strip_edges().is_empty():
			push_error("SkillTree: key '%s.%s' in '%s' must be a non-empty string." % [where, key, path])
			return null
	var upgrade := Upgrade.new()
	upgrade.id = raw["id"]
	upgrade.display_name = raw["display_name"]
	upgrade.description = raw["description"]
	upgrade.branch = raw["branch"]
	if tree._by_id.has(upgrade.id):
		push_error("SkillTree: key '%s.id' in '%s' is a duplicate ('%s')." % [where, path, upgrade.id])
		return null
	var cost: Variant = raw.get("cost")
	if not (cost is float or cost is int) or cost < 1:
		push_error("SkillTree: key '%s.cost' in '%s' must be a number of at least 1 (got %s)." % [where, path, cost])
		return null
	upgrade.cost = roundi(cost)
	if not raw.get("requires") is Array:
		push_error("SkillTree: key '%s.requires' in '%s' must be a list of node ids." % [where, path])
		return null
	for required: Variant in raw["requires"]:
		# Requiring only earlier nodes rules out cycles.
		if not required is String or not tree._by_id.has(required):
			push_error("SkillTree: key '%s.requires' in '%s' must list ids of nodes written earlier in the file (got %s)." % [where, path, required])
			return null
		upgrade.requires.append(required)
	if not raw.get("effects") is Array or (raw["effects"] as Array).is_empty():
		push_error("SkillTree: key '%s.effects' in '%s' must be a non-empty list." % [where, path])
		return null
	for j: int in raw["effects"].size():
		var effect: Variant = raw["effects"][j]
		if not _is_effect_valid(effect, "%s.effects[%d]" % [where, j], path, catalog):
			return null
		upgrade.effects.append(effect)
	return upgrade


static func _is_effect_valid(effect: Variant, where: String, path: String, catalog: CardCatalog) -> bool:
	if not effect is Dictionary or not effect.get("type") is String:
		push_error("SkillTree: key '%s.type' in '%s' must be a string." % [where, path])
		return false
	if not EFFECT_NUMBER_KEYS.has(effect["type"]):
		push_error("SkillTree: key '%s.type' in '%s' is an unknown effect type ('%s')." % [where, path, effect["type"]])
		return false
	for key: String in EFFECT_NUMBER_KEYS[effect["type"]]:
		var value: Variant = effect.get(key)
		if not (value is float or value is int) or value <= 0:
			push_error("SkillTree: key '%s.%s' in '%s' must be a number above 0 (got %s)." % [where, key, path, value])
			return false
	if effect["type"] == "unlock_cards":
		var ids: Variant = effect.get("card_ids")
		if not ids is Array or (ids as Array).is_empty():
			push_error("SkillTree: key '%s.card_ids' in '%s' must be a non-empty list of card ids." % [where, path])
			return false
		for card_id: Variant in ids:
			if not card_id is String or not catalog.has_card(card_id):
				push_error("SkillTree: key '%s.card_ids' in '%s' must list ids of cards in cards.json (got %s)." % [where, path, card_id])
				return false
	return true


## True when [param id] is an upgrade of this tree.
func has_upgrade(id: String) -> bool:
	return _by_id.has(id)


## Points earned by a game: points_per_wave_completed x waves finished
## + floor(kills / kills_per_point).
func points_for_game(waves_completed: int, kills: int) -> int:
	return points_per_wave_completed * waves_completed + floori(float(kills) / kills_per_point)


## State of the upgrade [param id] for [param progress]. LOCKED wins over
## TOO_EXPENSIVE: a node whose requirements are missing cannot be bought anyway.
func node_state(id: String, progress: SaveProgress) -> NodeState:
	var upgrade: Upgrade = _by_id[id]
	if progress.owned_ids.has(id):
		return NodeState.OWNED
	for required: String in upgrade.requires:
		if not progress.owned_ids.has(required):
			return NodeState.LOCKED
	if progress.total_points < upgrade.cost:
		return NodeState.TOO_EXPENSIVE
	return NodeState.AVAILABLE


## Buys the upgrade [param id]: takes its cost from [param progress] and adds it
## to the owned ids. Returns an empty string on success, otherwise the short
## French refusal message, and then [param progress] is unchanged.
func buy(id: String, progress: SaveProgress) -> String:
	match node_state(id, progress):
		NodeState.OWNED:
			return "Déjà acquis"
		NodeState.LOCKED:
			var missing := PackedStringArray()
			for required: String in (_by_id[id] as Upgrade).requires:
				if not progress.owned_ids.has(required):
					missing.append("« %s »" % (_by_id[required] as Upgrade).display_name)
			return "Débloque d'abord %s" % ", ".join(missing)
		NodeState.TOO_EXPENSIVE:
			return "Pas assez de points"
	progress.total_points -= (_by_id[id] as Upgrade).cost
	progress.owned_ids.append(id)
	return ""


## Extra crystal max hit points given by the upgrades in [param owned].
func crystal_max_hp_bonus(owned: PackedStringArray) -> float:
	var total := 0.0
	for effect: Dictionary in _owned_effects(owned, "crystal_max_hp_bonus"):
		total += float(effect["value"])
	return total


## Extra starting gold given by the upgrades in [param owned].
func starting_gold_bonus(owned: PackedStringArray) -> int:
	var total := 0
	for effect: Dictionary in _owned_effects(owned, "starting_gold_bonus"):
		total += roundi(effect["value"])
	return total


## True when an upgrade in [param owned] offers a card choice before wave 1.
func has_start_card_choice(owned: PackedStringArray) -> bool:
	return not _owned_effects(owned, "start_card_choice").is_empty()


## Ids of the locked-by-default cards that the upgrades in [param owned] add to the draws.
func unlocked_card_ids(owned: PackedStringArray) -> PackedStringArray:
	var ids := PackedStringArray()
	for effect: Dictionary in _owned_effects(owned, "unlock_cards"):
		for card_id: String in effect["card_ids"]:
			ids.append(card_id)
	return ids


## Extra cards offered at each card choice by the upgrades in [param owned].
func cards_offered_bonus(owned: PackedStringArray) -> int:
	var total := 0
	for effect: Dictionary in _owned_effects(owned, "cards_offered_bonus"):
		total += roundi(effect["value"])
	return total


func _owned_effects(owned: PackedStringArray, type: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for upgrade: Upgrade in upgrades:
		if not owned.has(upgrade.id):
			continue
		for effect: Dictionary in upgrade.effects:
			if effect["type"] == type:
				found.append(effect)
	return found
