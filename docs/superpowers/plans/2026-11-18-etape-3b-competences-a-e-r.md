# Étape 3b — Compétences A, E, R et leur déblocage : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter les compétences A, E et R des trois spécialisations (9 compétences) et leur déblocage pendant la partie : la partie commence avec le seul clic droit ; après les vagues 2, 4 et 6, le choix de fin de vague propose « Nouvelle compétence » pour A, puis E, puis R.

**Architecture:** Les 9 compétences s'ajoutent à `abilities.json` avec de nouveaux `type`. L'`AbilityCaster` gagne un état « verrouillé / débloqué » par emplacement. Le choix de carte de fin de vague reçoit, aux vagues prévues, une carte spéciale fabriquée en code à partir de la compétence à débloquer. Trois briques réutilisables portent les effets : un **saut** du héros (`Hero.dash`), une **zone au sol** (`GroundZone`, cercle ou segment épais, qui applique un effet aux ennemis dedans), et une lecture des **ennemis à l'écran** pour les ultimes.

**Tech Stack:** Godot 4.7.2, GDScript typé, données JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md` (sections 3.5 compétences, 9 étape 3)

## Global Constraints

- Godot 4.7.2, renderer Compatibility, export web ; viewport 1280×720 ; terrain 2400×1600, caméra qui suit le héros en combat.
- Toute valeur de jeu vient d'un fichier JSON de `assets/data/`, chargé par une classe `RefCounted` qui valide à la lecture et renvoie `null` + `push_error` nommant le fichier et la clé fautive.
- Interface construite en code ; aucun nouveau `.tscn`. Pas d'autoload ; dépendances passées par `setup(...)`.
- Ne jamais écrire d'attribut `uid=` ni de fichier `.uid`.
- Commentaires de doc (`##`) sur toute fonction publique ; typage statique partout.
- Compétences seulement en COMBAT, recharges qui ne descendent qu'en COMBAT, dégâts × `PlayerModifiers.damage_multiplier()`, durées de marque / brûlure / trempé lues sur l'arme du héros (comme en 3a).
- Les ennemis libérés (`is_queued_for_deletion()`) sont ignorés par tous les effets.
- Les effets restent dans le terrain (sauts, zones, ciblage à la souris).
- Hors périmètre : PV du héros (étape 4) — les sauts ne donnent donc pas encore d'invulnérabilité ; boss (le R passera après le premier boss à l'étape 6).

## Décisions prises pour cette étape (valeurs dans `abilities.json`, à régler en partie)

| Spé | Touche | Compétence | `type` | Recharge | Valeurs |
|---|---|---|---|---|---|
| Archer | A | Roulade | `dash_crit` | 5 s | saut de 180 px en 0,15 s ; la prochaine flèche normale du héros est critique |
| Archer | E | Pluie de flèches | `arrow_rain` | 12 s | cercle de rayon 120 sous la souris (au plus à 600 px du héros), 3 s, 8 dégâts toutes les 0,25 s à chaque ennemi dedans |
| Archer | R | Œil du chasseur | `hunter_eye` | 60 s | 8 s : chaque ennemi à l'écran est marqué (et reste marqué tant que dure l'effet) ; tous les tirs normaux du héros sont critiques |
| Feu | A | Bond enflammé | `dash_fire_trail` | 6 s | saut de 180 px en 0,15 s ; laisse un segment de flammes de largeur 40 sur le trajet, 3 s, qui enflamme les ennemis qui le touchent |
| Feu | E | Mur de feu | `fire_wall` | 12 s | segment de 300 px perpendiculaire à la visée, centré sous la souris (au plus à 500 px), épaisseur 30, 4 s, enflamme les ennemis qui le touchent |
| Feu | R | Météore | `meteor` | 60 s | cercle d'annonce de rayon 180 sous la souris (au plus à 700 px) pendant 1 s, puis 150 dégâts + brûlure à chaque ennemi dedans |
| Eau | A | Glissade | `dash_wet` | 6 s | saut de 200 px en 0,18 s ; trempe les ennemis à moins de 50 px du trajet |
| Eau | E | Flaque | `puddle` | 12 s | cercle de rayon 130 sous la souris (au plus à 600 px), 5 s, trempe et ralentit (facteur 0,6) les ennemis dedans ; près d'une tour de glace, le combo « trempé + glace » existant les gèle |
| Eau | R | Raz-de-marée | `tidal_wave` | 60 s | chaque ennemi à l'écran est trempé puis gelé 2 s (ignore le délai de regel) |

