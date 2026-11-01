# Story 011: Mage du temps et Gardien du cristal

> **Epic**: Cristal Combo
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief « Après le MVP — Spécialisations et builds », ordre de construction étape 4

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (partie « Après le MVP », lignes Mage du temps et Gardien du cristal) :*

- [ ] Les deux spécialisations ont chacune un nœud de déblocage dans la branche « Spécialisations » ; une fois débloquées, elles apparaissent dans l'écran de choix.
- [ ] Mage du temps : les ennemis proches du héros sont ralentis ; à intervalle régulier (données), tous les ennemis sont « figés » quelques secondes (état visible).
- [ ] Combo « figé + Archer » : un tir de l'Archer sur un ennemi figé est un coup critique garanti (ajouté au système de procs).
- [ ] Gardien du cristal : un bouclier absorbe une partie des dégâts reçus par le cristal et le cristal se répare lentement ; une aura renforce les tours proches du héros.
- [ ] État « affaibli » : les ennemis proches du cristal font moins de dégâts (valeur en données), état visible.
- [ ] Chaque spécialisation a 3 ou 4 cartes à elle, proposées seulement quand elle est choisie.
- [ ] Les PV du cristal ne dépassent jamais leur maximum, bouclier compris ; le bouclier est visible.
- [ ] États, cartes, combos et coûts sont dans des fichiers de données.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- Le combo « figé + Archer » ne concerne que l'Archer (une seule spécialisation par partie) : il ne se déclenche que si l'Archer est choisi… ce qui exclut le Mage du temps dans la même partie. À clarifier avec l'utilisateur au démarrage (ex. figé par une carte ou une tour plutôt que par le Mage).
- Faire valider le contenu précis (cartes, valeurs) par l'utilisateur au démarrage de la story.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012 : Berserker, Piégeur.

---

## Files

- `src/specs/`, `src/enemies/enemy.gd`, `src/crystal/crystal.gd`, `src/towers/`
- `assets/data/specializations.json`, `assets/data/cards.json`, `assets/data/procs.json`, `assets/data/skill_tree.json`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: test d'intégration OU compte rendu de partie jouée. Les tests automatiques sont facultatifs à `qa.level: minimal`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cristal-combo/story-010-maitres-terre-vent.md`
- Unlocks: `production/epics/cristal-combo/story-012-berserker-piegeur.md`
