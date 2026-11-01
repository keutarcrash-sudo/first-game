# Story 013: Équilibrage et finitions

> **Epic**: Cristal Combo
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief « Après le MVP — Spécialisations et builds », ordre de construction étape 6

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (partie « Après le MVP », étape 6, et « Who it's for » : parties de 10 à 15 minutes) :*

- [ ] Or, ennemis et prix de l'arbre sont réglés dans les fichiers de données pour qu'une partie sans amélioration dure environ 10 à 15 minutes ; les valeurs choisies et la raison sont notées dans la story.
- [ ] La ligne « Cartes » de l'affichage ne déborde plus sur l'arène, même avec beaucoup de cartes prises.
- [ ] Le héros ne bouge pas et ne tire pas pendant les écrans de choix (carte, spécialisation).
- [ ] Un double-clic rapide sur « Rejouer » ne relance la partie qu'une seule fois.
- [ ] L'aperçu de pose de la tour de glace montre sa portée réelle (avec les bonus de cartes).
- [ ] Le texte des combos affiche un nombre arrondi (« ×3 » au lieu de « ×3.0 »).

---

## Implementation Notes

- Aucun ADR à ce niveau de rigueur. Règles : `.claude/docs/coding-standards.md`.
- L'équilibrage se fait d'après les parties jouées par l'utilisateur : lui demander ses retours avant de changer les chiffres.
- Consulter `docs/engine-reference/godot/` avant d'utiliser une API.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Nouvelles spécialisations, nouveaux contenus (stories 008 à 012).

---

## Files

- `assets/data/*.json` (économie, vagues, arbre, cartes)
- `src/ui/crystal_hud.gd`, `src/hero/hero.gd`, `src/meta/death_screen.gd`, `src/towers/tower_placer.gd`, `src/procs/proc_effect.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: une capture de chaque écran modifié (affichage pendant la partie, aperçu de pose) dans `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cristal-combo/story-012-berserker-piegeur.md`
- Unlocks: None
