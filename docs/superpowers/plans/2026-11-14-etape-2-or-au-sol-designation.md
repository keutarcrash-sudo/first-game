# Étape 2 — Or au sol et désignation : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** L'or n'est plus donné automatiquement : chaque ennemi tué lâche une pièce au sol, qui disparaît au bout d'un moment et que le héros ramasse en passant à portée. Pendant le combat, un clic gauche sur un ennemi le désigne : les canons à portée le visent en priorité jusqu'à sa mort.

**Architecture:** Un nœud `GoldField` possède et dessine toutes les pièces au sol (données légères, pas un nœud par pièce), les fait vieillir et les donne au `GameState` quand le héros passe à portée. Le `WaveSpawner` transmet la position de l'ennemi tué ; le `WaveCycle` demande une pièce au `GoldField` au lieu d'ajouter l'or. Un nœud `TargetDesignator` gère le clic gauche en COMBAT, garde la cible désignée et dessine sa marque ; les canons le consultent avant de prendre l'ennemi le plus proche.

**Tech Stack:** Godot 4.7.2, GDScript typé, données JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md` (sections 3.2, 3.3, 4.1, 9 étape 2)

## Global Constraints

- Godot 4.7.2, renderer Compatibility, export web ; viewport 1280×720 ; terrain 2400×1600, caméra qui suit le héros en combat.
- Toute valeur de jeu vient d'un fichier JSON de `assets/data/`, chargé par une classe `RefCounted` qui valide à la lecture et renvoie `null` + `push_error` nommant le fichier et la clé fautive (modèle : `src/crystal/defence_stats.gd`).
- Interface construite en code ; aucun nouveau `.tscn`. Pas d'autoload ; dépendances passées par `setup(...)`.
- Ne jamais écrire d'attribut `uid=` ni de fichier `.uid`.
- Commentaires de doc (`##`) sur toute fonction publique ; typage statique partout.
- L'or tombe des ennemis tués et disparaît au bout d'environ 10 s (données) ; le héros le ramasse en passant dans sa portée de ramassage (spec 3.2).
- L'or encore au sol à la fin de la vague est perdu ; l'or non dépensé reste au joueur (spec 3.3).
- Désignation : clic gauche sur un ennemi ; les tours à portée le visent en priorité jusqu'à sa mort, puis reprennent leur cible par défaut ; pas de limite ni de temps de recharge ; une seule cible à la fois, un nouveau clic remplace l'ancienne (spec 3.2).
- Cible par défaut des tours : l'ennemi le plus proche (spec 3.2).
- Hors périmètre : objets « aimant » et magasin (étape 5), compétences (étape 3), nouveaux ennemis (étape 4).

## Décisions prises pour cette étape

