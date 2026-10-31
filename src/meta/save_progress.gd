## Saved progression (story 007): the points total and the ids of the owned
## upgrades. Plain data; file access only happens in [method load_from_file]
## and [method save_to_file]. The file is a small JSON object in user://:
## [code]{"version": 1, "total_points": 12, "owned_ids": ["cristal_renforce"]}[/code].
class_name SaveProgress
extends RefCounted

## Format version written in the file. A file with another version is ignored.
const SAVE_VERSION := 1

## Points not spent yet. Never negative.
var total_points := 0
## Ids of the owned upgrades, in purchase order.
var owned_ids := PackedStringArray()


## Reads the progression at [param path]. A missing file gives an empty
## progression silently; an unreadable or invalid file gives an empty
## progression and a warning, never an error. Owned ids that [param tree] does
## not know are dropped with a warning.
static func load_from_file(path: String, tree: SkillTree) -> SaveProgress:
	var progress := SaveProgress.new()
	if not FileAccess.file_exists(path):
		return progress
	# A JSON instance rather than JSON.parse_string, which prints an engine error on a corrupt file.
	var json := JSON.new()
	var parsed: bool = json.parse(FileAccess.get_file_as_string(path)) == OK
	var data: Variant = json.data if parsed else null
	if not data is Dictionary:
		push_warning("SaveProgress: '%s' is unreadable or not a JSON object; starting with an empty progression." % path)
		return progress
	var version: Variant = data.get("version")
	var points: Variant = data.get("total_points")
	var owned: Variant = data.get("owned_ids")
	if not (version is float or version is int) or version != SAVE_VERSION \
			or not (points is float or points is int) or points < 0 or not owned is Array:
		push_warning("SaveProgress: '%s' has an unknown version or invalid keys; starting with an empty progression." % path)
		return progress
	progress.total_points = floori(points)
	for id: Variant in owned:
		if id is String and tree.has_upgrade(id) and not progress.owned_ids.has(id):
			progress.owned_ids.append(id)
		else:
			push_warning("SaveProgress: '%s' lists an unknown or repeated upgrade (%s); it is ignored." % [path, id])
	return progress


## Writes the progression to [param path]. Returns [code]false[/code] and prints
## a warning if the file cannot be written; the game goes on either way.
func save_to_file(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveProgress: cannot write '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return false
	var written: bool = file.store_string(JSON.stringify({
		"version": SAVE_VERSION,
		"total_points": total_points,
		"owned_ids": Array(owned_ids),
	}))
	# Closed explicitly rather than when the reference is dropped, so the data is flushed now.
	file.close()
	if not written:
		push_warning("SaveProgress: writing '%s' failed." % path)
	return written
