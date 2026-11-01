# Story 010: Maître de la terre et Maître du vent

> **Epic**: Cristal Combo
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief « Après le MVP — Spécialisations et builds », ordre de construction étape 3

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (partie « Après le MVP », lignes Maître de la terre et Maître du vent) :*

- [ ] Les deux spécialisations ont chacune un nœud de déblocage dans la branche « Spécialisations » ; une fois débloquées, elles apparaissent dans l'écran de choix.
- [ ] Maître de la terre : rochers lourds et ondes de choc ; les ennemis touchés sont « ébranlés » (ils reçoivent plus de dégâts pendant un temps donné, état visible).
- [ ] Maître du vent : des rafales repoussent les ennemis ; les ennemis touchés sont « déséquilibrés » (état visible).
- [ ] Combo « trempé + ébranlé = boue » : l'ennemi devient très lent pendant un temps donné.
- [ ] Combo « brûle + vent » : la brûlure se propage aux ennemis proches.
- [ ] Chaque spécialisation a 3 ou 4 cartes à elle, proposées seulement quand elle est choisie.
- [ ] Le recul du vent ne pousse jamais un ennemi hors de l'arène et ne bloque pas la fin d'une vague.
- [ ] États, cartes, combos et coûts sont dans des fichiers de données.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- Le combo « déséquilibré + pièges » arrive avec le Piégeur (story 012).
- Faire valider le contenu précis (cartes, valeurs) par l'utilisateur au démarrage de la story.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011 : Mage du temps, Gardien du cristal.
- Story 012 : pièges du Piégeur.

---

## Files

- `src/specs/`, `src/enemies/enemy.gd`
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

- Depends on: `production/epics/cristal-combo/story-009-maitres-feu-eau.md`
- Unlocks: `production/epics/cristal-combo/story-011-mage-temps-gardien.md`
