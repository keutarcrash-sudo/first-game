# Étape 4 — Danger pour le héros : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Le héros a des PV et peut mourir ; deux nouveaux ennemis (kamikaze, artilleur) créent des zones de danger annoncées au sol ; types d'ennemis en données ; cartes de survie.

**Architecture:** La logique de vie du héros est une petite classe pure `HeroHealth` (testable) tenue par `Hero`. Les attaques annoncées passent par un nœud réutilisable `TelegraphZone` (cercle qui se remplit puis frappe). Les types d'ennemis sont décrits dans `assets/data/enemy_types.json` (multiplicateurs par rapport au gobelin de `defence_stats.json`, comportement, planche) ; `Enemy` lit son type et délègue le comportement particulier à de petits composants (`KamikazeBehaviour`, `ArtilleryBehaviour`). La fabrique d'images produit le zombie et la soucoupe.

**Tech Stack:** Godot 4.7.2 / GDScript typé ; JSON dans `assets/data/` ; fabrique `tools/sprite_baker/`.

**Spec:** `docs/superpowers/specs/2026-11-20-etape-4-danger-heros-design.md`

## Global Constraints

- Données JSON validées (null + `push_error` nommant le fichier et la clé), interface en code, pas d'autoload, pas de `uid=`/`.uid`/`.import` écrits par les agents ; `##` et typage statique partout.
- Les gobelins et tout le reste du jeu gardent **exactement** leurs règles (spec §4, §9).
- Toutes les valeurs des tables de la spec (§5, §6, §7, §7bis) **exactement**, en données.
- Tous les ennemis visent le cristal ; aucune attaque sans annonce visible ; les ennemis libérés sont ignorés ; la fin de vague efface ennemis et annonces sans dégâts.
- Cercles = rayons ; le héros est touché si son corps chevauche le cercle ; le cristal est touché si son centre est dans le cercle (spec §7bis).

## Décisions prises pour ce plan

- `assets/data/hero_stats.json` gagne `"hero_max_hp": 100.0` et `"hit_invulnerability": 0.5`.
- `assets/data/enemy_types.json` :
  ```json
  { "types": [
      { "id": "goblin", "hp_mult": 1.0, "speed_mult": 1.0, "sheet": "res://assets/sprites/goblin", "height_px": 84.0, "behaviour": "contact", "start_wave": 1, "base_count": -1 },
      { "id": "kamikaze", "hp_mult": 0.6, "speed_mult": 1.4, "sheet": "res://assets/sprites/zombie", "height_px": 84.0, "behaviour": "kamikaze", "start_wave": 3, "base_count": 1, "per_wave": 1.0,
        "fuse": 0.6, "radius": 90.0, "crystal_damage": 20.0, "hero_damage": 25.0 },
      { "id": "artilleur", "hp_mult": 1.5, "speed_mult": 0.8, "sheet": "res://assets/sprites/ufo", "height_px": 84.0, "behaviour": "artillery", "start_wave": 5, "base_count": 1, "per_wave": 0.5,
        "stand_off": 350.0, "fire_interval": 3.0, "telegraph": 1.2, "radius": 70.0, "aim_spread": 60.0, "crystal_damage": 10.0, "hero_damage": 20.0 } ] }
  ```
  `base_count: -1` = le nombre actuel de `waves.json` (gobelins inchangés). Nombre d'un type à la vague `w ≥ start_wave` : `base_count + floor(per_wave × (w − start_wave))`.
