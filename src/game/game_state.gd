## Run state (story 003, design/game-brief.md MVP feature 3): gold, wave number
## and combat/build phase. Plain logic, no UI and no scene tree, so it can be
## unit-tested alone. Display and other systems listen to its signals.
class_name GameState
extends RefCounted

## Emitted when the gold amount changes.
signal gold_changed(gold: int)
## Emitted when the phase changes.
signal phase_changed(phase: Phase)
## Emitted when the current wave number changes.
signal wave_changed(wave_number: int)

## CARD_CHOICE sits between a finished wave and BUILD: the player picks a card (story 006).
## SPEC_CHOICE is the specialization choice at the start of the game (story 008).
enum Phase { COMBAT, BUILD, CARD_CHOICE, SPEC_CHOICE }

## Gold owned. Never negative.
var gold: int
## Current wave: the one being fought, or just finished during BUILD. Starts at 1
## (the first wave, announced during the opening COMBAT countdown).
var wave_number := 1
## Current phase. The game starts in COMBAT.
var phase := Phase.COMBAT
## Waves finished during this game (end-of-game points, story 007).
var waves_completed := 0
## Enemies killed during this game (end-of-game points, story 007).
var kills := 0


func _init(starting_gold: int) -> void:
	gold = maxi(starting_gold, 0)


## Adds [param amount] gold. A negative amount is ignored: use [method spend_gold].
func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)


## Spends [param amount] gold. Returns [code]false[/code] and changes nothing
## when the gold is insufficient (or the amount is negative).
func spend_gold(amount: int) -> bool:
	if amount < 0 or amount > gold:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


## Enters COMBAT for wave [param new_wave_number].
func begin_combat(new_wave_number: int) -> void:
	if wave_number != new_wave_number:
		wave_number = new_wave_number
		wave_changed.emit(wave_number)
	_set_phase(Phase.COMBAT)


## Enters CARD_CHOICE (the wave is finished, a card is to be picked).
func begin_card_choice() -> void:
	_set_phase(Phase.CARD_CHOICE)


## Enters SPEC_CHOICE (start of the game, before wave 1).
func begin_spec_choice() -> void:
	_set_phase(Phase.SPEC_CHOICE)


## Enters BUILD (the card, if any, is chosen).
func begin_build() -> void:
	_set_phase(Phase.BUILD)


func _set_phase(new_phase: Phase) -> void:
	if phase == new_phase:
		return
	phase = new_phase
	phase_changed.emit(phase)
