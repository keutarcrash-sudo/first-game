# Test Evidence: Héros déplacé en ZQSD, tir automatique vers la souris

> **Story**: `production/epics/cristal-combo/story-001-heros-deplacement-tir.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-10-30
> **Tester**: keutarcrash-sudo (joueur, sur son PC)
> **Build / Commit**: 4ed5d79 (code de la story) ; ouvert dans Godot 4.7.2.stable

---

## What Was Tested

Le projet a été ouvert dans Godot 4.7.2 sur le PC Windows de l'utilisateur, lancé avec F5, puis exporté et lancé dans le navigateur (« Exécuter dans le navigateur »). Chaque critère de comportement a été confirmé un par un par l'utilisateur lors de `/story-done`.

**Acceptance criteria covered**: AC-1 à AC-9

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | Le dossier s'ouvre dans Godot 4.7.2 et le jeu se lance avec F5 | PASS | Capture de l'éditeur (scène `main` chargée, 4.7.2.stable) ; lancement confirmé par l'utilisateur |
| AC-2 | Z, Q, S, D (AZERTY) déplacent le héros | PASS | Confirmé par l'utilisateur à `/story-done` |
| AC-3 | Diagonale à la même vitesse qu'en ligne droite | PASS | Confirmé par l'utilisateur à `/story-done` |
| AC-4 | Arrêt sans touche enfoncée | PASS | Confirmé par l'utilisateur à `/story-done` |
| AC-5 | Tir automatique vers le curseur, suivi en temps réel | PASS | Confirmé par l'utilisateur ; capture : projectiles alignés derrière le héros |
| AC-6 | Valeurs de jeu dans un fichier de données | PASS | `assets/data/hero_stats.json` (vérifié dans le code) |
| AC-7 | Projectiles détruits à l'impact ou à portée max | FAIL (accepté) | Le code libère le projectile à 600 px (`bullet_max_range`), mais l'utilisateur voit les projectiles traverser la bordure de l'arène et continuer ; il veut qu'ils s'arrêtent à la bordure. Impact sur ennemi : non observable avant la story 002 |
| AC-8 | Le héros reste dans l'arène | PASS | Confirmé par l'utilisateur à `/story-done` |
| AC-9 | Export web créé, jeu lancé dans un navigateur | PASS | Capture du jeu dans le navigateur (`localhost:8060`) |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `story-001-heros-deplacement-tir/web-export-navigateur.png` | Le jeu dans le navigateur : arène bordée, héros (cercle bleu avec repère de visée), trois projectiles jaunes partant vers la souris | AC-5, AC-9 |

---

## Test Conditions

- **Game state at start**: lancement à neuf, héros au centre de l'arène
- **Platform / hardware**: Windows (PC de l'utilisateur), Godot 4.7.2.stable ; Chrome via « Exécuter dans le navigateur »
- **Framerate during test**: non mesuré ; aucun ralentissement signalé
- **Any special setup required**: préréglage d'export « Web » et modèles d'export installés par l'utilisateur

---

## Observations

- AC-7 : les projectiles traversent la bordure de l'arène. À corriger (libérer le projectile quand il sort du rectangle de l'arène), dans la story 002 ou par un petit correctif.
- Le préréglage d'export (`export_presets.cfg`) reste sur le PC de l'utilisateur (exclu de git). Les fichiers générés par l'export (`Cristal Combo.*`) ont été commités par erreur à la racine et sont à retirer de git. `commands.build` dans `project.yaml` reste à configurer.
- La sensation de jeu (vitesse, cadence) n'a pas été évaluée en détail ; à revoir en playtest une fois les ennemis présents.

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (développeur solo) | keutarcrash-sudo | 2026-10-30 | [x] Approved — avec l'exception AC-7 acceptée par l'utilisateur à la clôture |
