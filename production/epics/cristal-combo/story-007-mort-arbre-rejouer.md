# Story 007: À la mort, arbre de compétences, sauvegarde navigateur et bouton rejouer

> **Epic**: Cristal Combo
> **Status**: In Progress
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-31

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 7

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (MVP feature 7, Player goal & fail state, Out of scope, Build order step 4) :*

- [ ] Quand le cristal tombe à 0 PV, un écran de défaite s'affiche avec la vague atteinte.
- [ ] Chaque partie rapporte des points ; la formule est dans un fichier de données.
- [ ] L'écran affiche un arbre d'environ 6 améliorations permanentes, reliées entre elles (une amélioration peut en débloquer une autre).
- [ ] Le joueur dépense ses points à la souris sur une amélioration débloquée et assez peu chère ; sinon l'achat est refusé.
- [ ] Les améliorations achetées s'appliquent dès la partie suivante.
- [ ] Points et améliorations sont sauvegardés dans le navigateur et retrouvés après un rechargement de la page. Aucun compte, aucune sauvegarde en ligne.
- [ ] Si la sauvegarde est absente ou illisible, le jeu démarre normalement avec une progression vide, sans erreur.
- [ ] Le bouton « Rejouer » lance une partie neuve (cristal à 100 PV, aucune tour) avec les améliorations achetées.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- Avant de choisir la méthode de sauvegarde pour un export web, lire `docs/engine-reference/godot/` puis la documentation de Godot 4.7 : ne pas la deviner.
- Tester la sauvegarde dans l'export web réel, pas seulement dans l'éditeur.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006 : compétences choisies pendant une partie.
- Hors du MVP (voir le brief) : plus de 6 améliorations, sauvegarde en ligne, comptes.

---

## Files

- `src/meta/skill_tree.gd`
- `src/meta/save_progress.gd`
- `src/meta/death_screen.gd`
- `assets/data/skill_tree.json`
- `assets/data/cards.json`
- `src/cards/card_def.gd`
- `src/cards/card_catalog.gd`
- `src/cards/card_pool.gd`
- `src/cards/card_choice_screen.gd`
- `src/crystal/crystal.gd`
- `src/game/game_state.gd`
- `src/game/wave_cycle.gd`
- `src/game/main.gd`
- `src/ui/crystal_hud.gd`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: une capture d'écran de l'écran de défaite et de l'arbre dans `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cristal-combo/story-006-cartes-competences.md`
- Unlocks: None
