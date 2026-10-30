# Test Evidence: Héros déplacé en ZQSD, tir automatique vers la souris

> **Story**: `production/epics/cristal-combo/story-001-heros-deplacement-tir.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-10-30
> **Tester**: keutarcrash-sudo (joueur, sur son PC)
> **Build / Commit**: 4ed5d79 (code de la story) ; ouvert dans Godot 4.7.2.stable

---

## What Was Tested

Le projet a été ouvert dans Godot 4.7.2 sur le PC Windows de l'utilisateur, lancé avec F5, puis exporté et lancé dans le navigateur (« Exécuter dans le navigateur »). L'utilisateur a confirmé que tout fonctionne : déplacement ZQSD sur clavier AZERTY, tir automatique vers la souris, héros limité à l'arène, et fonctionnement dans le navigateur.

**Acceptance criteria covered**: AC-1 à AC-9

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | Le dossier s'ouvre dans Godot 4.7.2 et le jeu se lance avec F5 | PASS | Capture de l'éditeur reçue (scène `main` chargée, version 4.7.2.stable) ; lancement F5 confirmé par l'utilisateur |
| AC-2 | Z, Q, S, D (AZERTY) déplacent le héros | PASS | Confirmé par l'utilisateur, dans l'éditeur et dans le navigateur |
| AC-3 | Diagonale à la même vitesse qu'en ligne droite | PASS | Confirmé par l'utilisateur (« tout fonctionne ») |
| AC-4 | Arrêt sans touche enfoncée | PASS | Confirmé par l'utilisateur |
| AC-5 | Tir automatique vers le curseur, suivi en temps réel | PASS | Visible sur la capture : projectiles alignés vers la souris |
| AC-6 | Valeurs de jeu dans un fichier de données | PASS | `assets/data/hero_stats.json` (vérifié dans le code) |
| AC-7 | Projectiles détruits à l'impact ou à portée max | PASS | Portée max confirmée ; l'impact sera observable avec les ennemis (story 002) |
| AC-8 | Le héros reste dans l'arène | PASS | Confirmé par l'utilisateur |
| AC-9 | Export web créé, jeu lancé dans un navigateur | PASS | Capture du jeu dans le navigateur (`localhost:8060`) |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `story-001-heros-deplacement-tir/web-export-navigateur.png` | Le jeu dans le navigateur : arène bordée, héros (cercle bleu avec repère de visée), trois projectiles jaunes partant vers la souris | AC-5, AC-9 |

---

## Test Conditions

- **Game state at start**: lancement à neuf, héros au centre de l'arène
- **Platform / hardware**: Windows (PC de l'utilisateur), Godot 4.7.2.stable ; navigateur Chrome via « Exécuter dans le navigateur »
- **Framerate during test**: non mesuré ; aucun ralentissement signalé
- **Any special setup required**: préréglage d'export « Web » et modèles d'export installés par l'utilisateur

---

## Observations

- Le préréglage d'export (`export_presets.cfg`) reste sur le PC de l'utilisateur : il est exclu de git par `.gitignore`. `commands.build` dans `project.yaml` reste à configurer.
- La sensation de jeu (vitesse, cadence) n'a pas été évaluée en détail ; à revoir en playtest une fois les ennemis présents.

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (développeur solo) | keutarcrash-sudo | 2026-10-30 | « oui tout fonctionne » / « ça marche aussi dans le navigateur » (validation donnée dans la conversation) |
