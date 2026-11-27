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


## Value [param key] for a tower on [param branch] at [param level]: the branch value
## when the level is 2 or more and the branch has the key ([code]l3_<key>[/code] first
## at level 3), else the base value ([code]range[/code] and [code]radius[/code]
## included); [code]null[/code] if none exists.
func value(key: String, branch: StringName, level: int) -> Variant:
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
