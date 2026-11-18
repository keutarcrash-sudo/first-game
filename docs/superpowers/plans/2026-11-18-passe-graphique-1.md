# Passe graphique 1 — Néon pop : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Habiller le jeu en néon pop : personnages, tours et cristal affichés avec des images tirées de modèles 3D gratuits (8 directions, caméra inclinée), sol et trajet néon, polices BD, explosions en étoile avec onomatopées, tremblement d'écran et arrêt sur image — sans changer les règles du jeu.

**Architecture:** Une fabrique (`tools/sprite_baker/`, Node + Playwright + three.js) produit des planches PNG et un manifeste JSON par élément dans `assets/sprites/`. Dans Godot, `SpriteSheet` charge un manifeste et `DirectionalSprite` (nœud 2D) affiche l'image de l'animation et de la direction voulues ; héros, ennemis, tours et cristal remplacent leur dessin par ce nœud. Un nœud `ImpactFeedback` créé par `main.gd` gère tremblement et arrêt sur image ; les effets de sorts gagnent une étoile et une onomatopée.

**Tech Stack:** Godot 4.7.2 / GDScript typé ; Node.js 22, Playwright (préinstallé, Chromium en `--use-gl=swiftshader`), three.js 0.147.0 via npm ; Python 3 + Pillow pour les planches de contrôle.

**Spec:** `docs/superpowers/specs/2026-11-18-passe-graphique-1-design.md` (référence visuelle validée : https://claude.ai/artifact/99ZfLAAZtsfi5tmssEG3NX ; code de l'essai : `docs/superpowers/spikes/2026-11-18-sprite-baker-spike.html` et `-run.js`)

## Global Constraints

- Aucune règle de jeu ne change : rayons de collision, vitesses, dégâts, recharges, or, vagues restent identiques (spec §5).
- Godot 4.7.2, renderer Compatibility, export web ; vue 1280×720 ; terrain 2400×1600.
- Valeurs dans des fichiers JSON de `assets/data/`, chargés par une classe `RefCounted` qui valide et renvoie `null` + `push_error` nommant le fichier et la clé fautive. Interface en code, pas de nouveau `.tscn`, pas d'autoload.
- Les agents n'écrivent jamais d'attribut `uid=`, ni de fichier `.uid` ou `.import` (l'éditeur de l'utilisateur les crée).
- `##` sur toute fonction publique ; typage statique partout.
- Caméra de la fabrique : orthographique, inclinée de **50°**, contour noir, aplats 3 tons, fond transparent, **8 directions** (spec §9.1).
- Convention de direction (fabrique ET jeu) : direction `k` (0 à 7) = l'objet regarde vers l'angle écran `k × 45°`, mesuré dans le sens des aiguilles d'une montre à partir de la droite (0 = droite, 2 = bas, 4 = gauche, 6 = haut), comme `Vector2.angle()` dans Godot (y vers le bas).
- Seuls les fichiers listés en spec §8 entrent dans le dépôt ; les zips restent dehors ; `assets/models/source/.gdignore` empêche Godot d'importer les modèles sources.
- Lisibilité d'abord : ennemis, or, zones, cible désignée et états (brûle, trempé, gelé, marqué, ralenti) restent visibles d'un coup d'œil (spec §6).

## Décisions prises pour ce plan

- **Taille des cases** : 128×128 px. **Images par seconde** : 12. **Images par animation** : 8 (mort : 10, sans boucle).
- **Animations** (nom du pack → nom court) : héros `Idle`→`idle`, `Run`→`run`, `Shoot_OneHanded`→`shoot`, `Roll`→`roll`, `RecieveHit`→`hit`, `Death`→`death` ; ennemi `Run`→`run`, `Punch`→`punch`, `RecieveHit`→`hit`, `Death`→`death`.
- **Disposition d'une planche** : 8 lignes (une par direction `k`), une colonne par image.
- **Taille à l'écran** (`assets/data/visuals.json`) : héros 64 px de haut, ennemi 56 px, canon 76 px, glace 76 px, chariot à cristal 90 px (largeur de case mise à l'échelle en conséquence). Ancrage : bas-centre de la silhouette sur la position de jeu.
- **Polices** : Bangers et Bungee en `.ttf` (Google Fonts, SIL OFL 1.1), dans `assets/fonts/` avec `OFL.txt`.
- **Impact** (`assets/data/impact.json`) : tremblement `small` 4 px / 0,12 s, `big` 10 px / 0,25 s ; arrêt sur image 0,05 s à vitesse 0,05.

