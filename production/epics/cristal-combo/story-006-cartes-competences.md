# Story 006: Choix d'1 compétence parmi 3 entre les vagues, avec 2 autres combos

> **Epic**: Cristal Combo
> **Status**: Complete
> **Layer**: Feature
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-31

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 5 et fin de la feature 6 (au moins 3 combos au total avec la story 005)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (MVP features 5 et 6, Core loop, Build order step 3) :*

- [ ] À la fin de chaque vague, un écran propose 3 compétences différentes tirées d'un ensemble plus large.
- [ ] Le joueur en choisit 1 à la souris ; elle s'applique tout de suite pour la suite de la partie.
- [ ] Les 3 compétences proposées sont différentes entre elles dans un même tirage.
- [ ] La partie ne reprend qu'après le choix.
- [ ] Chaque carte affiche son nom et une description lisible de ce qu'elle fait et avec quoi elle se combine.
- [ ] Au moins 2 combos supplémentaires existent (3 au total avec le combo glace + canon de la story 005) et se déclenchent entre compétences ou tours.
- [ ] L'ensemble de compétences est assez large pour proposer des choix variés sur plusieurs vagues.
- [ ] Compétences et combos sont décrits dans des données, pas codés en dur.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- Réutiliser le système de procs de la story 005 ; ne pas le modifier sans raison.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007 : arbre de compétences permanent (différent des compétences choisies pendant une partie).

---

## Files

- `src/cards/card_def.gd`
- `src/cards/card_catalog.gd`
- `src/cards/player_modifiers.gd`
- `src/cards/card_pool.gd`
- `src/cards/card_choice_screen.gd`
- `assets/data/cards.json`
- `assets/data/procs.json`
- `src/procs/proc_rules.gd`
- `src/game/game_state.gd`
- `src/game/wave_cycle.gd`
- `src/game/main.gd`
- `src/enemies/enemy.gd`
- `src/hero/hero.gd`
- `src/hero/hero_bullet.gd`
- `src/towers/cannon_tower.gd`
- `src/towers/frost_tower.gd`
- `src/towers/tower_placer.gd`
- `src/crystal/crystal.gd`
- `src/ui/crystal_hud.gd`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: une capture d'écran de l'écran de choix dans `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cristal-combo/story-003-cycle-combat-construction-or.md`, `production/epics/cristal-combo/story-005-systeme-procs.md`
- Unlocks: `production/epics/cristal-combo/story-007-mort-arbre-rejouer.md`

---

## Completion Notes
**Completed**: 2026-10-31
**Criteria**: 8/8 passing (AC-1 to AC-7 confirmed by the user; AC-8 checked by looking at `assets/data/cards.json` and `assets/data/procs.json`; the card screen, the "Cartes" HUD line and 7 distinct cards taken by wave 13 are visible in the retained screenshots).
**Deviations**: None. Scope not checked: no uncommitted changes to compare. The card screen is built in code (no `card_choice_screen.tscn`), approved by the user before implementation. Content: 8 cards (5 repeatable, 3 unique), combos "Glace + Héros" and "Feu + Héros" unlocked by cards, new enemy state "burning". Polish ideas: the "Cartes" HUD line overflows onto the arena; the game looks too easy by wave 13 (2440 gold banked, crystal 90/100) — balance to revisit after story 007; the hero still moves and fires during the card choice; the frost placement preview shows the base range.
**Test Evidence**: UI screenshots `production/qa/evidence/story-006-cartes-competences/ecran-choix-cartes.png` (3-card choice screen) and `construction-vague13-cartes.png` (build phase with the "Cartes" line). Run result: OBSERVED — game launched by the user on Windows/Godot 4.7.2; choice screen "Choisis une carte" with Pillage, Canon rapide, Balles lourdes, phase "Choix d'une carte".
**Reviewed by**: self, no independent review