- **Plus de bonus d'or automatique en fin de vague** : la spec dit que l'or est ramassé au sol (4.1, 9.2). La clé `gold_per_wave_bonus` disparaît.
- **Or par ennemi : 15** (au lieu de 10) pour compenser la fin du bonus de vague. À régler en partie.
- **Toutes les morts lâchent de l'or**, quel que soit le tueur (héros, canon, brûlure). La carte « or par ennemi » (`gold_per_kill_bonus`) s'ajoute à la valeur de la pièce.
- **Portée de ramassage de départ : 70 pixels** (données). Elle sera améliorable par les objets « aimant » à l'étape 5.
- **Ramassage instantané** quand la pièce entre dans la portée (pas d'animation d'attraction pour l'instant).
- **Clignotement** pendant les 3 dernières secondes de vie d'une pièce, pour prévenir qu'elle va disparaître.
- **Désignation : seuls les canons sont concernés.** La tour de glace ralentit tout ce qui est dans sa zone, elle n'a pas de cible.
- **Clic dans le vide** : ne change rien (la cible désignée reste).
- **Tolérance du clic** : un ennemi est désigné si le clic tombe à moins de (rayon de l'ennemi + 12 pixels) de son centre ; s'il y en a plusieurs, le plus proche du clic.
- **Marque de la cible** : un anneau rouge-orangé qui pulse autour de l'ennemi désigné, distinct des marques d'état existantes (jaune « marqué », orange « brûle », etc.).

## Review Focus

1. **Ennemi tué par une brûlure ou par un canon loin du héros** : la pièce tombe quand même à sa position, et disparaît après 10 s si personne ne la ramasse. → Task 1, V-2.
2. **Cible désignée qui meurt, touche le cristal ou est libérée à l'arrivée** : aucun canon ne doit planter en lisant une cible libérée ; ils reviennent à l'ennemi le plus proche. → Task 2, règle `is_instance_valid` + `is_queued_for_deletion`.
3. **Cible désignée hors de portée d'un canon** : ce canon tire sur l'ennemi le plus proche à sa portée au lieu de rester inactif. → Task 2.
4. **Clic gauche en préparation** : il pose une tour comme avant, et ne désigne rien. Clic gauche en combat : ne pose pas de tour. → Task 2, V-5.
5. **Fin de vague** : les pièces au sol disparaissent sans donner d'or ; la désignation est effacée. → Tasks 1 et 2.

## Vérification

Pas de tests automatiques exécutables ici (Godot absent de la session cloud, `qa.level: minimal`). Chaque tâche est relue par `godot-gdscript-specialist`, puis l'ensemble par une relecture finale ; l'utilisateur joue ensuite avec la liste V-1 à V-7 (fin de la tâche 2).

---

## Fichiers

| Fichier | Rôle | Tâche |
|---|---|---|
| `src/economy/gold_field.gd` (nouveau) | Pièces au sol : création, vieillissement, ramassage, dessin | 1 |
| `src/game/economy_stats.gd`, `assets/data/economy.json` | `gold_per_kill` 15, `gold_lifetime`, `gold_blink_time`, `pickup_radius` ; retrait de `gold_per_wave_bonus` | 1 |
| `src/waves/wave_spawner.gd` | `enemy_killed(position: Vector2)` | 1 |
| `src/game/wave_cycle.gd` | Lâche une pièce au lieu d'ajouter l'or ; plus de bonus de vague | 1 |
| `src/game/main.gd` | Crée le `GoldField`, le vide en fin de vague ; crée le `TargetDesignator` | 1, 2 |
| `src/towers/target_designator.gd` (nouveau) | Clic gauche en combat, cible désignée, marque | 2 |
| `src/towers/tower_stats.gd`, `assets/data/towers.json` | `designation.click_margin` | 2 |
| `src/towers/cannon_tower.gd` | Vise la cible désignée si elle est à portée | 2 |
| `src/towers/tower_placer.gd` | Passe le désignateur aux canons | 2 |

---

### Task 1: L'or tombe au sol et se ramasse

**Files:**
- Create: `src/economy/gold_field.gd`
- Modify: `src/game/economy_stats.gd`, `assets/data/economy.json`, `src/waves/wave_spawner.gd`, `src/game/wave_cycle.gd`, `src/game/main.gd`

**Interfaces:**
- Produces:
  - `EconomyStats` : `starting_gold: int` (≥ 0), `gold_per_kill: int` (> 0), `gold_lifetime: float` (> 0), `gold_blink_time: float` (> 0 et < `gold_lifetime`), `pickup_radius: float` (> 0). `gold_per_wave_bonus` supprimé.
  - `class_name GoldField extends Node2D` :
    - `func setup(state: GameState, hero: Node2D, economy: EconomyStats) -> void`
    - `func drop(at: Vector2, amount: int) -> void` — ajoute une pièce
    - `func clear() -> void` — retire toutes les pièces sans donner d'or
    - `func count() -> int` — nombre de pièces au sol
  - `WaveSpawner` : `signal enemy_killed(position: Vector2)` (position de l'ennemi à sa mort)
  - `WaveCycle.setup(...)` reçoit en plus `gold_field: GoldField` en dernier paramètre.

- [ ] **Step 1: Données** — `assets/data/economy.json` :

```json
{
	"starting_gold": 100,
	"gold_per_kill": 15,
	"gold_lifetime": 10.0,
	"gold_blink_time": 3.0,
	"pickup_radius": 70.0
}
```

`EconomyStats` lit et valide ces clés (même modèle qu'aujourd'hui) ; `gold_blink_time >= gold_lifetime` est refusé avec un `push_error` nommant `gold_blink_time`.

- [ ] **Step 2: `GoldField`**
  - Chaque pièce = `{ position: Vector2, amount: int, age: float }` dans un `Array[Dictionary]` ; pas un nœud par pièce.
  - `_physics_process(delta)` : vieillit chaque pièce ; retire celles dont `age >= gold_lifetime` ; donne (`state.add_gold(amount)`) et retire celles à moins de `pickup_radius` du héros. `queue_redraw()` quand la liste change ou qu'une pièce clignote.
  - `_draw()` : pièce = disque doré `Color(1.0, 0.85, 0.25)` de rayon 7 avec contour `Color(1.0, 0.97, 0.7)` ; pendant les `gold_blink_time` dernières secondes, la pièce n'est dessinée qu'une demi-période sur deux (période 0,25 s).
  - Le héros n'est lu que s'il est valide (`is_instance_valid`).

- [ ] **Step 3: `WaveSpawner`** — `enemy_killed` porte la position : à la connexion de `died`, émettre `enemy_killed(enemy.global_position)` (lier l'ennemi). Le reste du spawner ne change pas.

- [ ] **Step 4: `WaveCycle`** — sur `enemy_killed(position)` : `kills += 1` puis `gold_field.drop(position, economy.gold_per_kill + modifiers.gold_per_kill_bonus())`. Supprimer l'ajout du bonus de fin de vague. Mettre à jour le commentaire de classe.

- [ ] **Step 5: `main.gd`** — créer le `GoldField` en code, enfant de Main placé juste avant `Enemies` (sous les ennemis), `setup(state, hero, economy)` ; le passer à `WaveCycle.setup` ; connecter `_spawner.wave_finished` à `gold_field.clear` (comme `clear_towers`).

- [ ] **Step 6: Relecture** par `godot-gdscript-specialist`.

- [ ] **Step 7: Commit**

```bash
git add src/economy/gold_field.gd src/game/economy_stats.gd assets/data/economy.json src/waves/wave_spawner.gd src/game/wave_cycle.gd src/game/main.gd
git commit -m "feat: l'or tombe au sol et se ramasse — étape 2"
```

---

### Task 2: Désigner une cible au clic gauche

**Files:**
- Create: `src/towers/target_designator.gd`
- Modify: `src/towers/tower_stats.gd`, `assets/data/towers.json`, `src/towers/cannon_tower.gd`, `src/towers/tower_placer.gd`, `src/game/main.gd`

**Interfaces:**
- Consumes: `GameState.phase_changed`, `GameState.phase`, `WaveSpawner.wave_finished`, `Enemy` (enfants du nœud `Enemies`, `is_queued_for_deletion()`).
- Produces:
  - `TowerStats` : `var designation_click_margin: float` lu dans `"designation": { "click_margin": 12.0 }` de `towers.json` (clé obligatoire, nombre > 0).
  - `class_name TargetDesignator extends Node2D` :
    - `func setup(state: GameState, enemies: Node2D, stats: TowerStats) -> void`
    - `func target() -> Enemy` — la cible désignée, ou `null` si aucune ou si elle n'est plus valide (`is_instance_valid` faux ou `is_queued_for_deletion()`)
    - `func clear() -> void`
  - `CannonTower.setup(...)` reçoit en plus `designator: TargetDesignator` en dernier paramètre.
  - `TowerPlacer.setup(...)` reçoit en plus `designator: TargetDesignator` en dernier paramètre et le passe à chaque canon.

- [ ] **Step 1: Données** — ajouter à `assets/data/towers.json` : `"designation": { "click_margin": 12.0 }` ; `TowerStats` le lit et le valide.

- [ ] **Step 2: `TargetDesignator`**
  - `_unhandled_input` : seulement en `COMBAT`, clic gauche pressé → position monde du clic (`get_global_mouse_position()`) → parmi les ennemis valides, celui dont le centre est le plus proche du clic, à condition que la distance soit ≤ rayon de l'ennemi + `click_margin` (le rayon est lu sur l'ennemi : exposer `Enemy.radius() -> float` si rien d'équivalent n'existe). Si un ennemi est trouvé, il devient la cible (remplace l'ancienne) et l'événement est marqué traité ; sinon rien ne change.
  - Quitter `COMBAT` efface la cible.
  - `_draw()` (chaque image tant qu'une cible valide existe) : anneau `Color(1.0, 0.35, 0.15)`, largeur 4, rayon = rayon de l'ennemi + 10 + 3 × sin(temps × 8), à la position de la cible. Rien n'est dessiné sans cible.

- [ ] **Step 3: `CannonTower`** — choix de la cible : si `designator.target()` est valide et à portée de ce canon, la viser ; sinon l'ennemi le plus proche à portée (code actuel).

- [ ] **Step 4: `TowerPlacer`** — nouveau paramètre `designator`, transmis à chaque `CannonTower.setup`.

- [ ] **Step 5: `main.gd`** — créer le `TargetDesignator` en code (enfant de Main, après `Enemies`, pour que la marque soit dessinée au-dessus des ennemis), `setup(state, enemies, tower_stats)`, le passer à `TowerPlacer.setup` ; connecter `_spawner.wave_finished` à `designator.clear`.

- [ ] **Step 6: Relecture** par `godot-gdscript-specialist`, puis relecture finale de la branche.

- [ ] **Step 7: Commit et push**

```bash
git add src/towers/target_designator.gd src/towers/tower_stats.gd assets/data/towers.json src/towers/cannon_tower.gd src/towers/tower_placer.gd src/game/main.gd src/enemies/enemy.gd
git commit -m "feat: désignation de cible au clic gauche — étape 2"
git push origin main
```

- [ ] **Step 8: Partie jouée par l'utilisateur**

| N° | À vérifier | Attendu |
|---|---|---|
| V-1 | Tuer un ennemi | Une pièce dorée apparaît où il est mort ; l'or n'augmente pas tant qu'on ne la ramasse pas |
| V-2 | Laisser une pièce loin du héros | Elle clignote les 3 dernières secondes puis disparaît au bout de 10 s |
| V-3 | Passer près d'une pièce | Elle disparaît et l'or augmente de 15 (plus le bonus de carte si pris) |
| V-4 | Fin de vague avec des pièces au sol | Elles disparaissent sans donner d'or ; plus de bonus d'or automatique |
| V-5 | En combat, clic gauche sur un ennemi | Anneau rouge-orangé qui pulse autour de lui ; les canons à portée tirent dessus ; un clic dans le vide ne change rien ; aucune tour n'est posée |
| V-6 | La cible désignée meurt | L'anneau disparaît ; les canons reprennent l'ennemi le plus proche ; on peut cliquer sur le suivant |
| V-7 | En préparation, clic gauche | Pose une tour comme avant |

Captures à conserver dans `production/qa/evidence/story-015-or-au-sol-designation/` : des pièces au sol pendant un combat, et un ennemi désigné.
