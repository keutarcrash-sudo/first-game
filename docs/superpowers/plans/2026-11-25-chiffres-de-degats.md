# Chiffres de dégâts : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Afficher au-dessus de chaque ennemi touché le nombre de dégâts reçus, coloré selon la source, critiques mis en avant, petits dégâts répétés regroupés.

**Architecture:** Un modèle pur `DamageNumberModel` (RefCounted, testable) reçoit les coups, regroupe les dégâts répétés par ennemi et tient la liste des chiffres vivants. Un seul nœud `DamageNumbers` (Node2D, au-dessus des ennemis) le fait avancer en temps réel et dessine tous les chiffres dans son `_draw`. `Enemy.take_damage` gagne la source et le critique, et signale chaque coup réellement retiré au nœud.

**Tech Stack:** Godot 4.7.2 / GDScript typé ; JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-25-chiffres-de-degats-design.md`

## Global Constraints

- Couleurs : héros blanc `#ffffff`, canon cyan `#19e3ff`, brûlure orange `#ff9a1f`, critique jaune `#ffe14d` plus gros et suivi de « ! ».
- Les dégâts eux-mêmes ne changent pas ; le chiffre affiché est le montant réellement retiré (après Combustion), coup mortel compris.
- Réglages en JSON validé (null + `push_error` nommant le fichier et la clé) ; interface en code ; pas d'autoload ; aucun `uid=`/`.uid`/`.import` écrit ; `##` et typage statique.
- Temps réel (pas ralenti par l'arrêt sur image) ; police Bangers avec contour noir.

## Décisions prises pour ce plan

- `assets/data/damage_numbers.json` :
  ```json
  { "enabled": true,
    "colors": { "hero": "#ffffff", "cannon": "#19e3ff", "burn": "#ff9a1f", "crit": "#ffe14d" },
    "font_size": 22, "crit_font_size": 32, "lifetime": 0.7, "rise_px": 34.0,
    "group_interval": 0.5, "jitter_px": 12.0, "max_on_screen": 60 }
  ```
- Sources (`StringName`) : `&"hero"` (balle du héros, compétences d'impact, effets de cartes), `&"cannon"` (balle des canons), `&"burn"` (brûlure, mur de feu), `&"area"` (dégâts répétés de zone : pluie de flèches). `area` s'affiche en blanc comme `hero`.
- **Regroupés** : `burn` et `area`. Un ennemi garde un cumul par source ; le cumul s'affiche en un seul chiffre quand `group_interval` s'est écoulé depuis le premier dégât du cumul ; un cumul < 1 attend d'atteindre 1. **Immédiats** : `hero`, `cannon`, critiques. À la mort de l'ennemi, son cumul restant (≥ 0,5 arrondi) s'affiche tout de suite.
- Le texte affiché est l'entier arrondi (`roundi`), minimum 1 ; critique : `"%d!"`.
- Au-delà de `max_on_screen`, le chiffre le plus ancien disparaît.
- `Enemy.take_damage(amount: float, heavy: bool = false, source: StringName = &"hero", crit: bool = false)` ; la balle partagée héros/canon passe `&"cannon"` quand sa source de combo est `&"cannon"`, sinon `&"hero"`, et `crit` quand c'est un critique.

## Review Focus

1. **Pluie de flèches ou météore sur 30 ennemis** : pas plus de `max_on_screen` chiffres, aucun ralentissement visible ; les chiffres de zone sont regroupés par ennemi. → Task 1 (plafond, regroupement), Task 2 (relecture).
2. **Ennemi tué par une brûlure** : le cumul de brûlure s'affiche quand même (pas perdu à la mort). → Task 1.
3. **Critique mortel** : chiffre jaune avec « ! » affiché alors que l'ennemi disparaît. → Task 1 / Task 2.
4. **Réglage `enabled: false`** : aucun chiffre, aucun coût. → Task 1.
5. **Fin de vague / relance de partie** : les chiffres restants s'effacent, rien ne reste affiché pendant la construction ou la carte. → Task 2.

## Vérification

Godot indisponible : `tests/unit/ui/damage_numbers_check.gd` écrit et relu ; l'utilisateur le lance et joue. Captures dans `production/qa/evidence/chiffres-de-degats/` : coups du héros, canon, brûlure, critique.

---

### Task 1: Modèle des chiffres et réglages

**Files:**
- Create: `assets/data/damage_numbers.json`, `src/ui/damage_number_model.gd`, `tests/unit/ui/damage_numbers_check.gd`

**Interfaces:**
- Produces: `class_name DamageNumberModel extends RefCounted` :
  - `static func load_from_file(path: String) -> DamageNumberModel` ;
  - `static func from_data(data: Variant, source: String) -> DamageNumberModel` ;
  - `var enabled: bool` ;
  - `func report(key: int, position: Vector2, amount: float, source: StringName, crit: bool, now: float) -> void` (`key` = id de l'ennemi) ;
  - `func flush(key: int, position: Vector2, now: float) -> void` (mort de l'ennemi : affiche ses cumuls) ;
  - `func advance(now: float) -> void` (fait sortir les cumuls mûrs et retire les chiffres expirés) ;
  - `func clear() -> void` ;
  - `func numbers() -> Array[Dictionary]` : chaque entrée `{ "text": String, "color": Color, "font_size": int, "position": Vector2, "age": float }`, avec la position déjà montée de `rise_px × age / lifetime` et le petit décalage au hasard fixé à la création. Le hasard vient d'un `RandomNumberGenerator` passé par `func set_rng(rng: RandomNumberGenerator)`.
  - `func alpha(age: float) -> float` (1 puis fondu vers 0 sur la seconde moitié de `lifetime`).

- [ ] **Step 1: Write `damage_numbers_check.gd`.** Avec le vrai fichier, et un RNG à graine fixe :
  - `report(1, pos, 14.4, &"hero", false, 0)` → un chiffre « 14 » blanc de taille 22 ;
  - `report(…, 30.0, &"hero", true, 0)` → « 30! » jaune de taille 32 ;
  - `&"cannon"` → cyan ;
  - **Brûlure** : `report(2, …, 0.3, &"burn", …, t)` dix fois entre t = 0 et 0.45 → aucun chiffre ; `advance(0.5)` → un seul chiffre orange « 3 » ;
  - **Cumul sous 1** : 0.2 de brûlure puis `advance(0.6)` → aucun chiffre (attend d'atteindre 1) ;
  - **Mort** : `flush(2, …)` affiche un cumul en cours ≥ 0.5 ;
  - **Expiration** : `advance(0.7 + 0.01)` après création → la liste est vide ;
  - **Plafond** : 70 `report` immédiats → 60 chiffres, les plus anciens retirés ;
  - **Désactivé** : `enabled: false` → `report` ne crée rien ;
  - **Fondu** : `alpha(0) == 1` et `alpha(0.7) == 0` ;
  - **`from_data` refuse** une couleur invalide, `lifetime` ≤ 0 et `max_on_screen` < 1.

  Le script affiche `DAMAGE_NUMBERS OK` ou `DAMAGE_NUMBERS FAIL: <raison>`, et appelle `quit(1)` en cas d'échec.
- [ ] **Step 2: Run, expect FAIL** — `godot --headless -s res://tests/unit/ui/damage_numbers_check.gd` (lancé par l'utilisateur ; dans la session, relecture).
- [ ] **Step 3: Implement** le JSON et `DamageNumberModel`.
- [ ] **Step 4: Run, expect `DAMAGE_NUMBERS OK`.**
- [ ] **Step 5: Commit** `feat: modèle des chiffres de dégâts`.

### Task 2: Sources de dégâts et affichage

**Files:**
- Create: `src/ui/damage_numbers.gd`
- Modify:
  - `src/enemies/enemy.gd` : `take_damage`, `_damage` et la brûlure ;
  - `src/hero/hero_bullet.gd` ;
  - `src/abilities/ability_caster.gd` : la pluie de flèches, avec `&"area"` ;
  - `src/abilities/effects/*.gd` : les compétences d'impact, avec `&"hero"` ;
  - `src/cards/card_effects.gd` : avec `&"hero"` ;
  - `src/waves/wave_spawner.gd` : il donne le nœud à chaque ennemi ;
  - `src/game/main.gd` : il crée le nœud et charge les réglages.

**Interfaces:**
- Consumes: `DamageNumberModel` (Task 1).
- Produces:
  - `class_name DamageNumbers extends Node2D`, avec `func setup(model: DamageNumberModel, state: GameState) -> void` et `func report(enemy: Node2D, amount: float, source: StringName, crit: bool) -> void`, `func flush(enemy: Node2D) -> void`.
  - `Enemy.set_damage_numbers(numbers: DamageNumbers) -> void`.
  - `Enemy.take_damage(amount: float, heavy: bool = false, source: StringName = &"hero", crit: bool = false)`.

- [ ] **Step 1: `Enemy`** — `_damage` connaît la source et le critique.
  - Les dégâts de brûlure passent en `&"burn"`, ce qui couvre aussi le mur de feu s'il agit par la brûlure. Vérifie-le par la lecture ; sinon, il passe `&"burn"` explicitement.
  - Après le calcul de Combustion, le montant réellement retiré est signalé au nœud, s'il y en a un.
  - À la mort, `flush` est appelé avant `queue_free`.
  - Les appels existants sans source restent valides grâce aux valeurs par défaut.
- [ ] **Step 2: Points d'appel** — la balle passe `&"cannon"` ou `&"hero"` et `crit` ; la pluie de flèches passe `&"area"` ; les autres gardent `&"hero"`.
- [ ] **Step 3: `DamageNumbers`** :
  - Placement :
    - `z_index` au-dessus des ennemis et des effets ;
    - temps réel via `Time.get_ticks_msec()`.
  - Mise à jour, à chaque image :
    - `advance` ;
    - redessin seulement s'il y a des chiffres.
  - Dessin :
    - `draw_string_outline` noir puis `draw_string` ;
    - police Bangers (`NeonFonts`), couleur avec `alpha(age)`.
  - Phases : `clear()` dès que la phase quitte COMBAT (fin de vague, construction, carte).
  - Ennemis : `WaveSpawner` passe le nœud à chaque ennemi créé.
- [ ] **Step 4: Relecture** — vérifier par la lecture les points 1, 3 et 5 du Review Focus, et que le texte « CRIT ! » existant reste ou soit retiré au profit du chiffre jaune. **Décision : on retire « CRIT ! »**, car le chiffre jaune « 30! » le remplace. On garde le « ×2 » des combos.
- [ ] **Step 5: Commit** `feat: chiffres de dégâts au-dessus des ennemis`.
- [ ] **Step 6: Playtest de l'utilisateur** (captures) :
  - **V-1** les coups du héros en blanc ;
  - **V-2** les coups des canons en cyan ;
  - **V-3** la brûlure en orange, regroupée ;
  - **V-4** les critiques de l'archer en jaune avec « ! » ;
  - **V-5** la pluie de flèches ou le météore reste lisible ;
  - **V-6** plus aucun chiffre hors du combat.
