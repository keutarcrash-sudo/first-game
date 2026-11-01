# Story 009: Maître du feu et Maître de l'eau

> **Epic**: Cristal Combo
> **Status**: In Progress
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-01

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief « Après le MVP — Spécialisations et builds », ordre de construction étape 2

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (partie « Après le MVP », lignes Maître du feu et Maître de l'eau) :*

- [ ] Les deux spécialisations ont chacune un nœud de déblocage dans la branche « Spécialisations » de l'arbre ; une fois débloquées, elles apparaissent dans l'écran de choix.
- [ ] Maître du feu : les tirs du héros enflamment les ennemis (état « brûle » existant).
- [ ] Maître de l'eau : les tirs du héros trempent les ennemis (nouvel état « trempé », visible à l'écran).
- [ ] Combo « trempé + glace = gelé » : un ennemi trempé qui entre dans la zone d'une tour de glace est gelé (immobilisé) pendant un temps donné (données) ; l'état « gelé » est visible.
- [ ] Chaque spécialisation a au moins un combo actif dès cette story ; les combos qui demandent une spécialisation pas encore construite (ex. « brûle + vent ») sont ajoutés dans la story de celle-ci.
- [ ] Chaque spécialisation a 3 ou 4 cartes à elle, proposées seulement quand elle est choisie.
- [ ] États, cartes, combos et coûts de déblocage sont dans des fichiers de données.
- [ ] Le jeu reste fluide avec ces états sur une grosse vague.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- Réutiliser le système de spécialisations de la story 008 et le système de procs.
- Faire valider le contenu précis (cartes, valeurs) par l'utilisateur au démarrage de la story.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 010 : Maître de la terre, Maître du vent, combos « boue » et « brûle + vent ».

---

## Files

- `src/specs/elemental_weapon.gd`
- `src/specs/specialization_catalog.gd`
- `src/specs/specialization_def.gd`
- `src/cards/card_catalog.gd`
- `src/cards/player_modifiers.gd`
- `src/enemies/enemy.gd`
- `src/towers/frost_tower.gd`
- `src/hero/hero.gd`
- `src/hero/hero_bullet.gd`
- `src/game/main.gd`
- `src/meta/death_screen.gd`
- `assets/data/specializations.json`
- `assets/data/cards.json`
- `assets/data/procs.json`
- `assets/data/skill_tree.json`

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

- Depends on: `production/epics/cristal-combo/story-008-specialisations-archer.md`
- Unlocks: `production/epics/cristal-combo/story-010-maitres-terre-vent.md`
