## One tower owned by the player (towers T1). It lives in the [TowerReserve]
## for the whole run, whether it sits on the map or in the reserve, and keeps
## its level and branch for life.
class_name TowerRecord
extends RefCounted

## Highest upgrade level.
const MAX_LEVEL := 3

## Identifier unique within its reserve.
var id: int = 0
## Tower type: the id of its [TowerDef] ([code]&"cannon"[/code], [code]&"frost"[/code]…).
var kind: StringName = &""
## Upgrade level, 1 to [constant MAX_LEVEL].
var level: int = 1
## Branch id chosen at level 2; [code]&""[/code] at level 1.
var branch: StringName = &""
## True while the tower stands on the map.
var placed: bool = false
## True for a gift tower: it does not raise the price of the next ones.
## Named [code]is_free[/code] because [code]free[/code] is a method of Object.
var is_free: bool = false
