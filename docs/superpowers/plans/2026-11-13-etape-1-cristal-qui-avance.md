# Étape 1 — Le cristal qui avance : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer l'arène fixe par un terrain plus grand que l'écran où, à chaque vague, le cristal suit un trajet connu à l'avance ; le joueur prépare la vague (trajet visible, aperçu du nombre d'ennemis, tours posées), la vague se termine quand le cristal arrive, et les tours disparaissent.

**Architecture:** Une nouvelle classe de logique pure `CrystalPath` (génération du trajet + position à une distance donnée). `WaveCycle` prépare la vague suivante à l'entrée en BUILD (trajet + plan) et la lance sur Espace ; le `Crystal` suit le trajet et émet `arrived` ; le `WaveSpawner` fait apparaître les ennemis autour du cristal pendant le trajet et termine la vague à l'arrivée. Une `GameCamera` suit le héros en combat et dézoome sur tout le terrain en préparation. Tout ce qui est nouveau est construit en code (pas de nouveau `.tscn`).

**Tech Stack:** Godot 4.7.2, GDScript typé, données JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md` (sections 3.1, 3.2, 3.3, 3.4, 9 étape 1)

## Global Constraints

- Godot 4.7.2, renderer Compatibility, export web ; viewport 1280×720 (`project.godot`).
- Toute valeur de jeu vient d'un fichier JSON de `assets/data/`, chargé par une classe `RefCounted` qui valide à la lecture et renvoie `null` + `push_error` nommant le fichier et la clé fautive (modèle : `src/crystal/defence_stats.gd`).
- Interface construite en code ; aucun nouveau `.tscn`. Pas d'autoload ; dépendances passées par `setup(...)`.
- Ne jamais écrire d'attribut `uid=` ni de fichier `.uid` (l'éditeur de l'utilisateur les crée).
- Commentaires de doc (`##`) sur toute fonction publique ; typage statique partout.
- Consulter `docs/engine-reference/godot/` avant toute API Godot dont on n'est pas sûr (Camera2D, Viewport).
- Contrôles inchangés : ZQSD, tir automatique vers la souris, clic gauche pour poser une tour en préparation, Espace pour lancer la vague.
- Pas de minuteur en préparation (spec 3.1).
- L'aperçu montre **le nombre** d'ennemis (un seul type existe pour l'instant), **jamais leur point d'apparition** (spec 3.1).
- Le cristal avance seul à vitesse régulière, ne s'arrête pas (spec 3.2).
- Fin de vague = le cristal arrive au bout du trajet ; les ennemis restants disparaissent sans donner d'or ; les tours disparaissent ; l'or non dépensé est conservé (spec 3.3).
- La caméra suit le héros en combat ; une flèche au bord de l'écran montre le cristal hors écran, avec ses PV (spec 3.2).
- Trajet plus long et ennemis plus nombreux à chaque vague (spec 3.4).
- Hors périmètre de cette étape : or au sol, désignation, compétences, nouveaux ennemis, PV du héros, carte du monde (étapes 2 à 6). L'or reste gagné automatiquement comme aujourd'hui.

## Décisions prises pour cette étape (questions ouvertes de la spec, section 10)

- **Terrain** : 2400 × 1600 pixels (données), soit environ 2 écrans de large.
- **Voir tout le trajet en préparation** : la caméra dézoome pour montrer tout le terrain pendant BUILD, et revient à zoom 1 sur le héros au lancement de la vague. Pas de déplacement libre de caméra.
- **Continuité** : le trajet d'une vague part de l'endroit où le cristal s'est arrêté à la vague précédente. Le cristal ne revient jamais au départ.
- **Première vague** : après le choix de spé (et de la carte « Départ en trombe » si elle est possédée), le jeu entre en préparation de la vague 1. Le compte à rebours automatique de la vague 1 disparaît. L'or de départ passe à 100 pour pouvoir poser 2 tours.
- **Apparition des ennemis** : à `spawn_distance` pixels du cristal (sa position du moment), direction au hasard, ramenée dans le terrain. Les ennemis visent la position **actuelle** du cristal à chaque image.
- **Rythme d'apparition** : tous les ennemis de la vague apparaissent pendant la première fraction `spawn_window` (0,7) du temps de trajet du cristal, à intervalle régulier.

## Review Focus

1. **Trajet coincé dans un coin** : le cristal finit une vague près d'un bord ou d'un coin ; le trajet suivant doit quand même avoir la longueur demandée et rester entièrement dans le terrain (marge comprise). → test manuel T1-c dans la tâche 1.
2. **Ennemi qui touche le cristal à l'image de l'arrivée** : un ennemi qui touche le cristal à la même image que l'arrivée ne doit ni rouvrir la vague, ni la terminer deux fois. → règle « fin de vague une seule fois » dans la tâche 3.
3. **Cristal détruit pendant le trajet** : l'écran de défaite s'ouvre, le cristal arrête d'avancer, aucune carte n'est proposée. → vérification V-7 de la tâche 5.
4. **Clic sur un bouton de tour pendant le dézoom** : le clic sur le bouton du HUD ne doit pas poser de tour, et un clic dans le terrain dézoomé pose la tour à l'endroit exact sous la souris. → vérification V-3 de la tâche 5.
5. **Rien ne bouge hors combat** : en CARD_CHOICE et BUILD, le cristal reste immobile et aucun ennemi n'apparaît. → vérification V-5 de la tâche 5.

## Vérification

Godot n'est pas disponible dans la session cloud et gdUnit4 n'est pas installé : il n'y a pas de tests automatiques exécutables ici (`qa.level: minimal`, tests facultatifs). Chaque tâche est vérifiée par :

- une **relecture** du code par `godot-gdscript-specialist` (typage, signaux, API Godot 4.7) ;
- pour la tâche 1, un **contrôle de logique** écrit dans `tests/unit/crystal_path/crystal_path_check.gd` (script `extends SceneTree` lançable par l'utilisateur avec `godot --headless -s res://tests/unit/crystal_path/crystal_path_check.gd`, qui imprime `CRYSTAL_PATH OK` ou la première vérification ratée) ;
- à la fin, une **partie jouée par l'utilisateur** sur Windows avec la liste V-1 à V-8 (tâche 5) et des captures conservées dans `production/qa/evidence/story-014-cristal-qui-avance/`.

---

## Fichiers

| Fichier | Rôle | Tâche |
|---|---|---|
| `src/waves/crystal_path.gd` (nouveau) | Trajet : génération, longueur, position à une distance | 1 |
| `tests/unit/crystal_path/crystal_path_check.gd` (nouveau) | Contrôle de logique du trajet | 1 |
| `src/waves/path_settings.gd` (nouveau) | Réglages de génération lus dans `waves.json` | 1 |
| `assets/data/waves.json` | `path_length` par vague, réglages du trajet, `spawn_window` | 1, 3 |
| `src/waves/wave_curve.gd` | Lit `path_length` au lieu de `spawn_interval` | 3 |
| `src/crystal/crystal.gd` | Suit un trajet, émet `arrived` | 2 |
| `src/crystal/defence_stats.gd`, `assets/data/defence_stats.json` | `crystal_speed`, `spawn_distance` | 2, 3 |
| `src/enemies/enemy.gd` | Vise la position actuelle du cristal | 3 |
| `src/waves/wave_spawner.gd` | Apparition autour du cristal, fin de vague à l'arrivée | 3 |
| `src/game/wave_cycle.gd` | Prépare la vague (trajet + plan), la lance | 3 |
| `src/towers/tower_placer.gd` | Retire toutes les tours en fin de vague | 3 |
| `src/waves/path_view.gd` (nouveau) | Dessine le trajet | 4 |
| `src/game/game_camera.gd` (nouveau) | Suit le héros / dézoome en préparation | 4 |
| `src/ui/crystal_pointer.gd` (nouveau) | Flèche au bord de l'écran vers le cristal | 4 |
| `src/ui/crystal_hud.gd` | Aperçu « Vague N : X ennemis » et texte de préparation | 4 |
| `src/game/main.gd` | Nouveau terrain, nouveau déroulé, branchements | 5 |
| `assets/data/hero_stats.json` | `arena_width` 2400, `arena_height` 1600 | 5 |
| `assets/data/economy.json` | `starting_gold` 100 | 5 |

---

### Task 1: Le trajet (`CrystalPath`)

**Files:**
- Create: `src/waves/crystal_path.gd`, `src/waves/path_settings.gd`, `tests/unit/crystal_path/crystal_path_check.gd`
- Modify: `assets/data/waves.json` (ajout de l'objet `path`)

**Interfaces:**
- Produces:
  - `class_name PathSettings extends RefCounted` — `var segment_length: float`, `var max_turn_degrees: float`, `var margin: float` ; `static func from_dict(data: Variant, path: String) -> PathSettings` (null + `push_error` si une clé manque ou n'est pas un nombre > 0 ; `max_turn_degrees` ≤ 180).
  - `class_name CrystalPath extends RefCounted` —
    - `var points: PackedVector2Array` (au moins 2 points)
    - `func length() -> float` — somme des longueurs des segments
    - `func position_at(distance: float) -> Vector2` — `distance` ramenée dans `[0, length()]` ; 0 → premier point, `length()` → dernier point
    - `func end_point() -> Vector2`
    - `static func generate(start: Vector2, total_length: float, bounds: Rect2, settings: PathSettings, rng: RandomNumberGenerator) -> CrystalPath`

- [ ] **Step 1: Ajouter les réglages du trajet à `assets/data/waves.json`**

Ajouter à l'objet racine :

```json
"path": { "segment_length": 160.0, "max_turn_degrees": 50.0, "margin": 120.0 }
```

- [ ] **Step 2: Écrire le contrôle de logique `tests/unit/crystal_path/crystal_path_check.gd`**

Script `extends SceneTree` ; `_init()` exécute les vérifications puis `quit()`. Il imprime `CRYSTAL_PATH OK` si tout passe, sinon `CRYSTAL_PATH FAIL: <nom>` à la première erreur. Données construites dans le script (pas de lecture de fichier) : `bounds = Rect2(0, 0, 2400, 1600)`, `settings` avec 160 / 50 / 120, `rng.seed = 12345`.

| Nom | Vérification |
|---|---|
| T1-a `length_matches` | `generate(Vector2(1200, 800), 1500, …)` : `absf(path.length() - 1500) < 0.5` |
| T1-b `stays_inside` | même trajet : chaque point vérifie `bounds.grow(-120).grow(0.5).has_point(p)` |
| T1-c `corner_start` | `generate(Vector2(130, 130), 2500, …)` : longueur à 0,5 près et tous les points dans la marge |
| T1-d `position_at_ends` | `position_at(0) == points[0]`, `position_at(length()) == end_point()`, `position_at(-10) == points[0]`, `position_at(length() + 10) == end_point()` |
| T1-e `position_at_middle` | trajet fait à la main `points = [(0,0), (100,0), (100,100)]` : `position_at(150) ≈ (100, 50)` |
| T1-f `deterministic` | deux `generate` avec deux `rng` de même graine donnent les mêmes `points` |

- [ ] **Step 3: Implémenter `PathSettings.from_dict` et `CrystalPath`**

Algorithme de `generate` (non déterminé par les tests, à suivre) :

```text
inner = bounds.grow(-settings.margin)
pos = start ramené dans inner (clamp)
heading = angle au hasard dans [0, TAU)
points = [pos] ; restant = total_length
tant que restant > 0 :
    pas = min(settings.segment_length, restant)
    essayer jusqu'à 12 fois :
        candidat_heading = heading + rng.randf_range(-max_turn, +max_turn)   (radians)
        candidat = pos + Vector2.from_angle(candidat_heading) * pas
        si inner.has_point(candidat) : accepter, sortir
    si aucun essai accepté :
        candidat_heading = (inner.get_center() - pos).angle()   # demi-tour vers le centre
        candidat = pos + Vector2.from_angle(candidat_heading) * pas
    heading = candidat_heading ; pos = candidat ; points.append(pos) ; restant -= pas
```

Le repli « vers le centre » garantit de rester dans `inner` tant que `inner` fait plus de `segment_length` de large (vrai avec 2400×1600, marge 120, segment 160).

- [ ] **Step 4: Relecture**

Relecture par `godot-gdscript-specialist` des trois fichiers. L'utilisateur lancera le contrôle avec Godot à la fin (tâche 5, V-0) ; attendu : `CRYSTAL_PATH OK`.

- [ ] **Step 5: Commit**

```bash
git add src/waves/crystal_path.gd src/waves/path_settings.gd tests/unit/crystal_path/crystal_path_check.gd assets/data/waves.json
git commit -m "feat: trajet du cristal (CrystalPath) — étape 1"
```

---

### Task 2: Le cristal suit le trajet

**Files:**
- Modify: `src/crystal/crystal.gd`, `src/crystal/defence_stats.gd`, `assets/data/defence_stats.json`

**Interfaces:**
- Consumes: `CrystalPath.position_at(distance: float) -> Vector2`, `CrystalPath.length() -> float`
- Produces (sur `Crystal`) :
  - `signal arrived` — émis une seule fois par trajet, quand la distance parcourue atteint `length()`
  - `func travel(path: CrystalPath) -> void` — part du début du trajet, avance de `speed` pixels/s dans `_physics_process`
  - `func stop() -> void` — arrête d'avancer sans émettre `arrived`
  - `func is_travelling() -> bool`
  - `var speed: float` — lu dans `DefenceStats.crystal_speed` au `setup`
- Produces (sur `DefenceStats`) : `var crystal_speed: float`, `var spawn_distance: float` (clés obligatoires, nombres > 0)

- [ ] **Step 1: Ajouter les clés à `assets/data/defence_stats.json`**

`"crystal_speed": 55.0`, `"spawn_distance": 700.0`. Ajouter les deux clés à `REQUIRED_KEYS` et aux variables documentées de `DefenceStats`.

Raison du 55 px/s : trajet de la vague 1 = 900 px (tâche 3) → environ 16 s de vague ; il est inférieur à `enemy_speed` (90) pour que les ennemis rattrapent le cristal.

- [ ] **Step 2: Implémenter `travel`, `stop`, `is_travelling`, `arrived` dans `crystal.gd`**

`_physics_process` ne fait rien quand le cristal ne voyage pas ou quand `current_hp <= 0`. À l'arrivée : `global_position = path.end_point()`, état « ne voyage plus », puis `arrived.emit()`. `take_damage` qui détruit le cristal appelle aussi `stop()` avant `destroyed.emit()`.

- [ ] **Step 3: Relecture**

Relecture par `godot-gdscript-specialist`.

- [ ] **Step 4: Commit**

```bash
git add src/crystal/crystal.gd src/crystal/defence_stats.gd assets/data/defence_stats.json
git commit -m "feat: le cristal suit son trajet et signale son arrivée — étape 1"
```

---

### Task 3: Vague liée au trajet (spawner, cycle, ennemis, tours)

**Files:**
- Modify: `src/waves/wave_curve.gd`, `assets/data/waves.json`, `src/waves/wave_spawner.gd`, `src/game/wave_cycle.gd`, `src/enemies/enemy.gd`, `src/towers/tower_placer.gd`

**Interfaces:**
- Consumes: `CrystalPath.generate(...)`, `PathSettings`, `Crystal.travel/stop/arrived/is_travelling`, `DefenceStats.spawn_distance`
- Produces:
  - `WaveCurve` : clés de vague `enemy_count`, `hp_multiplier`, `path_length` ; croissance `enemy_count_per_wave`, `hp_multiplier_per_wave`, `path_length_per_wave` ; `var spawn_window: float` (0 < x ≤ 1) ; `var path_settings: PathSettings`. `get_wave(n)` renvoie `{enemy_count: int, hp_multiplier: float, path_length: float}`. Les clés `first_wave_delay`, `spawn_interval`, `spawn_interval_factor`, `min_spawn_interval` disparaissent.
  - `WaveSpawner` :
    - `func setup(curve: WaveCurve, stats: DefenceStats, field_rect: Rect2, crystal: Crystal, enemies_parent: Node) -> void` — ne lance plus rien
    - `func start_wave(wave_number: int, path: CrystalPath) -> void` — ignorée si une vague est en cours
    - signaux inchangés : `wave_started(wave_number: int)`, `wave_finished(wave_number: int)`, `enemy_killed`
  - `WaveCycle` :
    - `signal wave_prepared(wave_number: int, enemy_count: int, path: CrystalPath)`
    - `func setup(state: GameState, spawner: WaveSpawner, economy: EconomyStats, modifiers: PlayerModifiers, curve: WaveCurve, crystal: Crystal, field_rect: Rect2, rng: RandomNumberGenerator) -> void`
    - `func request_next_wave() -> void` — en BUILD seulement : lance la vague préparée
    - `func prepared_path() -> CrystalPath` (null avant la première préparation)
  - `TowerPlacer` : `func clear_towers() -> void` ; `setup(...)` reçoit `field_rect` à la place de `arena_rect` (même type)
  - `Enemy` : vise `_crystal.global_position` à chaque image (le champ `_target` disparaît)

- [ ] **Step 1: Mettre à jour `assets/data/waves.json`**

```json
{
	"spawn_window": 0.7,
	"path": { "segment_length": 160.0, "max_turn_degrees": 50.0, "margin": 120.0 },
	"waves": [
		{ "enemy_count": 4, "hp_multiplier": 1.0, "path_length": 900.0 },
		{ "enemy_count": 6, "hp_multiplier": 1.0, "path_length": 1100.0 },
		{ "enemy_count": 8, "hp_multiplier": 1.5, "path_length": 1300.0 }
	],
	"growth": {
		"enemy_count_per_wave": 2.0,
		"hp_multiplier_per_wave": 0.25,
		"path_length_per_wave": 200.0
	}
}
```

- [ ] **Step 2: `WaveCurve`** — lire ce nouveau format, avec la même validation qu'avant (null + `push_error` nommant la clé). `path` est lu par `PathSettings.from_dict`. La règle « la croissance doit rendre les vagues plus dures » devient : `enemy_count_per_wave > 0` ou `hp_multiplier_per_wave > 0`.

- [ ] **Step 3: `Enemy`** — se déplacer chaque image vers `_crystal.global_position` ; le test de contact utilise aussi cette position. Ne rien changer d'autre (états, gel, ralentissement).

- [ ] **Step 4: `WaveSpawner`** — états `IDLE`, `SPAWNING`, `TRAVELLING`.
  - `start_wave` : lit `curve.get_wave(wave_number)`, calcule `interval = path.length() / crystal.speed * curve.spawn_window / enemy_count`, appelle `crystal.travel(path)`, émet `wave_started`.
  - Point d'apparition : `crystal.global_position + Vector2.from_angle(randf() * TAU) * stats.spawn_distance`, ramené dans `field_rect.grow(-stats.spawn_margin)`.
  - Sur `crystal.arrived` (connecté une fois dans `setup`) : arrêter d'apparaître, `queue_free()` tous les ennemis vivants **sans** émettre `died` (donc sans or), passer en `IDLE`, émettre `wave_finished` **une seule fois** par vague (garde sur l'état).
  - La vague ne se termine plus quand tous les ennemis sont morts.

- [ ] **Step 5: `WaveCycle`**
  - À chaque passage en `BUILD` : numéro = `state.waves_completed + 1` ; `path = CrystalPath.generate(crystal.global_position, curve.get_wave(n)["path_length"], field_rect, curve.path_settings, rng)` ; mémoriser ; émettre `wave_prepared(n, enemy_count, path)`.
  - `request_next_wave` : en `BUILD` et avec un trajet préparé → `spawner.start_wave(n, path)`.
  - Garder le bonus d'or de fin de vague et l'or par ennemi tué.

- [ ] **Step 6: `TowerPlacer`** — `clear_towers()` libère tous les enfants de `_towers`. Le placement reste valide n'importe où dans `field_rect` (hors cristal, hors autres tours). Mettre à jour le commentaire de classe : « les tours durent une vague ».

- [ ] **Step 7: Relecture**

Relecture par `godot-gdscript-specialist`, en vérifiant le point 2 de la Review Focus (pas de double `wave_finished`).

- [ ] **Step 8: Commit**

```bash
git add src/waves/ src/game/wave_cycle.gd src/enemies/enemy.gd src/towers/tower_placer.gd assets/data/waves.json
git commit -m "feat: vagues liées au trajet du cristal, tours valables une vague — étape 1"
```

---

### Task 4: Affichage — trajet, caméra, flèche du cristal, aperçu

**Files:**
- Create: `src/waves/path_view.gd`, `src/game/game_camera.gd`, `src/ui/crystal_pointer.gd`
- Modify: `src/ui/crystal_hud.gd`

**Interfaces:**
- Consumes: `WaveCycle.wave_prepared(wave_number, enemy_count, path)`, `GameState.phase_changed`, `Crystal.health_changed`
- Produces:
  - `class_name PathView extends Node2D` — `func show_path(path: CrystalPath) -> void` ; dessine la ligne du trajet (couleur `Color(0.55, 0.9, 1.0, 0.5)`, largeur 6), un rond au départ et un drapeau ou un rond plus gros à l'arrivée. Visible en BUILD et en COMBAT, plus discrète (alpha 0,25) en COMBAT.
  - `class_name GameCamera extends Camera2D` — `func setup(hero: Node2D, field_rect: Rect2, state: GameState) -> void` ; limites = `field_rect` ; en COMBAT : suit le héros, zoom 1 ; en BUILD : zoom = `min(viewport.x / field.x, viewport.y / field.y)`, centrée sur le terrain. Dans les autres phases (choix de carte ou de spé) : ne change rien.
  - `class_name CrystalPointer extends Control` (enfant du HUD) — `func setup(crystal: Crystal) -> void` ; quand le cristal est hors de l'écran (position écran = `get_viewport().get_canvas_transform() * crystal.global_position`, hors du rectangle de l'écran réduit de 40 px), dessine une flèche au bord de l'écran dans sa direction, avec ses PV (`"%d PV"`) ; sinon rien.
  - `CrystalHud` : `func show_wave_preview(wave_number: int, enemy_count: int) -> void` ; en BUILD, le texte de préparation devient `Vague %d : %d ennemis — place tes tours, puis Espace`.

- [ ] **Step 1: `PathView`** — implémenter comme décrit.
- [ ] **Step 2: `GameCamera`** — implémenter comme décrit. Lire `docs/engine-reference/godot/` pour `Camera2D` (zoom, limites, `make_current`) avant d'écrire.
- [ ] **Step 3: `CrystalPointer`** — implémenter comme décrit.
- [ ] **Step 4: `CrystalHud`** — ajouter `show_wave_preview` et le pointeur ; le reste du HUD ne change pas.
- [ ] **Step 5: Relecture** par `godot-gdscript-specialist`.
- [ ] **Step 6: Commit**

```bash
git add src/waves/path_view.gd src/game/game_camera.gd src/ui/crystal_pointer.gd src/ui/crystal_hud.gd
git commit -m "feat: trajet visible, caméra qui suit le héros, flèche vers le cristal — étape 1"
```

---

### Task 5: Branchements dans `main.gd` et partie jouée

**Files:**
- Modify: `src/game/main.gd`, `assets/data/hero_stats.json`, `assets/data/economy.json`, `src/hero/hero_stats.gd` (commentaires seulement)

**Interfaces:**
- Consumes: tout ce qui précède.

- [ ] **Step 1: Données** — `hero_stats.json` : `arena_width` 2400, `arena_height` 1600 (le commentaire de `HeroStats` dit « terrain » au lieu d'« arène ») ; `economy.json` : `starting_gold` 100.

- [ ] **Step 2: `main.gd`**
  - `_field_rect = Rect2(Vector2.ZERO, stats.arena_size)` (le terrain n'est plus centré dans l'écran).
  - `_field_rect` remplace `_arena_rect` partout où il est passé : `Hero.setup`, `TowerPlacer.setup` (donc les tirs des canons), `WaveSpawner.setup`, `_draw` (sol et bordure du terrain).
  - Cristal placé au centre du terrain au départ ; héros juste en dessous (comme aujourd'hui).
  - Créer en code `PathView` (sous `Towers`, pour être dessiné sous les tours), `GameCamera` (`make_current()`), et passer le cristal au HUD pour le pointeur.
  - `_spawner.setup(...)` appelé une fois dans `_ready` ; `_cycle.setup(...)` avec la nouvelle signature ; `wave_prepared` relié à `PathView.show_path` et `CrystalHud.show_wave_preview` ; `wave_finished` relié à `TowerPlacer.clear_towers`.
  - Après le choix de spé (et après la carte « Départ en trombe ») : `_state.begin_build()` au lieu de `begin_combat(1)` + compte à rebours. Supprimer `_spawner_setup`.
  - `_on_crystal_destroyed` : inchangé (pause de l'arbre de scène).

- [ ] **Step 3: Relecture complète** par `godot-gdscript-specialist` de toute la branche (tâches 1 à 5).

- [ ] **Step 4: Commit et push**

```bash
git add src/game/main.gd assets/data/hero_stats.json assets/data/economy.json src/hero/hero_stats.gd
git commit -m "feat: déroulé préparation → trajet → arrivée branché dans le jeu — étape 1"
git push origin main
```

- [ ] **Step 5: Partie jouée par l'utilisateur (Windows, Godot 4.7.2)**

| N° | À vérifier | Attendu |
|---|---|---|
| V-0 | `godot --headless -s res://tests/unit/crystal_path/crystal_path_check.gd` | `CRYSTAL_PATH OK` |
| V-1 | Après le choix de spé | Vue dézoomée sur tout le terrain, trajet de la vague 1 dessiné, texte `Vague 1 : 4 ennemis — place tes tours, puis Espace` |
| V-2 | Rien n'apparaît tant qu'on n'appuie pas sur Espace | Pas d'ennemi, cristal immobile, pas de minuteur |
| V-3 | Poser 2 tours en vue dézoomée ; cliquer sur un bouton de tour | Chaque tour apparaît exactement sous la souris ; le clic sur le bouton ne pose rien |
| V-4 | Espace | Zoom 1 sur le héros, le cristal avance le long de la ligne, les ennemis arrivent de plusieurs côtés et le poursuivent |
| V-5 | S'éloigner du cristal | Flèche au bord de l'écran vers le cristal, avec ses PV |
| V-6 | Le cristal atteint le bout du trajet | Ennemis restants disparus, tours disparues, choix de carte, puis préparation de la vague 2 avec un trajet qui part de là où le cristal s'est arrêté, plus long, et `6 ennemis` |
| V-7 | Laisser le cristal mourir en plein trajet | Écran de défaite, le cristal n'avance plus, aucune carte proposée |
| V-8 | Jouer jusqu'à la vague 5 environ | Les trajets restent dans le terrain, même quand le cristal finit près d'un bord |

Captures à conserver : préparation dézoomée (V-1), combat avec la flèche du cristal (V-5), préparation de la vague 2 (V-6), dans `production/qa/evidence/story-014-cristal-qui-avance/`.
