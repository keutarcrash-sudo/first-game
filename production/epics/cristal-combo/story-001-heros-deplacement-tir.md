# Story 001: Héros déplacé en ZQSD, tir automatique vers la souris

> **Epic**: Cristal Combo
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 1

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (MVP feature 1, Core loop, Build order step 1):*

- [ ] Le dossier du dépôt s'ouvre dans Godot 4.7.2 (`project.godot` présent, rendu « Compatibilité ») et le jeu se lance avec F5.
- [ ] Les touches Z, Q, S, D (telles qu'imprimées sur un clavier AZERTY) déplacent le héros vers le haut, la gauche, le bas et la droite.
- [ ] Le héros se déplace en diagonale à la même vitesse qu'en ligne droite.
- [ ] Le héros s'arrête quand aucune touche n'est enfoncée.
- [ ] Le héros tire seul, sans clic, dans la direction du curseur de la souris ; la direction de tir suit la souris en temps réel.
- [ ] Vitesse du héros, cadence de tir, dégâts et vitesse des projectiles sont dans un fichier de données, pas dans le code.
- [ ] Les projectiles disparaissent à l'impact ou après une portée maximale.
- [ ] Le héros ne peut pas sortir des limites de la carte.
- [ ] Un export web (préréglage « Web ») est créé et le jeu se lance dans un navigateur.

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles du projet : `.claude/docs/coding-standards.md` (valeurs de jeu dans des données, commentaires de documentation sur les fonctions publiques).
- `project.godot` n'existe pas encore : il est à créer au début de cette story (dans Godot, rendu Compatibilité, ou via `/dev-story`).
- Avant d'utiliser une API de Godot, consulter `docs/engine-reference/godot/` : la version 4.7 est postérieure aux connaissances de Claude.
- Vérifier comment lire les touches par leur étiquette (AZERTY) plutôt que par leur position physique sur le clavier.
- Le préréglage d'export « Web » remplit `commands.build` dans `project.yaml` (actuellement « à configurer »).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002 : ennemis, cristal et vagues.
- Story 004 : tours.

---

## Files

- `project.godot`
- `src/hero/hero.gd`
- `src/hero/hero.tscn`
- `src/hero/hero_bullet.gd`
- `assets/data/hero_stats` (format choisi à l'implémentation : Resource `.tres` ou JSON)
- `export_presets.cfg`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: une capture d'écran gardée dans `production/qa/evidence/` + validation dans `production/qa/evidence/story-001-heros-deplacement-tir-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/cristal-combo/story-002-cristal-ennemis-vagues.md`
