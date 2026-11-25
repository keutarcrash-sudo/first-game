# Tours T1 — Réserve, branches, glace de soutien : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Les tours deviennent une réserve achetée à prix croissant, reposée gratuitement à chaque construction, améliorable avec un choix de branche ; la glace gèle et les ennemis gelés subissent plus de dégâts ; quatre cartes de tours.

**Architecture:** Chaque tour possédée est une fiche (`TowerRecord` : id, type, niveau, branche) dans une `TowerReserve` pure et testable. Poser crée le nœud depuis sa fiche, et reprendre ou finir la vague le supprime en gardant la fiche. Les règles de gel (temps passé dans la zone, temps d'attente avant de regeler, vulnérabilité) vivent dans `Enemy`, avec une petite partie pure testable (`ChillRules`). Les effets en chaîne passent par un `ChainLimiter` (plafond par image).

**Tech Stack:** Godot 4.7.2 / GDScript typé ; JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-25-tours-t1-reserve-design.md` (lire surtout §5 à §8bis).

## Global Constraints

- Prix d'achat : 50 puis +25 par tour **déjà possédée du même type** ; améliorations : niveau 2 = 80, niveau 3 = 150. Les réductions se multiplient, puis on arrondit.
- Glace de base :
  - ralentit (facteur de vitesse 0,45, valeur actuelle) ;
  - 1,5 s passées dans au moins une zone donnent un gel de 1 s ;
  - 3 s d'attente avant de pouvoir regeler, comptées à la fin du gel et partagées avec le gel du maître de l'eau ;
  - ennemi gelé : +25 % de dégâts de toutes les sources, quel que soit le gel. Ce bonus se multiplie avec Combustion, et « Gel mordant » le porte à +50 %.
- Réserve vide en début de partie. La fin de vague (arrivée du cristal) renvoie les tours posées dans la réserve, et chaque tour garde ses améliorations à vie.
- Les combos existants de `procs.json` restent tels quels. Les branches utilisent les états `burning`, `frozen`, `wet` et `slowed`.
- Les réactions en chaîne sont permises, avec un plafond par image. Le gel des éclats respecte le temps d'attente avant de regeler.
- Données JSON validées (null + `push_error` nommant le fichier et la clé) ; interface en code ; pas d'autoload ; aucun `uid=`/`.uid`/`.import` ; `##` et typage statique.

## Décisions prises pour ce plan

- **`assets/data/towers.json`**, à ajouter à l'existant :
  ```json
  "reserve": { "price_step": 25, "upgrade_costs": [80, 150] },
  "freeze": { "dwell": 1.5, "duration": 1.0, "cooldown": 3.0, "frozen_vulnerability": 0.25 },
  "chain": { "max_per_frame": 12 },
  "branches": {
    "cannon": {
      "incendiaire": { "label": "Incendiaire", "burn_duration": 4.0, "burn_dps": 8.0, "card_duration_mult": 1.5,
                       "l3_explosion_radius": 80.0, "l3_explosion_damage": 15.0 },
      "perforant": { "label": "Perforant", "pierce_total": 3, "l3_shots": 2, "l3_spread_degrees": 8.0 } },
    "frost": {
      "blizzard": { "label": "Blizzard", "range_mult": 1.4, "dwell": 1.0, "l3_wet_duration": 3.0 },
      "eclats": { "label": "Éclats", "shard_radius": 70.0, "shard_damage": 12.0, "l3_shard_freeze": 0.6 } } }
  ```
- **Nouvelles cartes** (`cards.json`), avec leurs nouveaux types d'effet :

  | id | rareté | effet | type d'effet |
  |---|---|---|---|
  | `tour_de_renfort` | rare, illimitée | une tour de base gratuite, du type le moins possédé (canon en cas d'égalité) ; ne fait pas monter le prix des suivantes | `free_tower` |
  | `ingenieur_chevronne` | peu commune, ×1 | améliorations ×0,75 | `upgrade_cost_mult` 0.75 |
  | `surcharge` | rare, ×1 | les tours de niveau 3 qui tirent (canon) tirent 20 % plus vite | `tier3_fire_rate_bonus` 0.2 |
  | `gel_mordant` | peu commune, ×1 | +25 % de vulnérabilité supplémentaire des ennemis gelés | `frozen_vulnerability_bonus` 0.25 |

- **Incendiaire + carte « Munitions incendiaires »** : les canons Incendiaire gardent leur propre brûlure, et la durée est multipliée par `card_duration_mult` si la carte est possédée. Les canons sans branche gardent la brûlure de la carte, comme aujourd'hui.
- **Éclats et Incendiaire niveau 3 :**
  - l'ennemi retient l'id de la dernière tour qui l'a gelé et du dernier canon dont les obus l'ont brûlé ;
  - à sa mort, si cette tour a la branche voulue, l'effet se déclenche une fois ;
  - les explosions et éclats passent par le `ChainLimiter`.

## Review Focus

1. **Acheter avec une réserve déjà pleine, puis reprendre et reposer** : le prix ne monte qu'à l'achat, poser depuis la réserve est gratuit, et une tour reprise garde son niveau et sa branche. → Task 1 (`tower_reserve_check`).
2. **Chaîne d'explosions sur 40 ennemis brûlants** : le jeu ne fige pas ; au plus `max_per_frame` effets par image, les suivants sont reportés ou abandonnés sans planter. → Task 3 (`chain_limiter_check`).
3. **Ennemi trempé dans la zone d'une glace avec le maître de l'eau** : un seul gel à la fois, un seul temps d'attente avant de regeler, pas de gel en boucle. → Task 2 (`chill_rules_check`).
4. **Fin de vague pendant qu'un panneau d'amélioration est ouvert ou qu'une tour est sélectionnée** : le panneau se ferme, et toutes les tours reviennent dans la réserve. → Task 4.
5. **Pas assez d'or pour une amélioration** : bouton grisé, rien n'est dépensé. → Task 1 (`try_upgrade` refusé) et Task 4.

## Vérification

Godot indisponible : les contrôles `tests/unit/towers/*_check.gd` sont écrits et relus, puis l'utilisateur les lance et joue (V-1…V-8, fin de Task 5). Captures dans `production/qa/evidence/tours-t1/`.

---

### Task 1: Réserve et améliorations (logique pure)

**Files:**
- Create : `src/towers/tower_record.gd`, `src/towers/tower_reserve.gd`, `tests/unit/towers/tower_reserve_check.gd`.
- Modify :
  - `assets/data/towers.json` (blocs `reserve`, `freeze`, `chain`, `branches`) ;
  - `src/towers/tower_stats.gd` (lecture et validation des nouveaux blocs).

**Interfaces:**
- Produces:
  - `class_name TowerRecord extends RefCounted` : `id: int`, `kind: TowerStats.Kind`, `level: int` (1 à 3), `branch: StringName` (`&""` avant le niveau 2), `placed: bool`, `free: bool` (gratuite : ne compte pas dans le prix).
  - `TowerStats` gagne :
    - les champs `price_step: int`, `upgrade_costs: Array[int]`, `freeze_dwell: float`, `freeze_duration: float`, `freeze_cooldown: float`, `frozen_vulnerability: float`, `chain_max_per_frame: int` ;
    - `branches: Dictionary`, de la forme kind → { branch id → Dictionary de valeurs } ;
    - `func branch_ids(kind) -> Array[StringName]`, `func branch_value(kind, branch: StringName, key: String) -> Variant`.
  - `class_name TowerReserve extends RefCounted` :
    - `func _init(stats: TowerStats)` ;
    - `func price_of_next(kind, cost_factor: float) -> int` : `roundi((base + price_step × achetées_payantes_de_ce_type) × cost_factor)` ;
    - `func buy(kind, gold_available: int, cost_factor: float) -> TowerRecord` : null si l'or ne suffit pas ; l'appelant dépense `price_of_next` calculé avant l'achat ;
    - `func add_free(kind) -> TowerRecord` ;
    - `func least_owned_kind() -> TowerStats.Kind` ;
    - `func upgrade_cost(record, cost_factor: float) -> int` : -1 au niveau 3 ;
    - `func try_upgrade(record, branch: StringName, gold_available: int, cost_factor: float) -> int` : le prix payé, ou -1 si refusé ; le niveau 1 vers 2 exige une branche valide, le 2 vers 3 garde la branche ;
    - `func records() -> Array[TowerRecord]` ; `func available() -> Array[TowerRecord]` (non posées) ;
    - `func mark_placed(record)`, `func mark_returned(record)`, `func return_all()` ;
    - `signal changed`.

- [ ] **Step 1: Write `tower_reserve_check.gd`** (avec le vrai `towers.json`) :
  - prix successifs d'un canon : 50, 75, 100 ; ceux de la glace sont indépendants (50) ;
  - avec `cost_factor` 0.8 : 40, 60, 80 ;
  - `add_free` ne fait pas monter le prix ;
  - `least_owned_kind` vaut CANNON à égalité ;
  - `buy` avec trop peu d'or renvoie null ;
  - `try_upgrade` :
    - sans branche au niveau 1 → -1 ;
    - avec `&"incendiaire"` → 80, niveau 2 ;
    - puis → 150, niveau 3 et même branche ;
    - au niveau 3 → -1 ;
    - avec une branche d'un autre type → -1 ;
  - avec `cost_factor` 0.6, l'amélioration coûte 48 ;
  - `mark_placed` retire la tour de `available()`, et `return_all` remet tout ;
  - une tour reprise garde son niveau et sa branche ;
  - `TowerStats` refuse un `towers.json` sans `reserve.price_step`, ou dont une branche n'a pas de `label`.

  Le contrôle affiche `TOWER_RESERVE OK` ou `TOWER_RESERVE FAIL: <raison>`, et appelle `quit(1)` en cas d'échec.
- [ ] **Step 2: Run, expect FAIL** — `godot --headless -s res://tests/unit/towers/tower_reserve_check.gd`.
- [ ] **Step 3: Implement** le JSON, `TowerStats`, `TowerRecord` et `TowerReserve`.
- [ ] **Step 4: Run, expect `TOWER_RESERVE OK`** (le contrôle existant `modifiers_check` doit toujours passer).
- [ ] **Step 5: Commit** `feat: réserve de tours et améliorations`.

### Task 2: Gel des tours et vulnérabilité des ennemis gelés

**Files:**
- Create: `src/enemies/chill_rules.gd`, `tests/unit/towers/chill_rules_check.gd`
- Modify: `src/enemies/enemy.gd`, `src/cards/player_modifiers.gd` (effet `frozen_vulnerability_bonus`)

**Interfaces:**
- Consumes: `TowerStats.freeze_*` (Task 1).
- Produces:
  - `class_name ChillRules extends RefCounted` (logique pure tenue par chaque ennemi) :
    - `func tick(delta: float, chilled_this_frame: bool, dwell_needed: float) -> bool` : vrai quand le temps passé dans une zone atteint le seuil (remis à 0 si l'ennemi sort de toutes les zones) ;
    - `func can_freeze(frozen: bool, cooldown_left: float) -> bool`.
  - `Enemy.apply_chill(dwell_needed: float, duration: float, cooldown: float, tower_id: int) -> void` : appelé chaque image par une glace en portée ; plusieurs glaces ne s'additionnent pas ; le plus petit `dwell_needed` demandé dans l'image l'emporte (cas du Blizzard).
  - `Enemy.freeze_from(duration: float, cooldown: float, tower_id: int) -> bool` : respecte le gel en cours et le temps d'attente, ce qui sert aux éclats du niveau 3.
  - `Enemy.last_freezer_id() -> int`, `Enemy.last_burner_id() -> int` (−1 si aucun) ; `Enemy.apply_burn(duration, dps, burner_id: int = -1)`.
  - Vulnérabilité dans `Enemy._damage` : ×(1 + `frozen_vulnerability` + bonus de cartes) si l'ennemi est gelé, multipliée avec Combustion. Ce bonus est lu dans `PlayerModifiers.frozen_vulnerability_bonus()`, et la valeur de base vient des réglages de tour transmis à l'ennemi.

- [ ] **Step 1: Write `chill_rules_check.gd`** :
  - 1,4 s dans une zone → pas de gel, puis 0,1 s de plus → gel ;
  - sortie de zone à 1,0 s → le compteur repart à 0 ;
  - `dwell` 1.0 (Blizzard) gèle à 1,0 s ;
  - `can_freeze` est faux pendant un gel et pendant le temps d'attente, vrai ensuite ;
  - la vulnérabilité calculée vaut ×1.25, puis ×1.5 avec le bonus de 0.25, et ×1.25 × (1 + Combustion) avec Combustion.

  Le calcul est exposé par `static func damage_factor(frozen: bool, base: float, bonus: float) -> float` dans `ChillRules`.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement** `ChillRules`, puis les ajouts dans `Enemy` et `PlayerModifiers`.

  Le gel du maître de l'eau (`try_freeze`) et `force_freeze` partagent le même temps d'attente. `force_freeze` garde son comportement actuel : il sert au Zéro absolu et au Raz-de-marée.
- [ ] **Step 4: Run, expect `CHILL_RULES OK`.**
- [ ] **Step 5: Commit** `feat: gel des tours et vulnérabilité des ennemis gelés`.

### Task 3: Branches des tours et effets en chaîne

**Files:**
- Create: `src/towers/chain_limiter.gd`, `tests/unit/towers/chain_limiter_check.gd`
- Modify: `src/towers/cannon_tower.gd`, `src/towers/frost_tower.gd`, `src/hero/hero_bullet.gd` (pierce et brûleur), `src/waves/wave_spawner.gd` (morts : déclencher Éclats et Incendiaire niveau 3)

**Interfaces:**
- Consumes: `TowerRecord`, `TowerStats.branch_value` (Task 1) ; `Enemy.apply_chill/freeze_from/last_*_id/apply_burn(…, burner_id)` (Task 2).
- Produces:
  - `class_name ChainLimiter extends RefCounted` : `func _init(max_per_frame: int)`, `func try_consume(frame: int) -> bool`.
  - `CannonTower.setup(..., record: TowerRecord)` et `FrostTower.setup(..., record: TowerRecord)` : la tour lit son niveau et sa branche dans la fiche, à chaque tir ou à chaque image, si bien qu'une amélioration agit tout de suite.
  - `TowerEffects` (dans `wave_spawner.gd` ou un petit fichier `src/towers/tower_effects.gd`) : à la mort d'un ennemi, il retrouve la fiche de son dernier geleur ou brûleur (un dictionnaire id → `TowerRecord` donné par le placeur) et déclenche l'explosion (Incendiaire niveau 3 : dégâts de zone qui brûlent) ou les éclats (Éclats niveau 2 : dégâts de zone ; niveau 3 : plus `freeze_from`).

- [ ] **Step 1: Write `chain_limiter_check.gd`** : avec `max_per_frame` 12, 12 `try_consume(5)` renvoient vrai et le 13e faux ; à l'image 6, le compteur repart à zéro.
- [ ] **Step 2: Run, expect FAIL** ; **Step 3: implement** ; **Step 4: expect `CHAIN_LIMITER OK`.**
- [ ] **Step 5: Branches** — selon le §6 et les valeurs des Décisions.

  **Canon :**
  - Incendiaire au niveau 2 : la balle pose sa brûlure avec `burner_id`, et la durée est multipliée si la carte « Munitions incendiaires » est possédée.
  - Perforant au niveau 2 : la balle touche 3 ennemis au total.
  - Perforant au niveau 3 : 2 obus écartés de 8°.
  - « Surcharge » : cadence +20 % au niveau 3.

  **Glace :**
  - Glace de base : ralentit comme avant et appelle `apply_chill`.
  - Blizzard au niveau 2 : portée ×1,4 et temps de gel de 1,0 s.
  - Blizzard au niveau 3 : l'ennemi qu'elle gèle est aussi trempé 3 s.
  - Éclats : par la mort de l'ennemi (étape suivante).

  **Morts :** Incendiaire niveau 3 et Éclats passent par `ChainLimiter`, et l'explosion est visible (`PopBurst` existant, petit).

  **Chaîne :** une explosion qui tue un ennemi brûlant de la même branche peut en déclencher une autre.
- [ ] **Step 6: Commit** `feat: branches des tours et effets en chaîne`.

### Task 4: Placement depuis la réserve, achat et panneau d'amélioration

**Files:**
- Create: `src/ui/tower_reserve_bar.gd`, `src/ui/tower_upgrade_panel.gd`
- Modify: `src/towers/tower_placer.gd`, `src/ui/crystal_hud.gd` (boutons d'achat), `src/game/main.gd` (création de la réserve, fin de vague → `return_all`)

**Interfaces:**
- Consumes: Tasks 1 à 3.
- Produces:
  - **`TowerPlacer`** :
    - `select_record(record: TowerRecord)` pour poser une tour de la réserve gratuitement ;
    - `select_purchase(kind)` pour acheter, puis poser au clic, au prix `price_of_next` × `tower_cost_factor` ;
    - un clic sur une tour posée émet `signal tower_clicked(record: TowerRecord, screen_position: Vector2)` ;
    - `func pick_up(record)` ;
    - `func return_all_towers()` remplace `clear_towers()`.
  - **`TowerReserveBar`** (Control) : une icône par tour non posée (type, niveau, lettre de branche) ; un clic appelle `select_record`.
  - **`TowerUpgradePanel`** (Control) : il affiche le niveau, la branche, l'amélioration suivante et son prix, avec deux boutons de branche au niveau 1, un bouton « Niveau 3 » au niveau 2 et un bouton « Reprendre ». Le bouton est grisé si l'or manque. Signaux : `upgrade_requested(record, branch)`, `pick_up_requested(record)`, `closed`.
  - **`PlayerModifiers`** gagne `func tower_cost_factor() -> float` (Plans d'ingénieur) et `func upgrade_cost_factor() -> float` (Plans × Ingénieur chevronné).

- [ ] **Step 1: Placeur** — Il reste en BUILD seulement. Le clic sur une tour posée est testé avant le test d'emplacement valide. Il garde un dictionnaire id → `TowerRecord` des tours posées, pour Task 3.
- [ ] **Step 2: Boutons et barre** :
  - Les boutons de type deviennent « Acheter canon — N » et « Acheter glace — N », avec le prix réel. Ils se rafraîchissent quand l'or, la réserve ou les modificateurs changent.
  - La barre de réserve se place juste au-dessus des boutons, dans la bande du bas de la construction. **La hauteur de cette bande, `CrystalHud.build_bottom_band_height()`, doit l'inclure**, pour que la caméra garde le terrain au-dessus.
- [ ] **Step 3: Panneau** :
  - Il s'ouvre près de la tour cliquée et se ferme au lancement de la vague, à la fin de la vague ou par Échap.
  - Une amélioration dépense l'or, puis appelle `try_upgrade`.
  - « Reprendre » appelle `pick_up`.
- [ ] **Step 4: Fin de vague** — `main` appelle `return_all_towers()` là où il appelait `clear_towers()`. Vérifier par la lecture le point 4 du Review Focus.
- [ ] **Step 5: Commit** `feat: placement depuis la réserve et panneau d'amélioration`.

### Task 5: Cartes des tours

**Files:**
- Modify: `assets/data/cards.json`, `src/cards/card_catalog.gd` (nouveaux types d'effet), `src/cards/player_modifiers.gd`, `src/game/main.gd` (`free_tower` → `reserve.add_free(reserve.least_owned_kind())`), `tests/unit/cards/modifiers_check.gd`

**Interfaces:**
- Consumes: `TowerReserve.add_free/least_owned_kind` (Task 1), `PlayerModifiers.upgrade_cost_factor` (Task 4), `frozen_vulnerability_bonus` (Task 2).
- Produces: `PlayerModifiers.tier3_fire_rate_factor() -> float` ; `signal free_tower_requested`.

- [ ] **Step 1: Extend `modifiers_check.gd`** :
  - après `ingenieur_chevronne`, `upgrade_cost_factor()` vaut 0.75, et 0.6 avec Plans d'ingénieur ;
  - après `surcharge`, `tier3_fire_rate_factor()` vaut 1/1.2 sur l'intervalle de tir ;
  - après `gel_mordant`, `frozen_vulnerability_bonus()` vaut 0.25 ;
  - `tour_de_renfort` émet `free_tower_requested`, autant de fois qu'elle est prise.
- [ ] **Step 2: Run, expect FAIL** ; **Step 3: implement** les 4 cartes du tableau des Décisions, communes à toutes les spés ; **Step 4: expect `MODIFIERS OK`.**
- [ ] **Step 5: Commit** `feat: cartes des tours`.
- [ ] **Step 6: Playtest de l'utilisateur** (captures dans `production/qa/evidence/tours-t1/`) :
  - **V-1** acheter des tours, prix 50, 75, 100 ;
  - **V-2** à la vague suivante, les tours sont dans la réserve et se posent gratuitement ;
  - **V-3** reprendre une tour, puis la reposer ;
  - **V-4** améliorer une tour : choix de branche, puis niveau 3 ;
  - **V-5** la glace gèle, et les ennemis gelés prennent plus de dégâts (chiffres) ;
  - **V-6** les explosions d'un canon Incendiaire niveau 3 se suivent en chaîne sans que le jeu rame ;
  - **V-7** les éclats de la glace ;
  - **V-8** les 4 nouvelles cartes.