## Review Focus

1. **Direction d'une image inversée** (personnage qui court à reculons ou regarde à l'opposé de la souris) : la convention de direction doit être la même dans la fabrique et dans le jeu. → Task 1 (planche de contrôle annotée) et Task 2 (contrôle `direction_index`).
2. **Ennemi qui meurt pendant son animation de coup reçu** : il disparaît du jeu immédiatement (comme aujourd'hui) et une image de mort indépendante joue à sa place. → Task 3.
3. **Arrêt sur image pendant un écran de choix ou après la défaite** : ignoré ; la vitesse du jeu revient toujours à 1. → Task 5.
4. **Marques d'état sur les nouvelles images** : anneaux et gouttes encore visibles sur un personnage plus grand que son ancien rond. → Task 3.
5. **Aperçu de pose de tour** : image de la tour en transparence, verte ou rouge, sous la souris en vue dézoomée. → Task 4.

## Vérification

Godot n'est pas disponible dans la session : les planches sont vérifiées en les regardant (planche de contrôle PNG), le code par `godot-gdscript-specialist`, le jeu par la partie de l'utilisateur (liste V-1 à V-9 en fin de Task 5) avec captures dans `production/qa/evidence/story-018-passe-graphique-1/`.

---

### Task 1: La fabrique d'images et les planches

**Files:**
- Create: `tools/sprite_baker/package.json` (dépendance `three` `0.147.0` exacte), `tools/sprite_baker/bake.js`, `tools/sprite_baker/page.html`, `tools/sprite_baker/recipes.json`, `tools/sprite_baker/contact_sheet.py`, `tools/sprite_baker/README.md`, `tools/sprite_baker/.gitignore` (`node_modules/`)
- Create: `assets/models/source/.gdignore`, `assets/models/source/quaternius/{Elf,Wizard,Witch,Goblin_Male,Zombie_Male}.glb`, `assets/models/source/kenney/{tower-round-bottom-a,tower-round-middle-a,weapon-cannon,tower-square-bottom-a,tower-square-middle-a,enemy-ufo-a,enemy-ufo-b,enemy-ufo-c,enemy-ufo-d}.glb`, `assets/models/source/kenney/Textures/colormap.png`, `assets/models/source/kenney/License.txt`
- Create (produits par la fabrique) : `assets/sprites/{elf,wizard,witch,goblin,cannon,frost_tower,crystal_cart}/` (PNG + `sheet.json`)

**Interfaces:**
- Produces: pour chaque élément, `assets/sprites/<id>/sheet.json` :
  ```json
  { "cell": [128, 128], "anchor": [64, 112], "directions": 8,
    "animations": { "run": { "file": "run.png", "frames": 8, "fps": 12, "loop": true } } }
  ```
  `anchor` = point de la case posé sur la position de jeu (bas-centre de la silhouette). Éléments fixes (`frost_tower`, `crystal_cart`) : `"directions": 1`, une animation `idle` d'une image. `cannon` : `"directions": 8`, une animation `idle` d'une image.

- [ ] **Step 1: Sources** — convertir en GLB (conteneur binaire, sans re-encodage) les 5 `.gltf` Quaternius fournis par l'utilisateur (`/root/.claude/uploads/dc8da191-41f7-5183-8267-1281bff2f7d6/f7da0c97-glTF-*.zip`) et copier les 9 `.glb` Kenney, la palette et `License.txt` (`/root/.claude/uploads/dc8da191-41f7-5183-8267-1281bff2f7d6/524b08b7-kenney_tower-defense-kit.zip`, dossier `Models/GLB format/`). Extraire chaque zip dans un dossier vide du scratchpad, jamais dans le dépôt. Créer `.gdignore` vide.
- [ ] **Step 2: `recipes.json`** — une entrée par élément : modèle(s), palette, animations (noms du pack → noms courts, nombre d'images), et pour les objets sur mesure le nom de la fonction de construction. Palettes Quaternius exactes : spec §8.1. Palettes Kenney : une teinte par pièce (socles violet foncé, arme du canon orange), comme `huePalette` de l'essai.
- [ ] **Step 3: `page.html` + `bake.js`** — repartir de l'essai (`docs/superpowers/spikes/`). three.js chargé depuis `node_modules`, servi par un petit serveur HTTP local lancé par `bake.js`. Rotation d'un modèle pour la direction `k` : le modèle regarde vers +Z ; pour regarder l'angle écran θ = k×45° (écran : droite = +X, bas = +Z vers la caméra), poser `rotation.y = atan2(cos θ, sin θ)`. Objets sur mesure (`crystal_cart`, haut de `frost_tower`) : construits par code comme dans l'essai (fonctions `gem`, chariot, anneau). Rendu `128×128` à `pixelRatio 1`. `bake.js` écrit les PNG et `sheet.json` dans `assets/sprites/<id>/`.
- [ ] **Step 4: `contact_sheet.py`** — assemble toutes les planches en une image `tools/sprite_baker/contact.png` (non commitée, ajoutée au `.gitignore`), avec le numéro de direction écrit à gauche de chaque ligne.
- [ ] **Step 5: Lancer** `cd tools/sprite_baker && npm install && node bake.js && python3 contact_sheet.py` ; ouvrir `contact.png` et vérifier : ligne 0 regarde à droite, ligne 2 vers le bas, ligne 4 à gauche, ligne 6 vers le haut ; personnages entiers dans leur case (mort comprise) ; contour noir visible ; couleurs de la spec.
- [ ] **Step 6: `README.md`** — à quoi sert la fabrique, comment la relancer, où sont les recettes.
- [ ] **Step 7: Commit** `feat: fabrique d'images et planches néon (passe graphique 1)` — vérifier avant que `assets/models/source` + `assets/sprites` pèsent moins de 15 Mo (`du -sh`).

---

### Task 2: Planches dans Godot (`SpriteSheet`, `DirectionalSprite`, `visuals.json`)

**Files:**
- Create: `src/visuals/sprite_sheet.gd`, `src/visuals/directional_sprite.gd`, `src/visuals/visual_stats.gd`, `assets/data/visuals.json`, `tests/unit/visuals/direction_check.gd`

**Interfaces:**
- Consumes: `assets/sprites/<id>/sheet.json` (Task 1).
- Produces:
  - `class_name SpriteSheet extends RefCounted` — `static func load_from_dir(dir: String) -> SpriteSheet` (lit `sheet.json`, charge les textures, valide ; `null` + `push_error` sinon) ; `var cell: Vector2i`, `var anchor: Vector2`, `var directions: int` ; `func has_animation(name: StringName) -> bool` ; `func frame_count(name: StringName) -> int` ; `func fps(name: StringName) -> float` ; `func loops(name: StringName) -> bool` ; `func texture(name: StringName) -> Texture2D` ; `static func direction_index(angle: float, directions: int) -> int` (angle en radians façon `Vector2.angle()`, renvoie l'index le plus proche, 0 si `directions == 1`).
  - `class_name DirectionalSprite extends Node2D` — `signal animation_finished(name: StringName)` ; `func setup(sheet: SpriteSheet, height_px: float) -> void` ; `func play(name: StringName, restart: bool = false) -> void` ; `func current() -> StringName` ; `func set_facing(angle: float) -> void` ; `var tint: Color = Color.WHITE` (multiplie l'image, pour l'aperçu de pose). Dessin par `draw_texture_rect_region`, ancré pour que `anchor` tombe sur la position du nœud, mis à l'échelle `height_px / float(cell.y)` (`height_px` = hauteur à l'écran de la case entière, lue dans `visuals.json`). Une animation sans boucle s'arrête sur sa dernière image et émet `animation_finished`.
  - `class_name VisualStats extends RefCounted` — `static func load_from_file(path: String) -> VisualStats` ; `func hero_sheet(spec_id: String) -> String` (dossier ; repli sur `default`) ; `var enemy_sheet: String`, `var cannon_sheet: String`, `var frost_sheet: String`, `var crystal_sheet: String` ; `func height(key: String) -> float`.
  - `assets/data/visuals.json` :
    ```json
    { "hero": { "default": "res://assets/sprites/elf", "archer": "res://assets/sprites/elf", "maitre_feu": "res://assets/sprites/wizard", "maitre_eau": "res://assets/sprites/witch" },
      "enemy": "res://assets/sprites/goblin", "cannon": "res://assets/sprites/cannon", "frost": "res://assets/sprites/frost_tower", "crystal": "res://assets/sprites/crystal_cart",
      "cell_height_px": { "hero": 96.0, "enemy": 84.0, "cannon": 110.0, "frost": 110.0, "crystal": 130.0 } }
    ```
    (hauteur à l'écran de la **case** entière ; la silhouette en occupe environ les deux tiers, soit les tailles de « Décisions »).

- [ ] **Step 1: `tests/unit/visuals/direction_check.gd`** (`extends SceneTree`, imprime `DIRECTION OK` ou `DIRECTION FAIL: <nom>` puis `quit()`) : `direction_index(0.0, 8) == 0` ; `direction_index(PI / 2.0, 8) == 2` ; `direction_index(PI, 8) == 4` ; `direction_index(-PI / 2.0, 8) == 6` ; `direction_index(deg_to_rad(22.0), 8) == 0` ; `direction_index(deg_to_rad(23.0), 8) == 1` ; `direction_index(deg_to_rad(-170.0), 8) == 4` ; `direction_index(1.0, 1) == 0`.
- [ ] **Step 2: Implémenter** les trois classes et `visuals.json`.
- [ ] **Step 3: Relecture** par `godot-gdscript-specialist`.
- [ ] **Step 4: Commit** `feat: affichage des planches 8 directions dans Godot (passe graphique 1)`.

---

### Task 3: Héros et ennemis en images

**Files:**
- Modify: `src/hero/hero.gd`, `src/enemies/enemy.gd`, `src/waves/wave_spawner.gd` (passer la planche ennemie), `src/game/main.gd`
- Create: `src/visuals/death_effect.gd`

**Interfaces:**
- Consumes: `SpriteSheet`, `DirectionalSprite`, `VisualStats` (Task 2).
- Produces:
  - `Hero.set_visual(sheet: SpriteSheet, height_px: float) -> void` (appelé à `setup` avec la planche par défaut, puis au choix de spé avec celle de la spé).
  - `Enemy.set_visual(sheet: SpriteSheet, height_px: float) -> void` (appelé par le spawner avant `add_child`) ; `WaveSpawner.set_enemy_visual(sheet: SpriteSheet, height_px: float) -> void`.
  - `class_name DeathEffect extends Node2D` — `func setup(sheet: SpriteSheet, height_px: float, facing: float) -> void` ; joue `death` puis se libère ; aucune influence sur le jeu.

- [ ] **Step 1: Héros** — le rond et le trait de visée disparaissent ; un `DirectionalSprite` enfant. Animation : `roll` pendant un saut, sinon `shoot` pendant 0,2 s après chaque tir quand le héros est immobile, sinon `run` s'il bouge, sinon `idle`. Orientation : vers la souris (pendant un saut : direction du saut).
- [ ] **Step 2: Ennemi** — le disque plein disparaît ; un `DirectionalSprite` enfant joue `run`, `hit` (0,2 s, une seule fois) quand il prend des dégâts, et regarde vers le cristal. Les teintes d'état actuelles s'appliquent au sprite par `modulate` (mêmes couleurs et même priorité que l'actuel `_draw` : gelé > ralenti > trempé > brûle), et les anneaux / gouttes / marque restent dessinés par `_draw` **par-dessus** le sprite, agrandis pour entourer la silhouette (rayon d'anneau = `height_px × 0.32`), avec un contour noir de 2 px sous chaque anneau pour la lisibilité.
- [ ] **Step 3: Mort** — quand un ennemi émet `died`, le spawner (ou `WaveCycle`, au choix, un seul endroit) crée un `DeathEffect` à sa position, comme enfant du parent du nœud `Enemies` (jamais sous `Enemies` lui-même, pour ne pas être pris pour un ennemi). Les ennemis libérés à l'arrivée du cristal ne jouent pas de mort.
- [ ] **Step 4: `main.gd`** — charger `VisualStats` et les planches une fois, les passer au héros, au spawner ; au choix de spé : `hero.set_visual(...)` de la spé.
- [ ] **Step 5: Relecture**, puis **Commit** `feat: héros et ennemis animés en images néon (passe graphique 1)`.

---

### Task 4: Tours, cristal, sol, trajet et polices

**Files:**
- Modify: `src/towers/tower.gd`, `src/towers/cannon_tower.gd`, `src/towers/frost_tower.gd`, `src/towers/tower_placer.gd`, `src/crystal/crystal.gd`, `src/game/main.gd` (sol), `src/waves/path_view.gd`, `src/ui/crystal_hud.gd`, `src/ui/ability_bar.gd`
- Create: `src/visuals/neon_floor.gd`, `assets/fonts/Bangers-Regular.ttf`, `assets/fonts/Bungee-Regular.ttf`, `assets/fonts/OFL.txt`, `src/ui/neon_fonts.gd`

**Interfaces:**
- Produces:
  - `Tower.set_visual(sheet: SpriteSheet, height_px: float) -> void` ; le canon appelle `set_facing` vers sa cible à chaque tir.
  - `Crystal.set_visual(sheet: SpriteSheet, height_px: float) -> void` ; halo cyan qui pulse dessous (dessiné par `_draw`).
  - `class_name NeonFloor extends Node2D` — `func setup(field_rect: Rect2) -> void` : fond `#120c2a`, trame de points `rgba(160,90,255,0.45)` tous les 16 px (texture motif générée en code, répétée), bordure du terrain noire 4 px + liseré cyan.
  - `class_name NeonFonts extends RefCounted` — `static func title() -> Font` (Bangers), `static func numbers() -> Font` (Bungee) ; chargement unique.

- [ ] **Step 1: Polices** — télécharger les `.ttf` (CSS Google Fonts `https://fonts.googleapis.com/css?family=Bangers|Bungee` avec un User-Agent ancien qui renvoie du TrueType, puis les URL `fonts.gstatic.com`) ; vérifier avec `file` qu'il s'agit de TrueType ; écrire `OFL.txt` (texte SIL OFL 1.1 complet + lignes de copyright : Bangers © Vernon Adams, Bungee © David Jonathan Ross).
- [ ] **Step 2: Tours** — le disque plein disparaît ; anneau de portée conservé (style : blanc 18 % comme aujourd'hui) ; halo de couleur au sol (orange canon, cyan glace) ; `TowerPlacer` dessine l'aperçu avec la planche de la tour choisie, `tint` vert `Color(0.5, 1.0, 0.6, 0.55)` si valide, rouge `Color(1.0, 0.4, 0.4, 0.55)` sinon, plus l'anneau de portée réelle.
- [ ] **Step 3: Cristal** — le losange disparaît au profit du chariot ; barre de PV inchangée.
- [ ] **Step 4: Sol et trajet** — `NeonFloor` remplace le dessin du sol dans `main.gd` ; `PathView` : trait noir 18 px, puis trait `#2a1a5e` 12 px, puis pointillés cyan `#19e3ff` 3 px (aux alphas BUILD/COMBAT actuels).
- [ ] **Step 5: Affichage** — titres, vague, or et onomatopées en Bangers avec contour noir (`outline_size` 6) ; chiffres des recharges en Bungee ; cases de compétences sombres `#1c1340` à liseré cyan, comme la maquette C.
- [ ] **Step 6: Relecture**, puis **Commit** `feat: tours, cristal, sol et polices néon (passe graphique 1)`.

---

### Task 5: Explosions pop, tremblement et arrêt sur image

**Files:**
- Create: `src/visuals/impact_feedback.gd`, `src/visuals/impact_stats.gd`, `assets/data/impact.json`, `src/visuals/pop_burst.gd`
- Modify: `src/game/game_camera.gd`, `src/game/main.gd`, `src/abilities/effects/fireball.gd`, `src/abilities/effects/meteor.gd`, `src/hero/hero_bullet.gd`, `src/enemies/enemy.gd`, `src/abilities/ability_caster.gd`, `src/crystal/crystal.gd` (signal déjà existant `health_changed` suffit)

**Interfaces:**
- Produces:
  - `assets/data/impact.json` : `{ "shake": { "small": { "strength": 4.0, "duration": 0.12 }, "big": { "strength": 10.0, "duration": 0.25 } }, "hitstop": { "duration": 0.05, "time_scale": 0.05 } }`.
  - `class_name ImpactFeedback extends Node` — `func setup(stats: ImpactStats, camera: GameCamera, state: GameState) -> void` ; `func shake(kind: StringName) -> void` (`&"small"` / `&"big"`, le plus fort en cours l'emporte) ; `func hitstop() -> void` (pose `Engine.time_scale`, remet 1.0 après `duration` secondes **réelles** via un `SceneTreeTimer` qui ignore la vitesse du temps ; sans effet si un arrêt est en cours, si la phase n'est pas COMBAT, ou si l'arbre est en pause) ; remet toujours `Engine.time_scale = 1.0` à la sortie de COMBAT et à la libération du nœud.
  - `GameCamera.set_shake_offset(offset: Vector2) -> void` (décalage ajouté à la position suivie).
  - `Enemy.signal died_heavy` — émis en plus de `died` quand le coup mortel est « lourd » ; `Enemy.take_damage(amount: float, heavy: bool = false)` (paramètre optionnel : les appels existants ne changent pas).
  - `class_name PopBurst extends Node2D` — `func setup(word: String, color: Color, radius: float) -> void` : étoile 11 branches remplie de points (jaune/rose), anneau cyan qui s'étend, onomatopée en Bangers blanche à contour noir légèrement penchée ; dure 0,6 s puis se libère.

- [ ] **Step 1: `ImpactStats`, `ImpactFeedback`, `GameCamera.set_shake_offset`** comme décrit ; `main.gd` crée l'`ImpactFeedback` et le donne aux effets qui en ont besoin.
- [ ] **Step 2: Coups lourds** — `HeroBullet` passe `heavy = true` sur un coup critique ; les effets de compétence (`PiercingArrow`, `Fireball`, `WaterWave`, zones, `Meteor`) passent `heavy = true`. Sur `died_heavy` : `hitstop()` + `shake(&"small")`.
- [ ] **Step 3: Explosions** — `Fireball` : `PopBurst` « POW ! » + `shake(&"small")` ; `Meteor` : `PopBurst` « BOUM ! » (rayon de l'explosion) + `shake(&"big")` + `hitstop()`. Le texte « Critique ×2 » de `HeroBullet` devient « CRIT ! » en Bangers jaune à contour noir.
- [ ] **Step 4: Cristal touché** — à chaque perte de PV du cristal : `shake(&"small")`.
- [ ] **Step 5: Relecture finale de la branche**, puis **Commit et push** `feat: explosions pop, tremblement et arrêt sur image (passe graphique 1)`.
- [ ] **Step 6: Partie jouée par l'utilisateur**

| N° | À vérifier | Attendu |
|---|---|---|
| V-1 | Choix de spé, puis préparation | Sol violet à trame de points, trajet bordé de noir à pointillés cyan, chariot à cristal |
| V-2 | Héros (chaque spé) | Elfe / sorcier / sorcière néon, qui court, tire, fait la roulade, regarde vers la souris |
| V-3 | Ennemis | Gobelins verts qui courent vers le cristal dans la bonne direction, réagissent aux coups, animation de mort |
| V-4 | États | Brûle, trempé, gelé, marqué, ralenti et cible désignée restent lisibles sur les gobelins |
| V-5 | Tours | Aperçu de pose en transparence vert/rouge ; canon qui se tourne vers sa cible ; tour de glace à pic et anneau |
| V-6 | Boule de feu / Météore | Étoile « POW ! » / « BOUM ! », écran qui tremble (fort pour le Météore) |
| V-7 | Coup critique ou mort par compétence | « CRIT ! », bref arrêt sur image, petit tremblement ; pas d'arrêt pendant les écrans de choix |
| V-8 | Fluidité | Jeu aussi fluide qu'avant en fin de partie (beaucoup d'ennemis) |
| V-9 | Affichage | Lettres de BD, cases de compétences néon, tout lisible |

Captures à conserver dans `production/qa/evidence/story-018-passe-graphique-1/` : un combat avec plusieurs gobelins et une tour, et une explosion de sort.
