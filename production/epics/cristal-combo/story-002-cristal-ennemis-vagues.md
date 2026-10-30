# Story 002: Cristal de 100 PV, ennemis qui le ciblent, vagues croissantes

> **Epic**: Cristal Combo
> **Status**: In Progress
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-30

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 2

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (MVP feature 2, Player goal & fail state, Build order step 1):*

- [ ] Un cristal est présent sur la carte avec 100 PV, et ses PV sont visibles à l'écran.
- [ ] Les ennemis apparaissent par vagues, en bordure de la carte, et foncent vers le cristal.
- [ ] Un ennemi qui touche le cristal lui inflige des dégâts puis disparaît ; aucun ennemi ne reste bloqué contre le cristal sans le blesser (défaut de la version GDevelop).
- [ ] Les tirs du héros blessent les ennemis ; un ennemi à 0 PV meurt.
- [ ] Chaque vague est plus difficile que la précédente (plus d'ennemis ou ennemis plus résistants) ; la courbe est dans un fichier de données.
- [ ] Une vague est terminée quand tous ses ennemis sont morts ou ont touché le cristal.
- [ ] Quand le cristal tombe à 0 PV, la partie s'arrête (l'écran de défaite complet est dans la story 007 ; ici, un message simple suffit).
- [ ] Le jeu reste fluide (aucun ralentissement visible) pendant la plus grosse vague atteinte lors du test.
- [ ] Un projectile du héros est supprimé dès qu'il sort de l'arène (ajouté à la clôture de la story 001, AC-7 : les projectiles traversaient la bordure).

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API (version 4.7 récente).
- Vérifier le défaut connu de la version GDevelop : un ennemi touchant le cristal juste après un autre pouvait rester collé et bloquer la fin de la vague.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003 : phase de construction et or.
- Story 007 : écran de défaite complet.

---

## Files

- `src/crystal/crystal.gd`
- `src/crystal/crystal.tscn`
- `src/enemies/enemy.gd`
- `src/enemies/enemy.tscn`
- `src/waves/wave_spawner.gd`
- `assets/data/waves` (format choisi à l'implémentation)
- `tests/integration/cristal-combo/cristal_ennemis_vagues_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/cristal-combo/cristal_ennemis_vagues_test.gd` OU un compte rendu de partie jouée. Les tests automatiques sont facultatifs à `qa.level: minimal`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cristal-combo/story-001-heros-deplacement-tir.md`
- Unlocks: `production/epics/cristal-combo/story-003-cycle-combat-construction-or.md`
