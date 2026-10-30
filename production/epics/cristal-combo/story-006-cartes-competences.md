# Story 006: Choix d'1 compétence parmi 3 entre les vagues, avec 2 autres combos

> **Epic**: Cristal Combo
> **Status**: Ready
> **Layer**: Feature
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

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

- `src/cards/card_pool.gd`
- `src/cards/card_choice_screen.gd`
- `src/cards/card_choice_screen.tscn`
- `assets/data/cards` (format choisi à l'implémentation)
- `assets/data/procs` (combos ajoutés)

---

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
