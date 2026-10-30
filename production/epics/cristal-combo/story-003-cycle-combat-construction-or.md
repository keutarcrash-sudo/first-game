# Story 003: Cycle combat / construction, or gagné à chaque kill

> **Epic**: Cristal Combo
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 3

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (MVP feature 3, Core loop):*

- [ ] Une partie alterne une phase de combat et une phase de construction.
- [ ] La phase de construction commence quand la vague est terminée (plus aucun ennemi en vie).
- [ ] Il n'y a aucun ennemi pendant la phase de construction, et aucune vague ne démarre pendant le combat précédent.
- [ ] La phase de construction se termine d'une façon claire pour le joueur (minuteur visible ou bouton) ; le choix est documenté dans la story à l'implémentation. La version GDevelop utilisait un minuteur de 8 secondes.
- [ ] Chaque ennemi tué donne de l'or ; la valeur est dans un fichier de données.
- [ ] Un bonus d'or est donné à la fin de chaque vague ; la valeur est dans un fichier de données.
- [ ] L'or ne peut jamais devenir négatif : une dépense plus grande que l'or disponible est refusée.
- [ ] Le numéro de la vague et l'or sont affichés à l'écran.
- [ ] Le numéro de vague augmente à chaque cycle complet.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- La logique du cycle et de l'or doit rester séparée de l'affichage pour pouvoir être testée seule.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004 : poser des tours avec l'or.
- Story 006 : choix de compétence entre les vagues.

---

## Files

- `src/game/game_state.gd`
- `src/game/wave_cycle.gd`
- `src/ui/hud.gd`
- `assets/data/economy` (format choisi à l'implémentation)
- `tests/unit/cristal-combo/cycle_economie_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/cristal-combo/cycle_economie_test.gd` — doit exister (`/story-done` vérifie l'existence ; réussite vérifiée plus tard par `/gate-check` et `/smoke-check`). Les tests sont facultatifs à `qa.level: minimal`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cristal-combo/story-002-cristal-ennemis-vagues.md`
- Unlocks: `production/epics/cristal-combo/story-004-tours-canon-glace.md`