- **Direction des sauts** : la direction de déplacement (ZQSD) si une touche est tenue, sinon vers la souris. Le saut est bloqué par le bord du terrain. Pendant le saut, ZQSD ne pilote pas le héros ; le héros continue de tirer.
- **Ciblage à la souris trop loin** : le point est ramené à la portée maximale dans la direction de la souris, puis dans le terrain.
- **« À l'écran »** : le rectangle visible par la caméra au moment du lancement (et à chaque image pour l'Œil du chasseur).
- **Déblocage** : `"unlock_after_waves": [2, 4, 6]` dans `abilities.json` (ordre A, E, R). À la fin de chacune de ces vagues (et des suivantes tant que la compétence n'est pas prise), le choix de carte montre la carte « Nouvelle compétence : <nom> (<touche>) » à la place d'une des cartes tirées ; sa description est la `description` de la compétence. La prendre débloque la compétence ; ne pas la prendre la repropose au choix suivant. L'emplacement R suit la même règle pour l'instant (il passera après le premier boss à l'étape 6).
- **Barre** : une compétence verrouillée affiche son nom en gris avec « verrouillée » à la place des secondes.
- **Visuels** (formes et lumières) : zones = disque ou segment semi-transparent de la couleur de l'effet (flèches : blanc-jaune ; feu : orange ; eau : bleu clair) ; annonce du météore = cercle rouge qui se remplit en 1 s ; Œil du chasseur = contour jaune autour du héros pendant l'effet ; raz-de-marée = flash bleu clair plein écran de 0,3 s.

## Review Focus

1. **Saut contre le bord du terrain** : le héros s'arrête au bord, ne sort jamais. → Task 2.
2. **Zone posée près du bord ou souris hors de portée** : la zone reste entière dans le terrain, à la portée maximale. → Task 3.
3. **Œil du chasseur ou raz-de-marée sans ennemi à l'écran** : rien ne plante, la recharge part quand même. → Task 4.
4. **Carte « Nouvelle compétence » quand il ne reste aucune autre carte** : elle est quand même proposée ; et elle n'est jamais proposée deux fois pour la même compétence une fois prise. → Task 1.
5. **Changement de phase pendant un effet** (fin de vague, défaite) : zones et effets en cours n'agissent plus sur des ennemis libérés et disparaissent à la fin de leur durée ; l'Œil du chasseur prend fin. → Tasks 3 et 4.

## Vérification

Pas de tests automatiques exécutables ici (Godot absent, `qa.level: minimal`). Chaque tâche est relue par `godot-gdscript-specialist`, puis l'ensemble ; l'utilisateur joue avec la liste V-1 à V-8 (fin de la tâche 4).

---

### Task 1: Données, verrouillage et carte « Nouvelle compétence »

**Files:**
- Modify: `assets/data/abilities.json`, `src/abilities/ability_def.gd`, `src/abilities/ability_catalog.gd`, `src/abilities/ability_caster.gd`, `src/ui/ability_bar.gd`, `src/game/main.gd`

**Interfaces:**
- Produces:
  - `AbilityDef.description: String` (clé obligatoire, chaîne non vide, pour les 12 compétences).
  - `AbilityCatalog.unlock_after_waves: PackedInt32Array` (3 entiers > 0 strictement croissants) ; `TYPE_NUMBER_KEYS` étendu aux 9 nouveaux types avec exactement les clés de la table ci-dessous.
  - `AbilityCaster` : `func is_unlocked(slot: StringName) -> bool` (le clic droit l'est dès `equip`), `func unlock(slot: StringName) -> void` (émet `cooldowns_changed`), `func next_locked_slot() -> StringName` (premier de A, E, R encore verrouillé et existant ; `&""` sinon). Une compétence verrouillée ne se lance pas.
  - Carte de déblocage : un `CardDef` fabriqué en code (`id` = `"unlock_ability_" + slot`, `display_name` = `"Nouvelle compétence : %s (%s)"`, `description` = celle de la compétence, `effects` vide), reconnue dans `main.gd` par son `id`.

| `type` | Clés `values` (nombres > 0) |
|---|---|
| `dash_crit` | `distance`, `duration` |
| `dash_fire_trail` | `distance`, `duration`, `trail_width`, `trail_duration` |
| `dash_wet` | `distance`, `duration`, `wet_radius` |
| `arrow_rain` | `radius`, `max_range`, `duration`, `tick_interval`, `damage` |
| `fire_wall` | `length`, `thickness`, `max_range`, `duration` |
| `puddle` | `radius`, `max_range`, `duration`, `slow_factor` |
| `hunter_eye` | `duration` |
| `meteor` | `radius`, `max_range`, `delay`, `damage` |
| `tidal_wave` | `freeze_duration` |

- [ ] **Step 1: `abilities.json`** — ajouter `"unlock_after_waves": [2, 4, 6]`, une `description` (une phrase, en français, reprenant la table de la spec 3.5) aux 3 compétences existantes, et les 9 compétences de la table « Décisions » avec leurs valeurs exactes.
- [ ] **Step 2: catalogue et définition** — lire et valider le nouveau format.
- [ ] **Step 3: `AbilityCaster`** — verrouillage comme décrit ; `equip` verrouille A, E, R.
- [ ] **Step 4: `AbilityBar`** — affichage « verrouillée » comme décrit.
- [ ] **Step 5: `main.gd`** — dans `_open_card_choice` : si `_state.waves_completed` ≥ l'entrée de `unlock_after_waves` correspondant au prochain emplacement verrouillé, construire la carte de déblocage et la mettre en tête de l'offre, à la place de la dernière carte tirée si l'offre est pleine (et même si l'offre tirée est vide) ; dans `_on_card_chosen` : si c'est une carte de déblocage, `caster.unlock(slot)` au lieu de `modifiers.take(card)`.
- [ ] **Step 6: Relecture** puis **commit** `feat: compétences A, E, R en données et leur déblocage — étape 3b`.

---

### Task 2: Les sauts (A)

**Files:**
- Modify: `src/hero/hero.gd`, `src/specs/archer_weapon.gd`, `src/abilities/ability_caster.gd`
- Create: `src/abilities/effects/ground_zone.gd` (utilisée ici pour la traînée de flammes, et à la tâche 3)

**Interfaces:**
- Produces:
  - `Hero` : `signal dash_finished` ; `func dash(direction: Vector2, distance: float, duration: float) -> void` (déplacement à vitesse constante, bloqué par le bord du terrain, ZQSD ignoré pendant le saut, tir conservé) ; `func is_dashing() -> bool` ; `func move_direction() -> Vector2` (direction ZQSD courante, `Vector2.ZERO` si aucune).
  - `ArcherWeapon` : `func force_next_crit() -> void` ; `func set_always_crit(active: bool) -> void` ; `roll_crit()` renvoie `true` si l'un des deux est actif (le « prochain critique » est consommé par ce tir).
  - `class_name GroundZone extends Node2D` : `func setup_circle(radius: float, duration: float, color: Color, field_rect: Rect2, enemies: Node2D) -> void` ; `func setup_segment(from: Vector2, to: Vector2, thickness: float, duration: float, color: Color, field_rect: Rect2, enemies: Node2D) -> void` (points en coordonnées globales) ; `signal enemy_inside(enemy: Enemy, delta: float)` émis à chaque image physique pour chaque ennemi valide dont le corps touche la zone ; se libère seule à la fin de `duration` ; dessin selon « Décisions ».

- [ ] **Step 1: `Hero.dash`** et `move_direction`.
- [ ] **Step 2: `ArcherWeapon`** critiques forcés.
- [ ] **Step 3: `GroundZone`**.
- [ ] **Step 4: `AbilityCaster`** — types `dash_crit` (saut, puis `force_next_crit()`), `dash_fire_trail` (à la fin du saut, `GroundZone` segment du départ à l'arrivée, `enemy_inside` → `apply_burn` avec la brûlure de l'arme), `dash_wet` (pendant le saut, trempe les ennemis à moins de `wet_radius` du héros, chacun une fois).
- [ ] **Step 5: Relecture** puis **commit** `feat: Roulade, Bond enflammé, Glissade — étape 3b`.

---

### Task 3: Les zones (E)

**Files:**
- Modify: `src/abilities/ability_caster.gd`, `src/enemies/enemy.gd` (seulement si un ralentissement par zone n'est pas déjà possible via `apply_slow`)

**Interfaces:**
- Consumes: `GroundZone` (Task 2), `Enemy.take_damage`, `apply_burn`, `apply_wet`, `apply_slow(factor)` (ralentissement demandé à chaque image, comme la tour de glace).
- Produces: `AbilityCaster` gère `arrow_rain`, `fire_wall`, `puddle` ; `func _target_point(max_range: float) -> Vector2` (souris ramenée à la portée puis dans le terrain réduit du rayon ou de la demi-longueur de la zone).

- [ ] **Step 1: `arrow_rain`** — `GroundZone` cercle ; dégâts `damage × damage_multiplier()` à chaque ennemi dedans toutes les `tick_interval` secondes (un compteur par zone, pas par ennemi).
- [ ] **Step 2: `fire_wall`** — `GroundZone` segment perpendiculaire à la direction héros → point visé, centré sur ce point ; `apply_burn` avec la brûlure de l'arme.
- [ ] **Step 3: `puddle`** — `GroundZone` cercle ; `apply_wet` (durée de l'arme) et `apply_slow(slow_factor)` à chaque image.
- [ ] **Step 4: Relecture** puis **commit** `feat: Pluie de flèches, Mur de feu, Flaque — étape 3b`.

---

### Task 4: Les ultimes (R)

**Files:**
- Create: `src/abilities/effects/meteor.gd`
- Modify: `src/abilities/ability_caster.gd`, `src/enemies/enemy.gd` (gel forcé)

**Interfaces:**
- Produces:
  - `AbilityCaster` gère `hunter_eye`, `meteor`, `tidal_wave` ; `func _enemies_on_screen() -> Array[Enemy]` (ennemis valides dans le rectangle visible : inverse de `get_viewport().get_canvas_transform()` appliqué au rectangle du viewport).
  - `Enemy.force_freeze(duration: float) -> void` — gèle sans tenir compte du délai de regel (même affichage que le gel existant).
  - `class_name Meteor extends Node2D` : `func setup(radius: float, delay: float, damage: float, burn_duration: float, burn_dps: float, enemies: Node2D) -> void`.

- [ ] **Step 1: `hunter_eye`** — pendant `duration` : `set_always_crit(true)` sur l'arme de l'Archer, marque (durée = temps restant) chaque ennemi à l'écran à chaque image physique, contour jaune autour du héros ; à la fin (ou en quittant COMBAT) : `set_always_crit(false)`.
- [ ] **Step 2: `Meteor`** — annonce puis explosion comme décrit.
- [ ] **Step 3: `tidal_wave`** — chaque ennemi à l'écran : `apply_wet` (durée de l'arme) puis `force_freeze(freeze_duration)` ; flash plein écran.
- [ ] **Step 4: Relecture**, relecture finale de la branche, puis **commit et push** `feat: Œil du chasseur, Météore, Raz-de-marée — étape 3b`.

- [ ] **Step 5: Partie jouée par l'utilisateur**

| N° | À vérifier | Attendu |
|---|---|---|
| V-1 | Début de partie | A, E, R affichent leur nom en gris et « verrouillée » ; les touches ne font rien |
| V-2 | Fin de la vague 2 | Le choix propose « Nouvelle compétence : … (A) » ; la prendre débloque A |
| V-3 | Ne pas la prendre | Elle revient au choix suivant |
| V-4 | Les 3 sauts (A) | Le héros saute dans la direction de déplacement (ou vers la souris), s'arrête au bord ; effet propre à la spé (critique, flammes, trempe) |
| V-5 | Les 3 zones (E) | Zone sous la souris (ou à portée max), visible, qui agit sur les ennemis dedans |
| V-6 | Les 3 ultimes (R) | Œil : tirs critiques + ennemis marqués 8 s ; Météore : annonce 1 s puis grosse explosion ; Raz-de-marée : ennemis à l'écran gelés 2 s |
| V-7 | Flaque près d'une tour de glace | Les ennemis trempés gèlent |
| V-8 | Fin de vague pendant une zone ou l'Œil | Rien ne plante, les effets s'arrêtent |

Captures à conserver dans `production/qa/evidence/story-017-competences-a-e-r/` : une carte « Nouvelle compétence », et une compétence E ou R en action.
