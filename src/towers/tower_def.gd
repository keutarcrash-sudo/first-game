## One tower type read from the [code]towers[/code] section of towers.json (towers T2a):
## its identifier, name, behaviour ([TowerBehaviour]), base price, range, body radius,
## sprite sheet and every other value of its behaviour, plus its upgrade branches.
## Built and validated by [TowerStats]; read-only afterwards.
class_name TowerDef
extends RefCounted

## Identifier of the tower type (key in towers.json, [member TowerRecord.kind]).
var id: StringName
## Display name ("Canon").
var label: String
## Behaviour identifier ([constant TowerStats.BEHAVIOUR_KEYS]).
var behaviour: StringName
## Base price in gold of the first paid tower of this type.
var base_cost: int
## Base range in pixels.
var range: float
## Body radius in pixels (drawing and placement footprint).
var radius: float
## Folder of the sprite sheet.
var sheet_path: String
## On-screen height in pixels of the whole sheet cell.
var height_px: float
## Halo colour on the ground (optional key [code]color[/code], white by default).
var color: Color = Color.WHITE
## Colour of the reserve bar icon (optional key [code]icon_color[/code], [member color] by default).
var icon_color: Color = Color.WHITE
## Every other value of the tower, key (String) -> number (float as read from JSON).
var values: Dictionary = {}
## Upgrade branches, id (StringName) -> Dictionary of values ([code]label[/code] is a String).
var branches: Dictionary = {}
## Evolutions (towers T2b), branch id (StringName) -> Dictionary: [code]name[/code], one of
## [code]requires_item[/code] / [code]requires_card[/code] (Strings) and the evolved values.
var evolutions: Dictionary = {}
## Filled by [method TowerStats.resolve_evolutions]: branch id -> display name of the
## required item or card, its specialization id, and that specialization's display name.
var _requirement_names: Dictionary = {}
var _requirement_specs: Dictionary = {}
var _requirement_spec_names: Dictionary = {}


## Value [param key] for a tower on [param branch] at [param level]: the evolution value
## when [param evolved] and the branch's evolution has the key (towers T2b), else the
## branch value when the level is 2 or more and the branch has the key
## ([code]l3_<key>[/code] first at level 3), else the base value ([code]range[/code] and
## [code]radius[/code] included); [code]null[/code] if none exists.
func value(key: String, branch: StringName, level: int, evolved: bool = false) -> Variant:
	if evolved and evolutions.has(branch):
		var evolution: Dictionary = evolutions[branch]
		if evolution.has(key):
			return evolution[key]
	if level >= 2 and branches.has(branch):
		var branch_values: Dictionary = branches[branch]
		if level >= TowerRecord.MAX_LEVEL and branch_values.has("l3_" + key):
			return branch_values["l3_" + key]
		if branch_values.has(key):
			return branch_values[key]
	match key:
		"range":
			return range
		"radius":
			return radius
	return values.get(key)


## Value [param key] of branch [param branch], or [code]null[/code] if the branch or the key does not exist.
func branch_value(branch: StringName, key: String) -> Variant:
	return (branches.get(branch, {}) as Dictionary).get(key)


## Branch ids, in file order.
func branch_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for branch_id: StringName in branches:
		ids.append(branch_id)
	return ids


## True if [param branch] has an evolution.
func has_evolution(branch: StringName) -> bool:
	return evolutions.has(branch)


## Display name of the evolution of [param branch] ("Volcan"), or "" if none.
func evolution_name(branch: StringName) -> String:
	return String((evolutions.get(branch, {}) as Dictionary).get("name", ""))


## Id of the item the evolution of [param branch] needs, or "" (a card, or no evolution).
func requirement_item(branch: StringName) -> String:
	return String((evolutions.get(branch, {}) as Dictionary).get("requires_item", ""))


## Id of the card the evolution of [param branch] needs, or "" (an item, or no evolution).
func requirement_card(branch: StringName) -> String:
	return String((evolutions.get(branch, {}) as Dictionary).get("requires_card", ""))


## Display name of the item or card the evolution of [param branch] needs; its id
## until [method TowerStats.resolve_evolutions] has run.
func requirement_name(branch: StringName) -> String:
	if _requirement_names.has(branch):
		return _requirement_names[branch]
	var item: String = requirement_item(branch)
	return requirement_card(branch) if item.is_empty() else item


## Specialization the required item or card is reserved to, or [code]&""[/code] for every hero.
func requirement_spec(branch: StringName) -> StringName:
	return _requirement_specs.get(branch, &"")


## Display name of [method requirement_spec] ("Archer"), or "" for every hero.
func requirement_spec_name(branch: StringName) -> String:
	return _requirement_spec_names.get(branch, "")


## Records what [method TowerStats.resolve_evolutions] found for the requirement of
## [param branch]: its display name, specialization id and specialization display name.
func set_requirement_info(branch: StringName, display_name: String, spec: StringName, spec_name: String) -> void:
	_requirement_names[branch] = display_name
	_requirement_specs[branch] = spec
	_requirement_spec_names[branch] = spec_name
