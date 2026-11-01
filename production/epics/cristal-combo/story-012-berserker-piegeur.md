# Story 012: Berserker et Piégeur

> **Epic**: Cristal Combo
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief « Après le MVP — Spécialisations et builds », ordre de construction étape 5

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (partie « Après le MVP », lignes Berserker et Piégeur) :*

- [ ] Les deux spécialisations ont chacune un nœud de déblocage dans la branche « Spécialisations » ; une fois débloquées, elles apparaissent dans l'écran de choix.
- [ ] Berserker : le héros frappe au corps à corps tout autour de lui au lieu de tirer ; il est plus fort quand les PV du cristal sont bas (seuil et bonus en données).
- [ ] État « saigne » : dégâts dans la durée, visible ; combo « saigne + canons » = dégâts en plus.
- [ ] Piégeur : le héros pose tout seul des mines et des pièges sur le chemin des ennemis, avec un nombre maximum en même temps (données).
- [ ] État « piégé » : l'ennemi est immobilisé un temps donné, visible ; combo « piégé + canons » = ×2.
- [ ] Combo « déséquilibré + pièges » : les ennemis déséquilibrés déclenchent les pièges plus facilement (Maître du vent, story 010).
- [ ] Chaque spécialisation a 3 ou 4 cartes à elle, proposées seulement quand elle est choisie.
- [ ] États, cartes, combos et coûts sont dans des fichiers de données.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- Comme pour la story 011, les combos entre deux spécialisations ne peuvent pas se produire dans une même partie (une seule spécialisation) : à clarifier avec l'utilisateur au démarrage (ex. pièges ou recul apportés aussi par des cartes ou des tours).
- Faire valider le contenu précis (cartes, valeurs) par l'utilisateur au démarrage de la story.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 013 : équilibrage et finitions.

---

## Files

- `src/specs/`, `src/enemies/enemy.gd`, `src/hero/hero.gd`
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

- Depends on: `production/epics/cristal-combo/story-011-mage-temps-gardien.md`
- Unlocks: `production/epics/cristal-combo/story-013-equilibrage-finitions.md`