- Mort du héros : la vague se fige (`WaveSpawner.freeze()` : plus d'apparitions, ennemis et annonces immobiles), animation `death` du héros, puis la même défaite que le cristal (une fonction `main._lose()` partagée).

## Review Focus

1. **Coup reçu pendant un saut ou pendant l'invincibilité** : aucun dégât, aucun flash. → Task 1 (contrôle `HeroHealth`).
2. **Héros et cristal tombent à 0 dans la même image** : une seule défaite, un seul écran. → Task 1.
3. **Fin de vague pendant une mèche ou une annonce** : rien ne frappe, rien ne reste à l'écran. → Task 2 / Task 4.
4. **Kamikaze tué pendant sa mèche** (par une compétence, une brûlure, un canon) : pas d'explosion ; or et effets normaux. → Task 4.
5. **Artilleur qui suit un cristal qui avance** : reste à environ 350 px, ne se colle pas, ne sort pas du terrain. → Task 4.

## Vérification

Godot indisponible : contrôles de logique `tests/unit/**/…_check.gd` écrits pour être lancés par l'utilisateur, relectures `godot-gdscript-specialist`, planches de la fabrique regardées dans la session, partie de l'utilisateur (V-1…V-8, fin de Task 5) avec captures dans `production/qa/evidence/story-020-danger-heros/`.

---

### Task 1: PV du héros, invincibilité, défaite

**Files:**
- Create: `src/hero/hero_health.gd`, `tests/unit/hero/hero_health_check.gd`, `src/ui/hero_health_bar.gd`
- Modify: `assets/data/hero_stats.json`, `src/hero/hero_stats.gd`, `src/hero/hero.gd`, `src/game/main.gd`, `src/ui/crystal_hud.gd`, `src/waves/wave_spawner.gd` (`freeze()`), `src/ui/stats_panel.gd` (ligne PV max)

**Interfaces:**
- Produces:
  - `class_name HeroHealth extends RefCounted` — `signal changed(current: float, max_hp: float)`, `signal died` ; `func _init(max_hp: float, invulnerability: float)` ; `func take_hit(amount: float, dashing: bool) -> bool` (false si mort, en saut ou invincible ; sinon retire les PV, arme l'invincibilité, émet `changed`, et `died` une seule fois à 0) ; `func tick(delta: float) -> void` (fait descendre l'invincibilité, applique la régénération) ; `func heal(amount: float) -> void` ; `func add_max(amount: float) -> void` (+max et soigne d'autant) ; `func set_regen(per_second: float) -> void` ; `func is_invulnerable() -> bool` ; `var current: float`, `var max_hp: float`.
  - `Hero.health() -> HeroHealth` ; `Hero.hurt(amount: float) -> void` (appelle `take_hit` avec `is_dashing()`, flash rouge + `ImpactFeedback.shake(&"small")` si touché) ; le héros clignote pendant l'invincibilité ; `Hero.signal died`.
  - `WaveSpawner.freeze() -> void`.
  - `main._lose() -> void` : appelée par la destruction du cristal et par la mort du héros (après l'animation `death`, ~0,8 s, jamais deux fois).

- [ ] **Step 1:** `hero_health_check.gd` (`extends SceneTree`, `HERO_HEALTH OK` / `HERO_HEALTH FAIL: <nom>`, `quit(1)` si échec) : 100 PV, `take_hit(25,false)` → 75 et true ; second `take_hit` aussitôt → false (invincible) ; `tick(0.5)` puis `take_hit` → true ; `take_hit(10,true)` → false (saut) ; `died` émis une seule fois en descendant à 0 puis en recevant d'autres coups ; `heal` ne dépasse pas le max ; `add_max(25)` → max 125 et +25 PV.
- [ ] **Step 2:** Implémenter `HeroHealth`, l'intégration `Hero`, la barre de PV (à côté de celle du cristal), `freeze()`, `_lose()`, la ligne PV max du panneau.
- [ ] **Step 3:** Relecture puis commit `feat: PV du héros, invincibilité et défaite`.

### Task 2: Attaques annoncées (`TelegraphZone`)

**Files:**
- Create: `src/hazards/telegraph_zone.gd`

**Interfaces:**
- Produces: `class_name TelegraphZone extends Node2D` — `signal impacted(center: Vector2)` ; `func setup(radius: float, duration: float, state: GameState, follow: Node2D = null) -> void` (si `follow` est donné, le cercle suit ce nœud tant qu'il existe) ; dessin : disque rouge translucide `Color(1.0, 0.2, 0.3, 0.25)` + contour `Color(1.0, 0.25, 0.35)` 3 px et contour noir 5 px dessous, remplissage du centre vers le bord sur `duration` ; à la fin émet `impacted` puis se libère ; se libère sans frapper si la phase quitte COMBAT ou si `cancel()` est appelée ; `func cancel() -> void`.
  - Helpers statiques : `static func hits_body(center: Vector2, radius: float, body_pos: Vector2, body_radius: float) -> bool` ; `static func hits_point(center: Vector2, radius: float, point: Vector2) -> bool`.

- [ ] **Step 1:** Implémenter, avec un contrôle `tests/unit/hazards/telegraph_check.gd` des deux helpers (bords inclus).
- [ ] **Step 2:** Relecture puis commit `feat: zones d'attaque annoncées`.

### Task 3: Planches du zombie et de la soucoupe

**Files:**
- Modify: `tools/sprite_baker/recipes.json`, `tools/sprite_baker/page.html` (animations synthétiques pour modèle fixe), `tools/sprite_baker/README.md`
- Create (produits) : `assets/sprites/zombie/`, `assets/sprites/ufo/`

**Interfaces:**
- Produces: `assets/sprites/zombie/sheet.json` (8 directions, `run` = `Walk` du pack, `punch`, `hit`, `death`) et `assets/sprites/ufo/sheet.json` (8 directions, `run` = rotation sur soi + oscillation 8 images, `hit` = secousse 4 images, `death` = rétrécit en tournant 10 images sans boucle) ; palettes : zombie selon spec graphique §8.1 (`Zombie_Male`), soucoupe recolorée néon (coque violette, dôme cyan, lumières roses).

- [ ] **Step 1:** Recettes + animations synthétiques ; lancer la fabrique ; regarder la planche de contrôle (directions, rien de coupé).
- [ ] **Step 2:** Commit `feat: planches du zombie et de la soucoupe`.

### Task 4: Types d'ennemis, kamikaze, artilleur

**Files:**
- Create: `assets/data/enemy_types.json`, `src/enemies/enemy_types.gd`, `src/enemies/kamikaze_behaviour.gd`, `src/enemies/artillery_behaviour.gd`
- Modify: `src/enemies/enemy.gd`, `src/waves/wave_spawner.gd`, `src/crystal/crystal.gd`, `src/game/main.gd`

**Interfaces:**
- Consumes: `TelegraphZone` (Task 2), `Hero.hurt` (Task 1), planches (Task 3), `PopBurst.spawn`, `ImpactFeedback`.
- Produces:
  - `class_name EnemyTypes extends RefCounted` — `static func load_from_file(path) -> EnemyTypes` ; `func all() -> Array[Dictionary]` ; `func count_for(type_id: String, wave: int, base_count: int) -> int`.
  - `Enemy.setup_type(type: Dictionary, hero: Hero, impact: ImpactFeedback, hazards_parent: Node) -> void` (multiplicateurs appliqués à PV et vitesse ; crée le composant de comportement si besoin).
  - `Crystal.predicted_position(seconds: float) -> Vector2` (position le long du trajet après `seconds`, ou la position actuelle s'il ne voyage pas).
  - Kamikaze : au contact, s'arrête (plus de dégâts de contact), crée une `TelegraphZone` qui le suit (mèche), à l'impact : `crystal.take_damage(crystal_damage)`, `hero.hurt(hero_damage)` si `hits_body`, « KABOUM ! » + `shake(&"big")` si le héros est touché sinon `&"small"`, puis se libère **sans** `died` (pas d'or) ; tué pendant la mèche → `cancel()`, mort normale.
  - Artilleur : avance vers le cristal jusqu'à `stand_off`, puis maintient cette distance en suivant le cristal (reste dans le terrain) ; toutes les `fire_interval` s : `TelegraphZone` fixe de `radius` centrée sur `crystal.predicted_position(telegraph)` décalée au hasard de ±`aim_spread` ; impact : cristal touché si `hits_point`, héros si `hits_body`, « BAM ! » + `shake(&"small")`.
  - `WaveSpawner` : compose la vague (gobelins = nombre actuel ; kamikazes et artilleurs selon `count_for`), mélangés au hasard dans la même fenêtre d'apparition ; chaque type a sa planche (chargée une fois dans `main.gd`) ; les annonces sont enfants d'un nœud dédié sous Main (au-dessus du sol et du trajet, sous les personnages).

- [ ] **Step 1:** Implémenter ; contrôle `tests/unit/enemies/enemy_types_check.gd` de `count_for` (kamikaze : 0 à la vague 2, 1 à la 3, 3 à la 5 ; artilleur : 0 à la 4, 1 à la 5, 1 à la 6, 2 à la 7) et de la validation.
- [ ] **Step 2:** Relecture puis commit `feat: kamikazes et artilleurs`.

### Task 5: Cartes de survie

**Files:**
- Modify: `assets/data/cards.json`, `src/cards/card_catalog.gd`, `src/cards/player_modifiers.gd`, `src/game/main.gd` (appliquer soin/max/régén au `HeroHealth`), `src/ui/stats_panel.gd`

**Interfaces:**
- Produces: cartes `bandage` (commune, illimitée, `hero_heal` 30), `peau_dure` (peu commune ×3, `hero_max_hp_bonus` 25), `regeneration` (rare ×1, `hero_regen` 1.0), `vampirisme` (épique ×1, `hero_heal_on_kill` 1.0), communes à toutes les spés ; `PlayerModifiers` : signal `hero_heal_requested(amount)` (comme `heal_requested` du cristal), `hero_max_hp_bonus()`, `hero_regen()`, `hero_heal_on_kill()` ; panneau : PV max et régénération (> 0).

- [ ] **Step 1:** Implémenter ; étendre `tests/unit/cards/modifiers_check.gd` (Peau dure ×2 → +50 ; régén 1.0 ; soin émis à la prise de Bandage).
- [ ] **Step 2:** Relecture finale de la branche, commit et push `feat: cartes de survie`.
- [ ] **Step 3: Partie jouée par l'utilisateur**

| N° | À vérifier | Attendu |
|---|---|---|
| V-1 | Barre de PV du héros | Visible à côté de celle du cristal, 100 PV |
| V-2 | Touché | Flash rouge, petit tremblement, clignotement 0,5 s sans nouveau dégât |
| V-3 | Saut à travers une zone | Aucun dégât |
| V-4 | Kamikazes (vague 3+) | Zombies rapides ; au cristal : cercle 0,6 s puis « KABOUM ! » ; tués avant : pas d'explosion |
| V-5 | Artilleurs (vague 5+) | Soucoupes à distance ; cercles qui se remplissent près du cristal, « BAM ! » |
| V-6 | Mort du héros | Animation de mort, puis écran de défaite habituel |
| V-7 | Cartes de survie | Bandage soigne, Peau dure augmente le max, Régénération, Vampirisme |
| V-8 | Fin de vague pendant une annonce | Rien ne frappe, tout disparaît |
