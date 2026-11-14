# Étape 3a — Système de compétences et clic droit : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Donner au héros des compétences actives : un système générique (données, recharges, touches clic droit / A / E / R, barre d'affichage en bas de l'écran) et la compétence du clic droit de chaque spécialisation existante (Archer : Flèche perforante ; Maître du feu : Boule de feu ; Maître de l'eau : Vague).

**Architecture:** Les compétences sont décrites dans `assets/data/abilities.json` et chargées par `AbilityCatalog`. Un nœud `AbilityCaster` connaît les compétences de la spé choisie, gère les recharges et lit les touches en COMBAT ; pour lancer une compétence il crée l'effet correspondant à son `type` (un script par type dans `src/abilities/effects/`). Une `AbilityBar` dans le HUD affiche les 4 emplacements, leur nom et leur recharge.

**Tech Stack:** Godot 4.7.2, GDScript typé, données JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md` (sections 3.2 commandes, 3.5 compétences, 9 étape 3)

## Global Constraints

- Godot 4.7.2, renderer Compatibility, export web ; viewport 1280×720 ; terrain 2400×1600, caméra qui suit le héros en combat.
- Toute valeur de jeu vient d'un fichier JSON de `assets/data/`, chargé par une classe `RefCounted` qui valide à la lecture et renvoie `null` + `push_error` nommant le fichier et la clé fautive.
- Interface construite en code ; aucun nouveau `.tscn`. Pas d'autoload ; dépendances passées par `setup(...)`.
- Ne jamais écrire d'attribut `uid=` ni de fichier `.uid`.
- Commentaires de doc (`##`) sur toute fonction publique ; typage statique partout.
- Touches : clic droit = compétence principale, **A**, **E**, **R** (AZERTY, mêmes `keycode` que les actions existantes : `move_up` utilise `keycode` 90 pour Z) ; clic gauche reste la désignation (combat) / pose de tour (préparation).
- Les compétences ne se lancent qu'en COMBAT ; les recharges continuent de descendre en COMBAT seulement (pas pendant la préparation ni les choix).
- Les dégâts des compétences sont multipliés par `PlayerModifiers.damage_multiplier()` (comme les armes).
- Hors périmètre : A, E, R et leur déblocage (étape 3b) ; PV du héros (étape 4).

## Décisions prises pour cette étape

- **Valeurs** (dans `abilities.json`) :

