# Étape 5a — Carte du monde : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mondes de 8 vagues avec une carte à chemins générée au hasard ; entre les vagues, un lieu bonus (magasin, trésor, repos) ; 12 objets passifs.

**Architecture:** Les objets sont des données (`items.json`) lues par un `ItemCatalog` ; leurs effets utilisent le même format que les cartes et passent par `PlayerModifiers` (source unique de stats), qui gagne `take_item`. La carte est une logique pure : `WorldMapGenerator` produit un `WorldMap` (colonnes de lieux reliés) à partir d'une graine ; `WorldRun` suit le monde en cours et la position du joueur. `GameState` gagne deux phases (`MAP`, `PLACE`) entre le choix de carte et la construction ; les écrans (carte, magasin, trésor, repos) sont construits en code et n'émettent que des signaux, `main.gd` les relie.

**Tech Stack:** Godot 4.7.2 / GDScript typé ; JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-20-etape-5a-carte-du-monde-design.md`

## Global Constraints

- Données JSON validées (null + `push_error` nommant le fichier et la clé), interface en code, pas d'autoload, pas de `uid=`/`.uid`/`.import` écrits par les agents ; `##` et typage statique partout.
- Toutes les valeurs de la spec (§6.2, §7, §8, §8bis) **exactement**, en données.
- Vagues, cartes, ennemis, compétences et défaite gardent leurs règles ; le numéro de vague continue d'un monde à l'autre (spec §5, §10).
- Style néon des écrans existants (`CardChoiceScreen`, `NeonFonts`, couleurs de rareté de `card_rarities.json`).
- Les effets « +X % » des objets suivent la convention des cartes existantes qui utilisent le même type d'effet (vérifier dans `cards.json` qu'un `value` de 0.1 veut bien dire +10 % pour ce type).

## Décisions prises pour ce plan

- `assets/data/waves.json` gagne `"world": { "waves_per_world": 8, "final_count_mult": 1.5 }`. Vague finale = `wave % waves_per_world == 0`. Monde d'une vague = `(wave - 1) / 8 + 1`, rang dans le monde = `(wave - 1) % 8 + 1`.
- `assets/data/enemy_types.json` : chaque type gagne `"display_name"` (« gobelin », « kamikaze », « artilleur ») et `"display_plural"` (« gobelins », « kamikazes », « artilleurs »).
- `assets/data/world_map.json` :
  ```json
  { "columns": 7, "min_nodes": 2, "max_nodes": 3,
    "weights": { "shop": 40, "treasure": 30, "rest": 30 },
    "min_shops_per_path": 2, "max_same_in_a_row": 2, "max_tries": 50 }
  ```
- `assets/data/items.json` :
  ```json
  { "prices": { "common": 60, "uncommon": 100, "rare": 150, "epic": 220, "legendary": 300 },
    "shop": { "slots": 4, "crystal_repair_cost": 40, "crystal_repair_hp": 20 },
    "treasure": { "slots": 3, "fallback_gold": 100 },
    "rest": { "hero_heal_fraction": 0.3, "crystal_heal": 20 },
    "items": [ { "id", "category": "attack|survival|utility", "rarity", "display_name", "description", "glyph": "1-2 lettres", "requires_spec": "", "effects": [ … ] } ] }
  ```
  Effets des 12 objets (types existants sauf ceux marqués *nouveau*) :
  | id | effet |
  |---|---|
  | `lunette` (`requires_spec: "archer"`) | `crit_chance_bonus` 0.05 |
  | `gachette` | `weapon_fire_rate_bonus` 0.10 |
  | `poudre_noire` | `hero_damage_bonus` 0.15 |
  | `oeil_de_faucon` | `tower_range_bonus` 0.20 *(nouveau)* |
  | `coeur_de_neon` | `hero_max_hp_bonus` 20 |
  | `pansement_dore` | `hero_heal_per_wave` 10 *(nouveau)* |
  | `bouclier_cristal` | `crystal_damage_reduction` 0.15 *(nouveau)* |
  | `seconde_chance` | `second_chance` `{ "hp_fraction": 0.3 }` *(nouveau, drapeau)* |
  | `bottes` | `move_speed_bonus` 0.10 |
  | `aimant` | `pickup_radius_mult` 1.3 |
  | `plans_ingenieur` | `tower_cost_mult` 0.8 *(nouveau)* |
  | `bourse_percee` | `gold_per_kill_mult` 1.2 *(nouveau)* |
