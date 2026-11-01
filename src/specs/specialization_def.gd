## One specialization as described in assets/data/specializations.json (story 008,
## design/game-brief.md « Après le MVP — Spécialisations et builds »). Plain
## data, built and validated by [SpecializationCatalog].
class_name SpecializationDef
extends RefCounted

## Unique id (also used by cards' [code]requires_spec[/code] and the tree's [code]unlock_spec[/code]).
var id: String
## Name shown on the choice screen and in the HUD.
var display_name: String
## What the specialization does, shown on the choice screen.
var description: String
## Short stats line shown on the choice screen.
var stats_line: String
## True when the specialization can be chosen without any tree upgrade.
var available_at_start := false
## Weapon type, one of [constant SpecializationCatalog.WEAPON_NUMBER_KEYS]; the hero builds its weapon from it.
var weapon_type: String
## The weapon's values (the keys listed for [member weapon_type]).
var weapon: Dictionary = {}
## Ids of the combos (procs.json) switched on when this specialization is chosen.
var combo_ids := PackedStringArray()
