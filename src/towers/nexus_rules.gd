## Pure rules of the Nexus (towers T2b, spec §5 and §7bis): every hit of a tower boosted by
## a Nexus (evolved Catalyseur amplifier) also sets a light version of the states the OTHER
## boosted towers set, with values fixed in the data:
## - cannon Incendiaire or flamethrower: burn of [code]share_burn_dps[/code] per second for
##   [code]share_burn_duration[/code] s;
## - frost: slow to [code]share_slow[/code] of the speed for [code]share_slow_duration[/code] s
##   (never a direct freeze: it would skip the time spent in the zone);
## - frost Blizzard level 3: also wet for [code]share_wet[/code] s;
## - Tesla Arc or evolved mortar Sismique (Tremblement): stun of [code]share_stun[/code] s.
## A tower never receives its own states; each state is given once, however many towers share it.
class_name NexusRules
extends RefCounted

## The value keys of the Nexus evolution these rules read.
const KEYS: Array[String] = [
	"share_burn_dps", "share_burn_duration", "share_slow", "share_slow_duration", "share_wet", "share_stun",
]


## The light states shared with a tower boosted by a Nexus. [param boosted]: the other towers
## boosted by the same Nexus amplifiers, each [code]{ "id": StringName, "branch": StringName,
## "level": int }[/code] plus optional [code]"evolved": bool[/code] and [code]"record": int[/code]
## (the [TowerRecord] id). [param values]: the Nexus evolution values ([constant KEYS]). The
## entry whose record is [param self_record] is left out (a tower never receives its own states).
## Returns at most one of each, in this order: [code]{ "state": &"burn", "dps", "duration" }[/code],
## [code]{ "state": &"slow", "factor", "duration" }[/code], [code]{ "state": &"wet", "duration" }[/code],
## [code]{ "state": &"stun", "duration" }[/code]. Never a freeze. A missing value key: an error,
## and that state is not given.
static func shared_states(boosted: Array[Dictionary], values: Dictionary, self_record: int = -1) -> Array[Dictionary]:
	var burn := false
	var slow := false
	var wet := false
	var stun := false
	for tower: Dictionary in boosted:
		if self_record >= 0 and int(tower.get("record", -1)) == self_record:
			continue
		var id: StringName = StringName(tower.get("id", &""))
		var branch: StringName = StringName(tower.get("branch", &""))
		var level: int = int(tower.get("level", 1))
		var evolved: bool = bool(tower.get("evolved", false))
		match id:
			&"cannon":
				burn = burn or (branch == &"incendiaire" and level >= 2)
			&"flamethrower":
				burn = true
			&"frost":
				slow = true
				wet = wet or (branch == &"blizzard" and level >= TowerRecord.MAX_LEVEL)
			&"tesla":
				stun = stun or (branch == &"arc" and level >= 2)
			&"mortar":
				stun = stun or (branch == &"sismique" and level >= TowerRecord.MAX_LEVEL and evolved)
	var states: Array[Dictionary] = []
	if burn and _has_keys(values, ["share_burn_dps", "share_burn_duration"]):
		states.append({"state": &"burn", "dps": float(values["share_burn_dps"]), "duration": float(values["share_burn_duration"])})
	if slow and _has_keys(values, ["share_slow", "share_slow_duration"]):
		states.append({"state": &"slow", "factor": float(values["share_slow"]), "duration": float(values["share_slow_duration"])})
	if wet and _has_keys(values, ["share_wet"]):
		states.append({"state": &"wet", "duration": float(values["share_wet"])})
	if stun and _has_keys(values, ["share_stun"]):
		states.append({"state": &"stun", "duration": float(values["share_stun"])})
	return states


## Sets on [param enemy] the shared states of the amplifier bonuses [param amp] (its
## [code]"shared"[/code] list, see [method shared_states]; none when absent). Ignored on an
## invalid or dying enemy.
static func apply_amp(enemy: Enemy, amp: Dictionary) -> void:
	var shared: Variant = amp.get("shared")
	if shared is Array:
		apply_states(enemy, shared as Array)


## Sets every state of [param states] (built by [method shared_states]) on [param enemy].
static func apply_states(enemy: Enemy, states: Array) -> void:
	for entry: Variant in states:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			return
		var state: Dictionary = entry as Dictionary
		match StringName(state.get("state", &"")):
			&"burn":
				enemy.apply_burn(float(state["duration"]), float(state["dps"]))
			&"slow":
				enemy.apply_timed_slow(float(state["factor"]), float(state["duration"]))
			&"wet":
				enemy.apply_wet(float(state["duration"]))
			&"stun":
				enemy.stun(float(state["duration"]))


static func _has_keys(values: Dictionary, keys: Array) -> bool:
	for key: String in keys:
		if not values.has(key) or values[key] == null:
			push_error("NexusRules: towers.json amplifier.catalyseur.evolution is missing '%s'." % key)
			return false
	return true
