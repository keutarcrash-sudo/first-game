# Barre de compétences « badges pop » : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redessiner la barre de compétences en pastilles rondes style BD néon pop (couleur par rôle, icône par compétence, horloge de recharge, respiration, pop, cadenas).

**Architecture:** Les réglages visuels sont dans `assets/data/ability_bar.json`, lus par une petite classe `AbilityBarStyle`, qui porte aussi les calculs purs (taille de la respiration, du pop, part de l'horloge, hauteur de la bande du bas) afin de les tester. `AbilityIcons` dessine les 12 icônes et le cadenas en traits. `AbilityBar` reste un `Control` qui dessine tout dans `_draw`, comme aujourd'hui.

**Tech Stack:** Godot 4.7.2 / GDScript typé ; JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-21-barre-competences-pop-design.md` — maquette : https://claude.ai/artifact/F2YvCU467PW3Lj16C62tpu (piste B).

## Global Constraints

- Couleurs par rôle, identiques pour tous les héros : `primary` rose `#ff2e88`, `a` cyan `#19e3ff`, `e` violet `#b44bff`, `r` jaune `#ffe14d` ; verrouillée gris `#3a3456`.
- Interface en code ; réglages en JSON validé (null + `push_error` nommant le fichier et la clé) ; pas d'autoload ; aucun `uid=`/`.uid`/`.import` écrit par les agents ; `##` et typage statique.
- `AbilityBar.bottom_band_height(...)` reste **la seule source** de la hauteur de la bande du bas (la caméra s'en sert pour garder le cristal visible).
- Pas de changement des compétences, des touches, des recharges ni de la place de la barre ; pas de clic sur les pastilles.

## Décisions prises pour ce plan

- `assets/data/ability_bar.json` :
  ```json
  { "role_colors": { "primary": "#ff2e88", "a": "#19e3ff", "e": "#b44bff", "r": "#ffe14d" },
    "locked_color": "#3a3456",
    "key_labels": { "primary": "CLIC D.", "a": "A", "e": "E", "r": "R" },
    "disc_diameter": 72.0, "spacing": 34.0, "outline_px": 5.0, "shadow_offset": [6.0, 6.0], "glow_alpha": 0.45,
    "name_font_size": 18, "key_font_size": 18, "cooldown_font_size": 34, "name_gap": 6.0,
    "bottom_margin": 120.0, "band_margin": 18.0,
    "breath": { "period": 1.6, "amount": 0.05 },
    "pop": { "duration": 0.25, "scale": 1.25 } }
  ```
- Hauteur de la bande = `bottom_margin + disc_diameter + name_gap + name_font_size × 1.2 + band_margin` (band_margin relevé à 18 après relecture : étiquette penchée et pop) (le nom est sous la pastille ; l'étiquette de touche dépasse en haut de moins de la moitié de sa hauteur et reste dans la marge).
- Respiration : échelle `1 + amount × (0.5 − 0.5 cos(2π t / period))` (de 1 à 1 + amount). Pop : à la fin d'une recharge, échelle qui décroît de `pop.scale` à 1 sur `pop.duration` (ease-out), avec un flash blanc qui s'éteint sur la même durée ; pendant le pop, pas de respiration.
- Horloge : part sombre = `cooldown_left / cooldown_total`, partant de midi dans le sens des aiguilles d'une montre ; chiffre = `ceili(cooldown_left)`.
- `AbilityCaster` gagne `cooldown_total(slot) -> float` : la recharge réelle (avec les cartes) enregistrée au moment du lancer ; 0 si aucune.

## Review Focus

1. **Recharge réduite par une carte** : l'horloge part bien du plein (elle se base sur la recharge réelle, pas celle des données). → Task 2 (`cooldown_total` enregistrée au lancer).
2. **Compétence débloquée en cours de partie** (carte « Nouvelle compétence ») : la pastille passe de grise avec cadenas à colorée, sans pop parasite. → Task 2.
3. **Changement de phase pendant une recharge** (fin de vague) : pas de pop au passage en construction si la recharge n'est pas finie ; le chiffre reste juste. → Task 2.
4. **Nom long** (« Pluie de flèches », « Raz-de-marée ») : tient sous la pastille sans chevaucher la voisine (taille de police réduite ou deux lignes au besoin). → Task 2.
5. **Réglages invalides** (couleur illisible, rôle manquant, taille ≤ 0) : chargement refusé avec un message clair, et la partie ne démarre pas comme pour les autres fichiers. → Task 1 (`ability_bar_style_check`).

## Vérification

Godot indisponible dans la session : le contrôle `tests/unit/ui/ability_bar_style_check.gd` est écrit et lu ; l'utilisateur le lance et joue. Captures dans `production/qa/evidence/barre-competences/` : barre de chaque héros prête, en recharge et avec une compétence verrouillée.

---

### Task 1: Réglages et calculs de la barre

**Files:**
- Create: `assets/data/ability_bar.json`, `src/ui/ability_bar_style.gd`, `tests/unit/ui/ability_bar_style_check.gd`

**Interfaces:**
- Produces: `class_name AbilityBarStyle extends RefCounted` :
  - `static func load_from_file(path: String) -> AbilityBarStyle` ;
  - `static func from_data(data: Variant, source: String) -> AbilityBarStyle` ;
  - champs typés pour chaque clé du JSON (`role_colors: Dictionary` StringName → Color, `locked_color: Color`, `key_labels: Dictionary`, `disc_diameter: float`, `shadow_offset: Vector2`, …) ;
  - `func color_of(slot: StringName) -> Color` ;
  - `func bottom_band_height() -> float` ;
  - `func breath_scale(time: float) -> float` ;
  - `func pop_scale(since_ready: float) -> float` (1.0 dès que `since_ready ≥ pop.duration` ou < 0) ;
  - `func pop_flash(since_ready: float) -> float` (alpha de 1 à 0 sur la même durée) ;
  - `static func cooldown_fraction(left: float, total: float) -> float` (bornée à [0, 1], 0 si `total ≤ 0`).

- [ ] **Step 1: Write `ability_bar_style_check.gd`.** Avec le vrai fichier :
  - `color_of(&"a") == Color("#19e3ff")` ;
  - `bottom_band_height() == 120 + 72 + 6 + 18 × 1.2 + 18` ;
  - `breath_scale(0) == 1`, `breath_scale(0.8)` ≈ 1.05, `breath_scale(1.6)` ≈ 1 ;
  - `pop_scale(0) == 1.25`, `pop_scale(0.25) == 1`, `pop_scale(-1) == 1` ;
  - `pop_flash(0) == 1`, `pop_flash(0.25) == 0` ;
  - `cooldown_fraction(3, 6) == 0.5`, `(7, 6) == 1`, `(1, 0) == 0`.

  `from_data` refuse (null) :
  - un rôle manquant dans `role_colors` ;
  - une couleur non valide ;
  - `disc_diameter` ≤ 0 ;
  - `breath.period` ≤ 0.

  Le contrôle affiche `ABILITY_BAR_STYLE OK` ou `ABILITY_BAR_STYLE FAIL: <raison>` et appelle `quit(1)` en cas d'échec.
- [ ] **Step 2: Run, expect FAIL** — `godot --headless -s res://tests/unit/ui/ability_bar_style_check.gd` (lancé par l'utilisateur ; dans la session, relecture).
- [ ] **Step 3: Implement** le JSON et `AbilityBarStyle`.
- [ ] **Step 4: Run, expect `ABILITY_BAR_STYLE OK`.**
- [ ] **Step 5: Commit** `feat: réglages de la barre de compétences`.

### Task 2: Pastilles, icônes et animations

**Files:**
- Create: `src/ui/ability_icons.gd`
- Modify: `src/ui/ability_bar.gd`, `src/abilities/ability_caster.gd`, `src/ui/crystal_hud.gd` (création de la barre), `src/game/main.gd` (chargement du style, appel de `bottom_band_height`), `src/game/game_camera.gd` (doc seulement si la référence change)

**Interfaces:**
- Consumes: `AbilityBarStyle` (Task 1).
- Produces:
  - `class_name AbilityIcons` : `static func draw_icon(canvas: CanvasItem, ability_id: String, center: Vector2, size: float, color: Color, width: float) -> void` (12 identifiants de `abilities.json`) ; `static func draw_lock(...)` (même signature, sans `ability_id`). Un identifiant inconnu dessine un « ? » sans planter.
  - `AbilityCaster.cooldown_total(slot: StringName) -> float`.
  - `AbilityBar.setup(caster: AbilityCaster, style: AbilityBarStyle)` ; `static func bottom_band_height(style: AbilityBarStyle) -> float` (délègue au style ; `main` charge le style une fois et le passe à la barre et à la caméra).

- [ ] **Step 1: `AbilityCaster`** — enregistrer la recharge réelle au lancer, exposer `cooldown_total`.
- [ ] **Step 2: `AbilityIcons`** — 12 icônes reconnaissables en traits noirs épais, dans l'esprit de la maquette :
  - flèche perforante, roulade, pluie de flèches, œil du chasseur ;
  - boule de feu, bond enflammé, mur de feu, météore ;
  - vague, glissade, flaque, raz-de-marée ;
  - plus le cadenas.
- [ ] **Step 3: `AbilityBar`** — rendu par emplacement, de l'arrière vers l'avant :
  1. ombre décalée ;
  2. halo ;
  3. disque de la couleur du rôle et contour noir ;
  4. icône ;
  5. horloge sombre et chiffre en recharge ;
  6. étiquette jaune penchée avec la touche, en haut à droite ;
  7. nom en Bangers avec un contour noir, sous la pastille.

  Pour les états :
  - **verrouillée** : couleur `locked_color`, cadenas et nom grisé ;
  - **prête** : respiration ;
  - **passage de la recharge à prête** : pop et flash, détectés en comparant la recharge restante d'une image à l'autre et seulement pendant le combat ;
  - **débloquée en cours de partie** : pas de pop.

  Pour l'affichage :
  - redessin à chaque image (`_process`) tant qu'une pastille respire, est en recharge ou fait son pop ;
  - un nom trop large pour la place disponible passe en police plus petite.
- [ ] **Step 4: Branchement** — `main` charge `assets/data/ability_bar.json` (échec = même arrêt que les autres données), passe le style au HUD et à `_camera.setup(..., AbilityBar.bottom_band_height(style))`.
- [ ] **Step 5: Relecture** — vérifier par la lecture les points 1 à 4 du Review Focus.
- [ ] **Step 6: Commit** `feat: barre de compétences en badges pop`.
- [ ] **Step 7: Playtest de l'utilisateur** (captures dans `production/qa/evidence/barre-competences/`) :
  - **V-1** les trois héros affichent leurs 4 icônes et les bonnes couleurs ;
  - **V-2** l'horloge et le chiffre pendant une recharge ;
  - **V-3** le pop à la fin d'une recharge ;
  - **V-4** le cadenas, puis le déblocage par carte ;
  - **V-5** le cristal reste toujours au-dessus de la barre.