- Icônes : cercle néon de la couleur de la catégorie (attaque rouge-rose, survie vert, utilité cyan) avec le `glyph` au centre ; icônes de lieux = formes néon dessinées en code (magasin, trésor, repos), une couleur par type.
- Seconde chance : `HeroHealth` reçoit un sauvetage armé une fois ; à 0 PV il remet `max_hp × 0.3`, arme l'invincibilité habituelle, émet `rescued` au lieu de `died`.
- Ordre de début de partie : spécialisation → choix « Départ en trombe » s'il existe → carte en consultation → construction de la vague 1.

## Review Focus

1. **Plus rien à vendre / à offrir** (tous les objets possédés, ou spé sans objet restant) : le magasin montre moins d'objets (ou seulement la réparation), le trésor donne 100 d'or ; rien ne plante. → Task 5 (`item_pool_check`).
2. **Pas assez d'or** au magasin ou réparation avec le cristal plein : bouton grisé, rien n'est dépensé, rien ne dépasse le max. → Task 5.
3. **Monde 2 et suivants** : nouvelle carte, position remise au départ, « Monde 2 — Vague 1/8 » à la vague 9, vague finale à 16. → Task 3 (`world_run_check`) et Task 4.
4. **Seconde chance quand un coup ferait passer bien sous 0, ou deux coups dans la même image** : un seul sauvetage, puis la mort normale au coup suivant après l'invincibilité. → Task 2 (`hero_health_check`).
5. **Générateur sur des centaines de graines** : toujours une carte valide, et identique pour une même graine. → Task 3 (`world_map_check`).

## Vérification