| Compétence | Recharge | Valeurs |
|---|---|---|
| Flèche perforante (Archer) | 6 s | dégâts 42 (3 × 14), vitesse 1100, portée 1200, rayon 9, traverse tous les ennemis, marque chaque ennemi touché pendant la durée de marque de l'arme (4 s) |
| Boule de feu (Maître du feu) | 5 s | dégâts d'explosion 30, rayon d'explosion 110, vitesse 600, portée 700, rayon 10 ; explose au premier ennemi touché ou en fin de portée ; enflamme tous les ennemis de l'explosion avec la brûlure de l'arme (3 s, 6 dégâts/s) |
| Vague (Maître de l'eau) | 6 s | cône de 70° vers la souris, portée 260, dégâts 12, repousse de 140 pixels (sur 0,2 s), trempe avec la durée de l'arme (5 s) |

- **Direction** : toutes les compétences du clic droit partent vers la souris.
- **Les cartes de la spé s'appliquent aux compétences quand c'est naturel** : bonus de dégâts (via `damage_multiplier`), bonus de durée de marque / brûlure / trempé (en lisant les valeurs de l'arme via `ArcherWeapon` / `ElementalWeapon`, qui intègrent déjà les cartes).
- **Barre de compétences** : 4 cases en bas au centre, au-dessus des boutons de tours (qui ne sont visibles qu'en préparation) ; chaque case montre la touche (« Clic droit », « A », « E », « R »), le nom de la compétence, et pendant la recharge un voile sombre + les secondes restantes arrondies au-dessus. Une case sans compétence affiche « — » en gris.
- **Effets visuels simples** (étape « formes et lumières ») : flèche perforante = trait blanc-jaune épais ; boule de feu = disque orange, explosion = cercle orange qui s'étend et s'efface en 0,3 s ; vague = arc de cercle bleu clair qui s'étend jusqu'à la portée en 0,25 s.

## Review Focus

1. **Lancer une compétence pendant la préparation ou un choix de carte** : rien ne se passe, la recharge ne bouge pas. → Task 2.
2. **Clic droit sur un bouton du HUD ou pendant un écran de choix** : ne lance rien (l'écran consomme le clic). → Task 2.
3. **Boule de feu qui sort du terrain** : elle explose en fin de portée ou au bord du terrain, jamais au-delà. → Task 3.
4. **Vague qui repousse un ennemi gelé ou contre le bord** : un ennemi gelé n'est pas déplacé ; aucun ennemi n'est poussé hors du terrain. → Task 3.
5. **Compétence lancée sur des ennemis libérés à l'arrivée du cristal** : aucun plantage, aucun or (les ennemis en cours de libération ignorent les dégâts). → Tasks 2 et 3.

## Vérification

Pas de tests automatiques exécutables ici (Godot absent, `qa.level: minimal`). Chaque tâche est relue par `godot-gdscript-specialist`, puis l'ensemble ; l'utilisateur joue avec la liste V-1 à V-7 (fin de la tâche 3).

---

## Fichiers

| Fichier | Rôle | Tâche |
|---|---|---|
| `assets/data/abilities.json` (nouveau) | Les compétences et leurs valeurs | 1 |
| `src/abilities/ability_def.gd`, `src/abilities/ability_catalog.gd` (nouveaux) | Chargement et validation | 1 |
| `project.godot` | Actions `ability_primary`, `ability_a`, `ability_e`, `ability_r` | 1 |
| `src/abilities/ability_caster.gd` (nouveau) | Recharges, touches, lancement | 2 |
| `src/abilities/effects/piercing_arrow.gd` (nouveau) | Flèche perforante | 2 |
| `src/ui/ability_bar.gd` (nouveau), `src/ui/crystal_hud.gd` | Barre de compétences | 2 |
| `src/game/main.gd` | Charge le catalogue, crée le lanceur, branche la barre | 2 |
| `src/abilities/effects/fireball.gd`, `src/abilities/effects/water_wave.gd` (nouveaux) | Boule de feu, Vague | 3 |
| `src/enemies/enemy.gd` | `push(offset: Vector2, duration: float)` | 3 |

---

### Task 1: Données des compétences et touches

**Files:**
- Create: `assets/data/abilities.json`, `src/abilities/ability_def.gd`, `src/abilities/ability_catalog.gd`
- Modify: `project.godot` (section `[input]`)

**Interfaces:**
- Produces:
  - `class_name AbilityDef extends RefCounted` : `id: String`, `spec_id: String`, `slot: StringName` (`&"primary"`, `&"a"`, `&"e"`, `&"r"`), `display_name: String`, `cooldown: float`, `type: String`, `values: Dictionary` (nombres du type).
  - `class_name AbilityCatalog extends RefCounted` :
    - `const TYPE_NUMBER_KEYS := { "piercing_arrow": ["damage", "speed", "range", "radius"], "fireball": ["damage", "explosion_radius", "speed", "range", "radius"], "water_wave": ["damage", "angle_degrees", "range", "push_distance", "push_duration"] }`
    - `static func load_from_file(path: String, specs: SpecializationCatalog) -> AbilityCatalog` — `spec_id` doit exister dans `specs` ; `slot` dans les 4 valeurs ; `cooldown` > 0 ; un seul couple (`spec_id`, `slot`) ; `type` connu et toutes ses clés nombres > 0.
    - `func for_spec(spec_id: String) -> Dictionary` — `{ slot: AbilityDef }` pour cette spé.
  - Actions d'entrée : `ability_primary` (bouton droit de la souris, `InputEventMouseButton` `button_index` 2), `ability_a` (`keycode` 65), `ability_e` (`keycode` 69), `ability_r` (`keycode` 82).

- [ ] **Step 1: `assets/data/abilities.json`**

```json
{
	"abilities": [
		{ "id": "fleche_perforante", "spec_id": "archer", "slot": "primary", "display_name": "Flèche perforante", "cooldown": 6.0,
		  "type": "piercing_arrow", "values": { "damage": 42.0, "speed": 1100.0, "range": 1200.0, "radius": 9.0 } },
		{ "id": "boule_de_feu", "spec_id": "maitre_feu", "slot": "primary", "display_name": "Boule de feu", "cooldown": 5.0,
		  "type": "fireball", "values": { "damage": 30.0, "explosion_radius": 110.0, "speed": 600.0, "range": 700.0, "radius": 10.0 } },
		{ "id": "vague", "spec_id": "maitre_eau", "slot": "primary", "display_name": "Vague", "cooldown": 6.0,
		  "type": "water_wave", "values": { "damage": 12.0, "angle_degrees": 70.0, "range": 260.0, "push_distance": 140.0, "push_duration": 0.2 } }
	]
}
```

- [ ] **Step 2: `AbilityDef` et `AbilityCatalog`** — sur le modèle de `SpecializationCatalog` (`src/specs/specialization_catalog.gd`).

- [ ] **Step 3: Actions dans `project.godot`** — ajouter les 4 actions à la section `[input]`, au même format que `start_wave` (copier sa structure ; `InputEventMouseButton` pour le clic droit, avec `"button_index":2`).

- [ ] **Step 4: Relecture** par `godot-gdscript-specialist`.

- [ ] **Step 5: Commit**

```bash
git add assets/data/abilities.json src/abilities/ability_def.gd src/abilities/ability_catalog.gd project.godot
git commit -m "feat: données des compétences et touches clic droit, A, E, R — étape 3a"
```

---

### Task 2: Lanceur, barre de compétences et Flèche perforante

**Files:**
- Create: `src/abilities/ability_caster.gd`, `src/abilities/effects/piercing_arrow.gd`, `src/ui/ability_bar.gd`
- Modify: `src/ui/crystal_hud.gd`, `src/game/main.gd`

**Interfaces:**
- Consumes: `AbilityCatalog.for_spec`, `AbilityDef`, `GameState.phase` / `phase_changed`, `PlayerModifiers.damage_multiplier()`, `Hero` (position, `equip`), `ArcherWeapon.mark_duration()`.
- Produces:
  - `class_name AbilityCaster extends Node` :
    - `signal cooldowns_changed` — émis quand une recharge change de seconde affichée, ou après un lancement
    - `func setup(state: GameState, hero: Hero, enemies: Node2D, bullets: Node2D, field_rect: Rect2, modifiers: PlayerModifiers, rules: ProcRules) -> void`
    - `func equip(abilities: Dictionary) -> void` — `{ slot: AbilityDef }` de la spé choisie
    - `func ability(slot: StringName) -> AbilityDef` (null si aucune)
    - `func cooldown_left(slot: StringName) -> float`
  - `Hero` expose ce dont les effets ont besoin pour lire les valeurs d'arme : `func archer_weapon() -> ArcherWeapon`, `func elemental_weapon() -> ElementalWeapon` (null selon la spé).
  - `class_name PiercingArrow extends Area2D` : `func setup(def: AbilityDef, direction: Vector2, field_rect: Rect2, damage: float, mark_duration: float) -> void`
  - `class_name AbilityBar extends Control` : `func setup(caster: AbilityCaster) -> void`
  - `CrystalHud` : `func bind_abilities(caster: AbilityCaster) -> void` (crée la barre).

- [ ] **Step 1: `AbilityCaster`**
  - `_unhandled_input` : en COMBAT seulement, `ability_primary` / `ability_a` / `ability_e` / `ability_r` pressé → si la compétence existe et que sa recharge est à 0 : la lancer, mettre la recharge à `def.cooldown`, marquer l'événement traité, émettre `cooldowns_changed`.
  - `_physics_process` : en COMBAT seulement, fait descendre les recharges.
  - Lancement selon `def.type` : `"piercing_arrow"` → crée une `PiercingArrow` sous `bullets`, à la position du héros, direction = vers la souris (`hero.get_global_mouse_position()`), dégâts `values.damage × modifiers.damage_multiplier()`, marque = `hero.archer_weapon().mark_duration()`. Les types `"fireball"` et `"water_wave"` sont ajoutés à la tâche 3 : jusque-là, un type non géré ne fait rien (sans erreur).

- [ ] **Step 2: `PiercingArrow`** — `Area2D` sur le modèle de `HeroBullet` (`src/hero/hero_bullet.gd` : couche, détection, sortie de terrain, `call_deferred` pour les effets) : avance en ligne droite, touche **chaque** ennemi une seule fois (garder la liste des touchés), ne s'arrête pas, disparaît après `range` pixels ou hors du terrain ; à chaque ennemi touché : `take_damage(damage)` puis `apply_mark(mark_duration)`. Dessin : trait blanc-jaune `Color(1.0, 0.95, 0.6)` de longueur 28 et épaisseur `radius`.

- [ ] **Step 3: `AbilityBar` et `CrystalHud.bind_abilities`** — comme décrit dans « Décisions » ; la barre se met à jour sur `cooldowns_changed` et chaque image pendant une recharge.

- [ ] **Step 4: `main.gd`** — charger `AbilityCatalog` (`res://assets/data/abilities.json`) avec les autres données ; créer l'`AbilityCaster` en code (enfant de Main) et le `setup` ; dans `_on_spec_chosen`, `caster.equip(catalog.for_spec(spec.id))` ; `hud.bind_abilities(caster)`.

- [ ] **Step 5: Relecture** par `godot-gdscript-specialist`.

- [ ] **Step 6: Commit**

```bash
git add src/abilities/ability_caster.gd src/abilities/effects/piercing_arrow.gd src/ui/ability_bar.gd src/ui/crystal_hud.gd src/game/main.gd src/hero/hero.gd
git commit -m "feat: lanceur de compétences, barre des touches, Flèche perforante — étape 3a"
```

---

### Task 3: Boule de feu et Vague

**Files:**
- Create: `src/abilities/effects/fireball.gd`, `src/abilities/effects/water_wave.gd`
- Modify: `src/abilities/ability_caster.gd`, `src/enemies/enemy.gd`

**Interfaces:**
- Consumes: `AbilityCaster` (Task 2), `ElementalWeapon.burn_duration()`, `burn_damage_per_second()`, `wet_duration()`, `Enemy.apply_burn`, `Enemy.apply_wet`, `Enemy.take_damage`.
- Produces:
  - `Enemy.push(offset: Vector2, duration: float) -> void` — déplace l'ennemi de `offset` réparti sur `duration` secondes, en plus de sa marche ; sans effet si l'ennemi est gelé ; la position reste dans le terrain (passer le rectangle du terrain à l'ennemi si besoin, ou borner par le spawner).
  - `class_name Fireball extends Area2D` : `func setup(def: AbilityDef, direction: Vector2, field_rect: Rect2, enemies: Node2D, damage: float, burn_duration: float, burn_dps: float) -> void`
  - `class_name WaterWave extends Node2D` : `func setup(def: AbilityDef, direction: Vector2, enemies: Node2D, damage: float, wet_duration: float) -> void`

- [ ] **Step 1: `Enemy.push`** — comme décrit.

- [ ] **Step 2: `Fireball`** — avance vers la souris ; explose au premier ennemi touché, en fin de portée ou en sortant du terrain ; l'explosion touche tous les ennemis valides à moins de `explosion_radius` : `take_damage(damage)` puis `apply_burn(burn_duration, burn_dps)` ; dessin de l'explosion comme dans « Décisions », puis libération.

- [ ] **Step 3: `WaterWave`** — instantanée au lancement : tous les ennemis valides à moins de `range` du héros et dans le cône de `angle_degrees` (centré sur la direction de la souris) : `take_damage(damage)`, `apply_wet(wet_duration)`, `push(direction_depuis_le_héros × push_distance, push_duration)` ; dessin de l'arc comme dans « Décisions », puis libération.

- [ ] **Step 4: `AbilityCaster`** — ajouter les types `"fireball"` et `"water_wave"` (valeurs de brûlure et trempé lues sur `hero.elemental_weapon()`, dégâts × `damage_multiplier()`).

- [ ] **Step 5: Relecture** par `godot-gdscript-specialist`, puis relecture finale de la branche.

- [ ] **Step 6: Commit et push**

```bash
git add src/abilities/effects/fireball.gd src/abilities/effects/water_wave.gd src/abilities/ability_caster.gd src/enemies/enemy.gd
git commit -m "feat: Boule de feu et Vague — étape 3a"
git push origin main
```

- [ ] **Step 7: Partie jouée par l'utilisateur**

| N° | À vérifier | Attendu |
|---|---|---|
| V-1 | En combat, barre en bas au centre | 4 cases : « Clic droit » avec le nom de la compétence de la spé, « A », « E », « R » en gris avec « — » |
| V-2 | Archer, clic droit vers un groupe | Une grosse flèche traverse tous les ennemis alignés, les blesse et les marque ; la case montre 6 s de recharge qui descend |
| V-3 | Clic droit pendant la recharge | Rien ne part |
| V-4 | Maître du feu, clic droit | Boule de feu qui explose sur le premier ennemi, enflamme ceux autour |
| V-5 | Maître de l'eau, clic droit | Arc bleu devant le héros ; les ennemis dans le cône sont repoussés et trempés ; près d'une tour de glace, ils gèlent |
| V-6 | Clic droit en préparation ou pendant un choix de carte | Rien ne se passe ; la recharge ne bouge pas |
| V-7 | A, E, R | Rien ne se passe (étape 3b) |

Captures à conserver dans `production/qa/evidence/story-016-competence-principale/` : la barre en combat, et une compétence en action.
