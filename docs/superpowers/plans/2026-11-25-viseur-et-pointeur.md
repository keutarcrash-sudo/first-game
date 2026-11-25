# Viseur et pointeur : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer la souris du système par un viseur néon en combat (rose et resserré sur un ennemi) et une flèche stylée BD ailleurs, sans aucun retard.

**Architecture:** `CursorArt` (logique pure, testable) dessine les images au pixel près à partir des réglages de `assets/data/cursor.json`. Un petit nœud `CursorController` les donne au système avec `Input.set_custom_mouse_cursor` selon la phase et le survol d'un ennemi. Les réglages sont en données pour le futur personnalisateur de viseur dans les paramètres.

**Tech Stack:** Godot 4.7.2 / GDScript typé ; JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-25-viseur-et-pointeur-design.md`

## Global Constraints

- Curseur matériel (`Input.set_custom_mouse_cursor`), donc aucun retard. Point chaud au centre exact du viseur et à la pointe de la flèche.
- Viseur en COMBAT uniquement ; flèche dans toutes les autres phases et sur l'écran de défaite (arbre en pause).
- Réglages en JSON validé (null + `push_error` nommant le fichier et la clé) ; dessin en code ; pas d'autoload ; aucun `uid=`/`.uid`/`.import` ; `##` et typage statique.
- Un réglage manquant ou invalide ne bloque pas la partie : on garde la souris du système et on affiche l'erreur.

## Décisions prises pour ce plan

- `assets/data/cursor.json` (forme pensée pour le futur personnalisateur) :
  ```json
  { "crosshair": { "size": 40, "color": "#19e3ff", "hover_color": "#ff2e88", "outline": "#000000",
                   "arm_length": 11, "gap": 6, "hover_gap": 3, "thickness": 3, "outline_px": 2, "dot_radius": 2 },
    "arrow": { "size": 36, "color": "#ffe14d", "outline": "#000000", "outline_px": 3, "shadow_offset": 3 },
    "hover_check_interval": 0.1 }
  ```
- Viseur : quatre branches autour du centre, séparées par `gap` (ou `hover_gap` au survol), plus un point central. Chaque trait reçoit un contour noir de `outline_px`. Image carrée `size`, point chaud `(size/2, size/2)`.
- Flèche : triangle de pointeur classique incliné, pointe en `(outline_px, outline_px)`, contour noir, ombre noire décalée de `shadow_offset`. Point chaud : la pointe.
- La flèche couvre les formes `CURSOR_ARROW` et `CURSOR_POINTING_HAND`, pour que les boutons ne repassent pas sur la main du système. En COMBAT, le viseur remplace `CURSOR_ARROW`.
- Survol d'un ennemi : la position de la souris dans le monde est comparée aux ennemis vivants (centre et rayon du corps) toutes les `hover_check_interval` secondes, et l'image ne change que si l'état change.

## Review Focus

1. **Écran de défaite** (arbre en pause) : la flèche s'affiche, pas le viseur. → Task 2.
2. **Point chaud décalé** : un clic sur le centre du viseur vise exactement ce point. → Task 1 (test du point chaud et du pixel central).
3. **Fichier de réglages absent** : la souris du système reste, rien ne plante. → Task 2.
4. **Relance de partie (Rejouer)** : le curseur repart correctement, pas de viseur coincé. → Task 2.
5. **Taille trop grande** (au-delà de 128 px) : refusée au chargement, car le système ne l'accepterait pas. → Task 1.

## Vérification

Godot indisponible : `tests/unit/ui/cursor_art_check.gd` écrit et relu ; l'utilisateur le lance et joue. Captures dans `production/qa/evidence/viseur/`.

---

### Task 1: Dessin du viseur et de la flèche

**Files:**
- Create: `assets/data/cursor.json`, `src/ui/cursor_art.gd`, `tests/unit/ui/cursor_art_check.gd`

**Interfaces:**
- Produces: `class_name CursorArt extends RefCounted` :
  - `static func load_from_file(path: String) -> CursorArt` ;
  - `static func from_data(data: Variant, source: String) -> CursorArt` ;
  - `func crosshair(hover: bool) -> Image` ;
  - `func crosshair_hotspot() -> Vector2` ;
  - `func arrow() -> Image` ;
  - `func arrow_hotspot() -> Vector2` ;
  - `var hover_check_interval: float`.

- [ ] **Step 1: Write `cursor_art_check.gd`.** Avec le vrai fichier :
  - le viseur est une image de 40 × 40 ;
  - son point chaud est `(20, 20)` ;
  - le pixel central a la couleur du viseur, et rose au survol ;
  - un pixel sur une branche, à `(20 + gap + 2, 20)`, est opaque ;
  - un pixel dans l'écart, à `(20 + gap − 2, 20)`, est transparent quand il n'y a pas de survol ;
  - les coins de l'image sont transparents ;
  - la flèche est une image de 36 × 36 ;
  - son point chaud a un pixel opaque ;
  - `from_data` refuse une `size` supérieure à 128 ou inférieure à 8, une couleur invalide et un `hover_check_interval` ≤ 0.

  Le script affiche `CURSOR_ART OK` ou `CURSOR_ART FAIL: <raison>`, et appelle `quit(1)` en cas d'échec.
- [ ] **Step 2: Run, expect FAIL** — `godot --headless -s res://tests/unit/ui/cursor_art_check.gd` (par l'utilisateur ; dans la session, relecture).
- [ ] **Step 3: Implement** le JSON et `CursorArt`. Le dessin se fait au pixel dans une `Image` RGBA8 : d'abord les formes en noir agrandies de `outline_px`, puis les formes en couleur.
- [ ] **Step 4: Run, expect `CURSOR_ART OK`.**
- [ ] **Step 5: Commit** `feat: dessin du viseur et du pointeur`.

### Task 2: Curseur selon la phase et le survol

**Files:**
- Create: `src/ui/cursor_controller.gd`
- Modify: `src/game/main.gd` (création du nœud, chargement des réglages)

**Interfaces:**
- Consumes: `CursorArt` (Task 1).
- Produces: `class_name CursorController extends Node` — `func setup(art: CursorArt, state: GameState, enemies: Node2D) -> void`.

- [ ] **Step 1: Implement `CursorController`.**
  - Les textures (`ImageTexture`) sont créées une fois : viseur normal, viseur au survol, flèche.
  - Le nœud est en `PROCESS_MODE_ALWAYS`. Il donne le viseur en COMBAT quand l'arbre n'est pas en pause, et la flèche sinon : phase autre que COMBAT, ou arbre en pause pour la défaite. Le survol est vérifié à l'intervalle prévu.
  - À sa sortie de l'arbre (`_exit_tree`), il remet la flèche, pour qu'une relance de partie reparte proprement.
- [ ] **Step 2: Branchement dans `main.gd`.**
  - `main` charge `assets/data/cursor.json`. En cas d'échec, il ne crée pas le nœud : la souris du système reste.
  - Sinon, il crée le contrôleur avec le nœud parent des ennemis.
- [ ] **Step 3: Relecture** — vérifier par la lecture les points 1, 3 et 4 du Review Focus.
- [ ] **Step 4: Commit** `feat: viseur en combat et pointeur stylé`.
- [ ] **Step 5: Playtest de l'utilisateur** :
  - **V-1** le viseur en combat ;
  - **V-2** le viseur rose et resserré sur un ennemi ;
  - **V-3** la flèche jaune dans les menus, la carte et le magasin ;
  - **V-4** la flèche sur l'écran de défaite ;
  - **V-5** pas de retard en visant.
