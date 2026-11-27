## Whether a tower can evolve, and why not (towers T2b §6). Pure rules: the caller
## passes how to know what the player owns. A tower evolves at level 3, for free, when
## the player owns the item or card its branch's evolution names; an evolution whose
## item or card is reserved to another hero is shown as such.
class_name EvolutionRules
extends RefCounted

const READY := &"ready"
const EVOLVED := &"evolved"
const NEEDS_LEVEL := &"needs_level"
const MISSING := &"missing"
const OTHER_HERO := &"other_hero"
const NO_BRANCH := &"no_branch"


## Evolution status of [param record] of type [param def]: [code]&"evolved"[/code] once
## evolved; [code]&"no_branch"[/code] without a branch or an evolution for it;
## [code]&"needs_level"[/code] below level 3; [code]&"other_hero"[/code] when the
## requirement is reserved to [param spec_of_requirement] and the hero is
## [param hero_spec]; else [code]&"ready"[/code] or [code]&"missing"[/code], from
## [param has_item] / [param has_card] ([code]func(id: String) -> bool[/code]).
static func status(record: TowerRecord, def: TowerDef, has_item: Callable, has_card: Callable, spec_of_requirement: StringName, hero_spec: StringName) -> StringName:
	if record.evolved:
		return EVOLVED
	if record.branch == &"" or def == null or not def.has_evolution(record.branch):
		return NO_BRANCH
	if record.level < TowerRecord.MAX_LEVEL:
		return NEEDS_LEVEL
	if spec_of_requirement != &"" and spec_of_requirement != hero_spec:
		return OTHER_HERO
	var item: String = def.requirement_item(record.branch)
	var owned: bool = bool(has_item.call(item)) if not item.is_empty() else bool(has_card.call(def.requirement_card(record.branch)))
	return READY if owned else MISSING


## What the evolution of [param branch] needs, for the panel: « carte Gel mordant » or
## « objet Poudre noire »; "" when the branch has no evolution.
static func requirement_label(def: TowerDef, branch: StringName) -> String:
	if def == null or not def.has_evolution(branch):
		return ""
	var kind_text: String = "objet" if not def.requirement_item(branch).is_empty() else "carte"
	return "%s %s" % [kind_text, def.requirement_name(branch)]
