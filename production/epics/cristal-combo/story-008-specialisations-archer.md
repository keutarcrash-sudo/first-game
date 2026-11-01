# Story 008: Système de spécialisations et Archer

> **Epic**: Cristal Combo
> **Status**: In Progress
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-01

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief « Après le MVP — Spécialisations et builds », ordre de construction étape 1

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (partie « Après le MVP », Règles et ligne Archer) :*

- [ ] Avant la vague 1, un écran propose les spécialisations débloquées ; le joueur en choisit une à la souris ; une seule spécialisation par partie.
- [ ] L'Archer est disponible dès la première partie, même sans sauvegarde.
- [ ] Archer : flèches perçantes (elles traversent plusieurs ennemis), longue portée et chance de coup critique ; toutes les valeurs sont dans un fichier de données.
- [ ] État « marqué » : un ennemi touché par un coup critique est marqué pendant un temps donné (données) ; l'état est visible à l'écran.
- [ ] Combo « marqué + tours » : les tours font plus de dégâts aux ennemis marqués ; il passe par le système de procs existant.
- [ ] L'Archer a 3 ou 4 cartes à lui, proposées seulement quand il est la spécialisation choisie.
- [ ] Une branche « Spécialisations » apparaît dans l'arbre de l'écran de défaite ; chaque spécialisation construite ensuite y ajoute son nœud de déblocage par un simple changement de données. L'écran tient toujours dans 1280×720.
- [ ] La spécialisation choisie est affichée pendant la partie.
- [ ] Spécialisations, états, cartes et combos sont décrits dans des fichiers de données.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- Réutiliser les systèmes existants : procs (`src/procs/`), cartes (`src/cards/`), arbre et sauvegarde (`src/meta/`).
- Le second combo de l'Archer (« figé + Archer = critique garanti ») arrive avec le Mage du temps (story 011).
- Faire valider le contenu précis (cartes de l'Archer, valeurs) par l'utilisateur au démarrage de la story.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 009 à 012 : les 8 autres spécialisations.
- Story 013 : équilibrage et finitions.

---

## Files

- `src/specs/specialization_def.gd`
- `src/specs/specialization_catalog.gd`
- `src/specs/archer_weapon.gd`
- `src/specs/specialization_choice_screen.gd`
- `assets/data/specializations.json`
- `assets/data/cards.json`
- `assets/data/procs.json`
- `assets/data/skill_tree.json`
- `src/cards/card_catalog.gd`
- `src/cards/card_def.gd`
- `src/cards/card_pool.gd`
- `src/cards/player_modifiers.gd`
- `src/enemies/enemy.gd`
- `src/game/game_state.gd`
- `src/game/main.gd`
- `src/hero/hero.gd`
- `src/hero/hero_bullet.gd`
- `src/meta/death_screen.gd`
- `src/meta/skill_tree.gd`
- `src/procs/proc_effect.gd`
- `src/ui/crystal_hud.gd`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: test d'intégration OU compte rendu de partie jouée. Les tests automatiques sont facultatifs à `qa.level: minimal`. Une capture de l'écran de choix et de la branche de l'arbre est recommandée.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cristal-combo/story-007-mort-arbre-rejouer.md`
- Unlocks: `production/epics/cristal-combo/story-009-maitres-feu-eau.md`