Godot indisponible : contrôles de logique `tests/unit/**/…_check.gd` (extends SceneTree, `quit(1)` en cas d'échec) lancés par l'utilisateur, relectures `godot-gdscript-specialist`, puis partie de l'utilisateur (V-1…V-8, fin de Task 6) avec captures dans `production/qa/evidence/story-021-carte-du-monde/`.

---

### Task 1: Objets en données et dans les modificateurs

**Files:**
- Create: `assets/data/items.json`, `src/items/item_def.gd`, `src/items/item_catalog.gd`, `tests/unit/items/item_catalog_check.gd`
- Modify: `src/cards/player_modifiers.gd`, `src/cards/card_catalog.gd` (types d'effets nouveaux dans `EFFECT_NUMBER_KEYS` ; `second_chance` → clé `hp_fraction`, et dans `FLAG_EFFECTS`), `tests/unit/cards/modifiers_check.gd`

**Interfaces:**
- Produces:
  - `class_name ItemDef extends RefCounted` : `id: String`, `category: StringName`, `rarity: StringName`, `display_name: String`, `description: String`, `glyph: String`, `requires_spec: String`, `effects: Array[Dictionary]`.
  - `class_name ItemCatalog extends RefCounted` : `static func load_from_file(path: String, rarities: CardRarities, specs: SpecializationCatalog, rules: ProcRules, abilities: AbilityCatalog) -> ItemCatalog` (valide chaque objet et chaque effet avec `CardCatalog._is_effect_valid`) ; `func all() -> Array[ItemDef]` ; `func get_item(id: String) -> ItemDef` ; `func price_of(item: ItemDef) -> int` ; `var shop_slots: int`, `crystal_repair_cost: int`, `crystal_repair_hp: float`, `treasure_slots: int`, `treasure_fallback_gold: int`, `rest_hero_heal_fraction: float`, `rest_crystal_heal: float`.
  - `PlayerModifiers` : `signal items_changed` ; `func take_item(item: ItemDef) -> void` (ignoré si déjà possédé ; applique les effets par le même code que `take`, extrait dans `_apply_effect(effect: Dictionary)` ; émet `items_changed` puis `changed`) ; `func owns_item(id: String) -> bool` ; `func owned_items() -> Array[ItemDef]` ; nouveaux lecteurs `tower_range_factor() -> float` (1 + somme), `tower_cost(base: int) -> int` (`roundi(base × produit des tower_cost_mult)`), `crystal_damage_factor() -> float` (1 − somme, jamais sous 0.1), `gold_per_kill(base: int) -> int` (`roundi(base × produit des gold_per_kill_mult)`), `hero_heal_per_wave() -> float`.

- [ ] **Step 1: Write `item_catalog_check.gd`** — charge le vrai `items.json` : 12 objets ; `price_of` de chaque rareté = 60/100/150/220/300 ; `lunette.requires_spec == "archer"` ; `shop_slots == 4`, `crystal_repair_cost == 40`, `treasure_fallback_gold == 100`, `rest_hero_heal_fraction == 0.3`. Un dictionnaire invalide (rareté inconnue, effet inconnu, `id` en double) donne `null`.
- [ ] **Step 2: Extend `modifiers_check.gd`** — `take_item(bourse)` puis `gold_per_kill(15) == 18` ; `take_item(plans)` puis `tower_cost(50) == 40` ; `take_item(oeil)` puis `tower_range_factor() == 1.2` ; `take_item(bouclier)` puis `crystal_damage_factor() == 0.85` ; second `take_item` du même objet ignoré ; `owns_item`, `has_flag(&"second_chance")`, `flag_value(&"second_chance", "hp_fraction") == 0.3` ; les cartes existantes donnent toujours les mêmes valeurs.
- [ ] **Step 3: Run both checks, expect FAIL** — `godot --headless -s res://tests/unit/items/item_catalog_check.gd` (l'utilisateur ; dans la session : relecture).
- [ ] **Step 4: Implement** `items.json`, `ItemDef`, `ItemCatalog`, l'extraction de `_apply_effect` et les nouveaux effets.
- [ ] **Step 5: Run both checks, expect `ITEM_CATALOG OK` / `MODIFIERS OK`.**
- [ ] **Step 6: Commit** `feat: objets passifs en données`.

### Task 2: Effets des objets dans le jeu

**Files:**
- Modify: `src/hero/hero_health.gd`, `src/hero/hero.gd`, `src/crystal/crystal.gd`, `src/towers/cannon_tower.gd`, `src/towers/frost_tower.gd`, `src/towers/tower_placer.gd`, `src/ui/crystal_hud.gd` (prix des boutons de tours), `src/ui/stats_panel.gd`, `src/game/wave_cycle.gd`, `src/game/main.gd`, `tests/unit/hero/hero_health_check.gd`

**Interfaces:**
- Consumes: lecteurs de `PlayerModifiers` (Task 1).
- Produces:
  - `HeroHealth` : `signal rescued` ; `func arm_rescue(hp_fraction: float) -> void` (une fois ; un second appel ne réarme pas un sauvetage déjà utilisé) ; `func has_rescue() -> bool`.
  - `Crystal.set_damage_factor(factor: float) -> void` (`take_damage` multiplie par ce facteur).
  - `Hero` : au signal `rescued`, flash, `PopBurst.spawn(…, "SECONDE CHANCE !", …)` et tremblement « grand ».

- [ ] **Step 1: Extend `hero_health_check.gd`** — sauvetage armé à 0.3 : un coup de 150 sur 100 PV laisse `current == 30`, émet `rescued`, pas `died`, héros invincible ; après `tick(0.5)`, un coup de 40 tue (`died` une fois) ; `arm_rescue` après usage ne réarme pas.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement** le sauvetage dans `take_hit` (avant de marquer la mort) ; `Hero` réagit à `rescued`.
- [ ] **Step 4: Wire the other effects** — portée : canon `cannon_range × tower_range_factor()`, glace `base × frost_range_factor() × tower_range_factor()`, cercle d'aperçu du placement idem ; coût : pose et libellés des boutons via `modifiers.tower_cost(stats.cost_of(kind))`, rafraîchis sur `changed` ; cristal : `main` appelle `set_damage_factor(modifiers.crystal_damage_factor())` sur `changed` ; or : `WaveCycle` dépose `modifiers.gold_per_kill(economy.gold_per_kill + modifiers.gold_per_kill_bonus())` ; Pansement : sur `wave_started`, `hero.health().heal(modifiers.hero_heal_per_wave())` ; Cœur de néon par le chemin existant `_apply_hero_survival` ; Seconde chance : sur `items_changed`, `arm_rescue(flag_value(&"second_chance", "hp_fraction"))` si le drapeau est présent.
- [ ] **Step 5: Stats panel** — lignes « Portée des tours », « Coût des tours », « Dégâts subis par le cristal », « Or par ennemi », « Soin par vague », « Seconde chance : prête / utilisée », affichées seulement quand elles diffèrent de la base.
- [ ] **Step 6: Run `hero_health_check`, expect `HERO_HEALTH OK`.**
- [ ] **Step 7: Commit** `feat: effets des objets dans le jeu`.

### Task 3: Génération de la carte et suivi du monde

**Files:**
- Create: `assets/data/world_map.json`, `src/world/world_map.gd`, `src/world/world_map_generator.gd`, `src/world/world_run.gd`, `tests/unit/world/world_map_check.gd`, `tests/unit/world/world_run_check.gd`
- Modify: `assets/data/waves.json`, `src/waves/wave_curve.gd` (lit `world`)

**Interfaces:**
- Produces:
  - `class_name WorldMap extends RefCounted` : `const SHOP := &"shop"`, `TREASURE := &"treasure"`, `REST := &"rest"` ; `var columns: Array` (chaque colonne = `Array[Dictionary]` de `{ "type": StringName, "links": PackedInt32Array }`, liens vers les index de la colonne suivante ; la dernière colonne a des liens vides = drapeau) ; `func paths() -> Array[PackedInt32Array]` (tous les chemins départ → drapeau, un index par colonne).
  - `class_name WorldMapGenerator extends RefCounted` : `static func load_from_file(path: String) -> WorldMapGenerator` ; `func generate(rng: RandomNumberGenerator) -> WorldMap` ; `func is_valid(map: WorldMap) -> bool` ; `func fallback() -> WorldMap`.
  - `class_name WorldRun extends RefCounted` : `func _init(waves_per_world: int)` ; `var world: int` (1 au départ) ; `var map: WorldMap` ; `var column: int` (−1 = départ) ; `var node: int` ; `func start_world(new_map: WorldMap) -> void` (remet au départ) ; `func reachable() -> PackedInt32Array` (départ → toute la colonne 0) ; `func move_to(index: int) -> bool` (refuse un lieu non atteignable) ; `func world_of(wave: int) -> int` ; `func wave_in_world(wave: int) -> int` ; `func is_final_wave(wave: int) -> bool`.
  - `WaveCurve` : `var waves_per_world: int`, `var final_count_mult: float`.

- [ ] **Step 1: Write `world_map_check.gd`** — pour les graines 1 à 500 : 7 colonnes de 2 ou 3 lieux ; chaque lieu sauf la dernière colonne a 1 ou 2 liens, chaque lieu des colonnes 1–6 a au moins un lien entrant ; aucun croisement (pour `a < a'` dans une colonne, tout lien de `a` ≤ tout lien de `a'`) ; deux lieux reliés au même lieu précédent ont des types différents ; chaque chemin a ≥ 2 magasins et jamais 3 types identiques de suite ; même graine = même carte ; `fallback()` passe `is_valid`.
- [ ] **Step 2: Write `world_run_check.gd`** — `wave_in_world(9) == 1`, `world_of(9) == 2`, `is_final_wave(8)` et `(16)`, pas `(7)` ; `reachable()` au départ = toute la colonne 0 ; `move_to` d'un lieu non relié refusé ; `start_world` remet `column == -1`.
- [ ] **Step 3: Run, expect FAIL.**
- [ ] **Step 4: Implement** — génération en trois temps (spec §8bis) :
  1. tailles des colonnes ;
  2. liens par intervalles contigus et croissants (chaque lieu vise un intervalle de 1 ou 2 lieux consécutifs ; l'intervalle du suivant commence au plus tôt à la fin du précédent ; tous les lieux de la colonne suivante sont couverts) ;
  3. types tirés avec les poids, sans doublon entre frères ; puis `is_valid` (minimum de magasins et plus longue suite identique, par programmation dynamique sur les colonnes ou par `paths()`) ; nouveau tirage jusqu'à `max_tries`, sinon `fallback()` (carte fixe valide écrite à la main dans le code).
- [ ] **Step 5: Run, expect `WORLD_MAP OK` / `WORLD_RUN OK`.**
- [ ] **Step 6: Commit** `feat: génération de la carte du monde`.

### Task 4: Vague finale et aperçu par type

**Files:**
- Modify: `assets/data/enemy_types.json`, `src/enemies/enemy_types.gd`, `src/waves/wave_spawner.gd`, `src/game/wave_cycle.gd`, `src/ui/crystal_hud.gd`, `src/game/main.gd`, `tests/unit/enemies/enemy_types_check.gd`

**Interfaces:**
- Consumes: `WaveCurve.waves_per_world`, `final_count_mult` (Task 3).
- Produces:
  - `EnemyTypes.composition(wave: int, base_count: int, count_mult: float) -> Dictionary` (id → nombre > 0, dans l'ordre des types, chaque nombre `roundi(count_for × count_mult)`) ; `EnemyTypes.preview_text(composition: Dictionary) -> String` (« 15 gobelins, 7 kamikazes, 1 artilleur »).
  - `WaveSpawner.composition_for(wave: int) -> Dictionary` (×1.5 si vague finale) ; `_compose_wave` s'en sert.
  - `WaveCycle.wave_prepared(wave_number: int, composition: Dictionary, path: CrystalPath)` (remplace `enemy_count`).
  - `CrystalHUD.show_wave_preview(wave_number: int, composition: Dictionary)` ; `CrystalHUD.show_banner(text: String) -> void` (grand texte néon centré, ~1,5 s) ; libellé « Monde X — Vague Y/8 ».

- [ ] **Step 1: Extend `enemy_types_check.gd`** — `composition(5, 18, 1.0)` = gobelins 18, kamikazes 3, artilleurs 1 ; `composition(8, 27, 1.5)` = chaque nombre de `count_for` × 1.5 arrondi ; `composition(1, 6, 1.0)` ne contient que les gobelins ; `preview_text` accorde singulier et pluriel.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement**, puis brancher : aperçu de la construction avec tous les types ; bandeau « VAGUE FINALE ! » quand une vague finale est préparée ; affichage « Monde X — Vague Y/8 » (`main` crée ici le `WorldRun` de la partie et le passe au HUD ; Task 6 le réutilise).
- [ ] **Step 4: Run, expect `ENEMY_TYPES OK`.**
- [ ] **Step 5: Commit** `feat: vague finale et aperçu des ennemis par type`.

### Task 5: Magasin, trésor, repos

**Files:**
- Create: `src/items/item_pool.gd`, `src/world/shop_screen.gd`, `src/world/treasure_screen.gd`, `src/world/rest_screen.gd`, `src/ui/item_bar.gd`, `tests/unit/items/item_pool_check.gd`

**Interfaces:**
- Consumes: `ItemCatalog`, `ItemDef`, `PlayerModifiers.owns_item/take_item/owned_items` (Task 1) ; `CardRarities.weight/color/label`.
- Produces:
  - `class_name ItemPool extends RefCounted` : `func _init(catalog: ItemCatalog, modifiers: PlayerModifiers, rng: RandomNumberGenerator, spec_id: String, rarities: CardRarities)` ; `func draw(count: int, wave: int) -> Array[ItemDef]` (sans doublon, sans objet possédé, sans objet d'une autre spé ; rareté tirée comme `CardPool._roll_rarity` parmi les raretés encore disponibles ; moins d'objets s'il n'en reste pas assez).
  - `ShopScreen` (CanvasLayer, en pause = `PROCESS_MODE_ALWAYS` comme `CardChoiceScreen`) : `func open(items: Array[ItemDef], catalog: ItemCatalog, gold: int, crystal_full: bool) -> void` ; `func refresh(gold: int, crystal_full: bool) -> void` ; `signal item_bought(item: ItemDef)` ; `signal repair_requested` ; `signal left`.
  - `TreasureScreen` : `func open(items: Array[ItemDef]) -> void` ; `signal item_chosen(item: ItemDef)`.
  - `RestScreen` : `func open(hero_heal: float, crystal_heal: float) -> void` (montre les valeurs réelles) ; `signal hero_chosen` ; `signal crystal_chosen`.
  - `ItemBar` (Control) : `func setup(modifiers: PlayerModifiers, health: HeroHealth) -> void` — rangée d'icônes, infobulle nom + effet, Seconde chance éteinte après `rescued`.

- [ ] **Step 1: Write `item_pool_check.gd`** — avec un `ItemCatalog` construit en mémoire : `draw(4, 1)` donne 4 objets distincts ; un objet possédé n'apparaît jamais (200 tirages) ; un objet `requires_spec: "archer"` n'apparaît pas pour une autre spé ; s'il reste 2 objets, `draw(4, 1)` en donne 2 ; s'il n'en reste aucun, tableau vide.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement `ItemPool`, run, expect `ITEM_POOL OK`.**
- [ ] **Step 4: Implement the three screens and `ItemBar`** — style des cartes (cadre couleur de rareté, catégorie, prix) ; objet trop cher ou réparation impossible (or insuffisant ou cristal plein) = bouton grisé ; un objet acheté disparaît de l'étal ; « Partir » ferme le magasin ; le trésor impose un choix.
- [ ] **Step 5: Commit** `feat: magasin, trésor et repos`.

### Task 6: Écran de carte et enchaînement d'une partie

**Files:**
- Create: `src/world/world_map_screen.gd`
- Modify: `src/game/game_state.gd`, `src/game/main.gd`, `src/ui/crystal_hud.gd`

**Interfaces:**
- Consumes: Tasks 1–5.
- Produces:
  - `GameState.Phase` gagne `MAP` et `PLACE` ; `begin_map()`, `begin_place()`.
  - `WorldMapScreen` (CanvasLayer, `PROCESS_MODE_ALWAYS`) : `func open(run: WorldRun, preview_text: String, choosing: bool) -> void` (`choosing == false` = consultation avec le bouton « C'est parti ! ») ; `signal place_chosen(index: int)` ; `signal closed`.

- [ ] **Step 1: Map screen** — gauche → droite : départ, 7 colonnes, drapeau « VAGUE FINALE » ; traits entre lieux reliés ; icônes néon par type ; lieu actuel marqué ; lieux atteignables qui clignotent (seulement si `choosing`) ; chemin parcouru en surbrillance ; lieux inaccessibles assombris ; infobulle au survol ; aperçu de la prochaine vague dans un coin ; titre « Monde X ».
- [ ] **Step 2: Flow in `main.gd`** — `_end_card_choice()` :
  - `waves_completed == 0` → carte en consultation, puis construction ;
  - vague finale terminée → `world += 1`, nouvelle carte (`generate` avec le `_rng` de la partie), bandeau « MONDE N », carte en consultation, puis construction ;
  - sinon → `begin_map()`, carte en mode choix ; `place_chosen` → `run.move_to`, `begin_place()`, ouverture du lieu ;
  - à la fin du lieu (`left`, `item_chosen`, `hero_chosen` ou `crystal_chosen`) → `begin_build()`.

  Effets des lieux :
  - achat : `spend_gold(price)` puis `take_item` ;
  - réparation : `spend_gold(40)` puis `crystal.heal(20)` ;
  - repos héros : `heal(max_hp × 0.3)` ;
  - repos cristal : `crystal.heal(20)` ;
  - trésor vide : `add_gold(100)` et bandeau « +100 OR ».
- [ ] **Step 3: HUD** — libellés de phase « Carte du monde » et « Lieu » ; `ItemBar` sous la ligne des cartes ; panneau de stats caché pendant `MAP` et `PLACE` comme pendant le choix de carte.
- [ ] **Step 4: Self-check** — relire que chaque chemin mène toujours à `begin_build()` (y compris l'ouverture avec « Départ en trombe » et le passage au monde 2), qu'aucun écran ne reste ouvert, et que la défaite reste impossible hors combat.
- [ ] **Step 5: Commit** `feat: écran de carte et enchaînement des mondes`.
- [ ] **Step 6: Playtest de l'utilisateur** (captures dans `production/qa/evidence/story-021-carte-du-monde/`) :
  - **V-1** carte en consultation au début, puis vague 1 ;
  - **V-2** après la vague 1, choix d'un lieu relié seulement ;
  - **V-3** magasin : achat, objet grisé si trop cher, réparation ;
  - **V-4** trésor et repos ;
  - **V-5** effets visibles dans le panneau de stats et la rangée d'objets ;
  - **V-6** Seconde chance ;
  - **V-7** vague 8 « VAGUE FINALE ! » avec plus d'ennemis, puis « MONDE 2 » et nouvelle carte ;
  - **V-8** aperçu avec tous les types d'ennemis.
