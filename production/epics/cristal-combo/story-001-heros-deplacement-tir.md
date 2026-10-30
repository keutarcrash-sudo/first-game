# Story 001: Héros déplacé en ZQSD, tir automatique vers la souris

> **Epic**: Cristal Combo
> **Status**: Complete
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-30

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
- `src/game/main.gd`
- `src/game/main.tscn`
- `src/hero/hero.gd`
- `src/hero/hero.tscn`
- `src/hero/hero_bullet.gd`
- `src/hero/hero_stats.gd`
- `assets/data/hero_stats.json`

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

---

## Completion Notes
**Completed**: 2026-10-30
**Criteria**: 8/9 passing. AC-7 fails in the user's eyes: projectiles are freed at their max range (600 px, `bullet_max_range`) as coded, but they cross the arena border and keep flying outside it; the user wants them stopped at the border. Impact on enemies could not be observed yet (no enemies until story 002).
**Deviations**: Closed with AC-7 failing, by the user's explicit choice ("Clôturer quand même"). OUT OF SCOPE: 12 web-export files (`Cristal Combo.*`, ~38 MB `.wasm`) were committed at the repo root; they are build output, not in `.gitignore`. ADVISORY: aim-line length and width are constants in `hero.gd` (visual only).
**Follow-up**: free a projectile when it leaves the arena rectangle (fold into story 002 or a small fix); remove the export files from git and ignore them.
**Test Evidence**: `production/qa/evidence/story-001-heros-deplacement-tir-evidence.md` + `production/qa/evidence/story-001-heros-deplacement-tir/web-export-navigateur.png`
**Reviewed by**: self, no independent review
