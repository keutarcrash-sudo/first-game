# Story 004: Tours canon et glace posées au clic

> **Epic**: Cristal Combo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-30

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 4

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (MVP feature 4, Core loop, Build order step 2):*

- [ ] Pendant la phase de construction, le joueur choisit le type de tour (canon ou glace) puis un clic gauche pose la tour à l'endroit du curseur.
- [ ] Le coût en or est déduit à la pose ; la pose est refusée si l'or est insuffisant.
- [ ] Impossible de poser une tour sur le cristal ou sur une autre tour.
- [ ] Impossible de poser une tour pendant le combat.
- [ ] La tour canon tire sur l'ennemi le plus proche dans sa portée.
- [ ] La tour de glace ralentit les ennemis qui sont dans sa zone ; le ralentissement et la teinte bleue disparaissent quand l'ennemi sort de la zone (défaut de la version GDevelop : la couleur restait bleue).
- [ ] Coût, portée, dégâts, cadence et force du ralentissement sont dans un fichier de données.
- [ ] Les tours posées restent d'une vague à l'autre pendant la partie.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.
- L'état « ralenti » doit pouvoir être lu par d'autres effets : il sera utilisé par la story 005.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005 : dégâts du canon augmentés sur les ennemis ralentis.
- Story 006 : choix de compétence.

---

## Files

- `src/towers/tower_stats.gd`
- `src/towers/tower.gd`
- `src/towers/cannon_tower.gd`
- `src/towers/frost_tower.gd`
- `src/towers/tower_placer.gd`
- `src/enemies/enemy.gd`
- `src/hero/hero_bullet.gd`
- `src/ui/crystal_hud.gd`
- `src/game/main.gd`
- `src/game/main.tscn`
- `assets/data/towers.json`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/cristal-combo/tours_test.gd` OU un compte rendu de partie jouée. Les tests automatiques sont facultatifs à `qa.level: minimal`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cristal-combo/story-003-cycle-combat-construction-or.md`
- Unlocks: `production/epics/cristal-combo/story-005-systeme-procs.md`

---

## Completion Notes
**Completed**: 2026-10-30
**Criteria**: 8/8 passing (AC-7 data file checked by looking at `assets/data/towers.json`; AC-1 to AC-6 and AC-8 confirmed by the user at `/story-done`, AC-1 and AC-8 also visible in the retained screenshot). The "not enough gold" refusal also closed story 003's AC-7.
**Deviations**: None. Scope not checked: no uncommitted changes to compare. Choices by the implementer: towers are built in code (no `cannon_tower.tscn` / `frost_tower.tscn`), plus a small shared `Tower` base class. Contract for story 005: `Enemy.is_slowed() -> bool`; the cannon holds the target in `CannonTower._fire(target)` and `HeroBullet.configure(...)` takes the damage. Polish ideas: range rings of all towers are always drawn (cluttered with many towers); frost towers are close in colour to the hero.
**Test Evidence**: waived at qa.level minimal; retained screenshot `production/qa/evidence/story-004-tours-canon-glace/construction-vague6-tours.png`. Run result: OBSERVED — game launched by the user on Windows/Godot 4.7.2; build phase at wave 6 with 8 cannon towers, 7 frost towers, the two tower buttons and the placement preview.
**Reviewed by**: self, no independent review
