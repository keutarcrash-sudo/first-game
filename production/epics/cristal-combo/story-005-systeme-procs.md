# Story 005: Système de procs, avec le premier combo glace + canon

> **Epic**: Cristal Combo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-31

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 6 (système de procs + premier combo ; les 2 autres combos sont dans la story 006)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (MVP feature 6, Build order step 2 — la partie la plus risquée du jeu) :*

- [ ] Un ennemi peut porter des « états » (par exemple « ralenti ») que d'autres effets peuvent lire.
- [ ] Un effet peut déclarer une condition sur un état et un résultat (par exemple : « si l'ennemi est ralenti, dégâts plus élevés »).
- [ ] Premier combo : la tour canon fait plus de dégâts sur un ennemi ralenti ; le multiplicateur est dans un fichier de données (la version GDevelop utilisait 3 au lieu de 1).
- [ ] Le bonus ne s'applique que tant que l'ennemi est ralenti ; hors ralentissement, les dégâts sont normaux.
- [ ] Quand plusieurs conditions s'appliquent au même ennemi, la règle de cumul est unique et documentée dans la story à l'implémentation.
- [ ] Un effet visible se déclenche quand un combo s'active, assez gros pour être remarqué.
- [ ] Les combos sont décrits dans des données, pas codés en dur, pour pouvoir en ajouter dans la story 006 sans changer le système.
- [ ] Des tests automatiques couvrent les dégâts avec et sans état.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md` (valeurs de jeu dans des données, fonctions publiques testables).
- Si ce combo n'est pas amusant à jouer, tout le jeu est à repenser (voir le brief) : le faire jouer à l'utilisateur dès que possible.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.
- **Règle de cumul (décidée le 2026-10-30) :** les bonus s'additionnent, ils ne se multiplient pas. Multiplicateur total = 1 + Σ (multiplicateur_i − 1) sur les combos déclenchés ; par exemple ×3 et ×2 ensemble donnent ×4, pas ×6. Aucun combo déclenché = exactement ×1. Implémentée dans `ProcRules.resolve()`.
- **Moment d'application :** au moment de l'impact du projectile (pas au tir). Les projectiles portent une étiquette de source (`cannon`, `hero`). Ajouter un combo = ajouter une entrée dans `assets/data/procs.json` ; ajouter un état = un cas dans `Enemy.has_state()`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006 : les 2 autres combos et le choix des compétences.

---

## Files

- `src/procs/proc_rules.gd`
- `src/procs/proc_effect.gd`
- `src/enemies/enemy.gd`
- `src/hero/hero_bullet.gd`
- `src/hero/hero.gd`
- `src/towers/cannon_tower.gd`
- `src/towers/tower_placer.gd`
- `src/game/main.gd`
- `assets/data/procs.json`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/cristal-combo/procs_test.gd` — doit exister (`/story-done` vérifie l'existence ; réussite vérifiée plus tard par `/gate-check` et `/smoke-check`). Les tests sont facultatifs à `qa.level: minimal`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cristal-combo/story-004-tours-canon-glace.md`
- Unlocks: `production/epics/cristal-combo/story-006-cartes-competences.md`

---

## Completion Notes
**Completed**: 2026-10-31
**Criteria**: 7/8 passing. Untested criteria: AC-8 (automated tests for damage with and without state — not written, waived at qa.level minimal; gdUnit4 not installed; `ProcRules.resolve()` is scene-tree-free and testable as is). AC-3, AC-4 and AC-6 confirmed by the user; AC-1 and AC-2 demonstrated by the working combo; AC-5 and AC-7 checked by looking (story notes, `ProcRules.resolve` doc comment, `assets/data/procs.json`).
**Deviations**: None. Scope not checked: no uncommitted changes to compare. Cosmetic: the combo label reads "×3.0" instead of "×3" (`String.num` formatting in `proc_effect.gd`). Core-fun check (brief build order step 2): the user found the effect very clear, the combo fun, and ×3 well balanced — the combo design holds.
**Test Evidence**: waived at qa.level minimal (AC-8 untested); retained screenshot `production/qa/evidence/story-005-systeme-procs/combo-glace-canon.png`. Run result: OBSERVED — game launched by the user on Windows/Godot 4.7.2; combo captured: purple ring around a hit enemy next to a cannon and a frost tower, magenta "×3.0" label.
**Reviewed by**: self, no independent review
