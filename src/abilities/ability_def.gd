## One ability as described in assets/data/abilities.json (étape 3a). Plain
## data, built and validated by [AbilityCatalog].
class_name AbilityDef
extends RefCounted

## Unique id.
var id: String
## Id of the specialization that owns this ability.
var spec_id: String
## Input slot: [code]&"primary"[/code] (right click), [code]&"a"[/code], [code]&"e"[/code] or [code]&"r"[/code].
var slot: StringName
## Name shown in the HUD.
var display_name: String
## One French sentence describing the ability (shown on the "new ability" card).
var description: String
## Seconds between two uses (above 0).
var cooldown: float
## Ability type, one of the keys of [constant AbilityCatalog.TYPE_NUMBER_KEYS].
var type: String
## The type's numeric values (the keys listed for [member type]).
var values: Dictionary = {}
