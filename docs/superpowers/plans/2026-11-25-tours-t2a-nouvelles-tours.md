# Tours T2a — Quatre nouvelles tours : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un système de tours générique, quatre nouvelles tours (Tesla, Lance-flammes, Mortier, Amplificateur) avec branches, débloquées en partie par des cartes « Plans » ou le trésor.

**Architecture:** `towers.json` décrit chaque tour sous un identifiant texte. `TowerStats` donne une `TowerDef` par identifiant. Une seule classe de nœud `Tower` porte un **comportement** par type (`TowerBehaviour` et ses enfants), choisi par la clé `behaviour` des données. Réserve, placement, boutons, panneau, stats et effets de mort ne parlent plus qu'en identifiants. Les nouveaux états d'ennemi (étourdi, brûlure qui garde la plus forte) vivent dans `Enemy` avec une partie pure testable.

**Tech Stack:** Godot 4.7.2 / GDScript typé ; JSON dans `assets/data/` ; fabrique d'images `tools/sprite_baker/` (Node + Playwright, déjà utilisée).

**Spec:** `docs/superpowers/specs/2026-11-25-tours-t2a-nouvelles-tours-design.md` (§5 valeurs, §6 déblocage, §7 générique, §8bis toutes les règles tranchées).

## Global Constraints

- Canon et glace **identiques pour le joueur** après la migration (valeurs, branches, effets du T1).
- Toutes les valeurs du §5 et du §8bis **exactement**, en données ; clés requises par tour et par branche (null + `push_error` nommant le fichier et la clé).
- Prix : base de la tour, +25 par tour de ce type possédée ; améliorations 80 / 150.
- Amplificateur : **le plus fort par type de bonus**, séparément ; cadence = intervalle ÷ (1 + bonus) ; se multiplie avec Surcharge et Canon rapide.
- Cartes : « Balles lourdes » s'applique à toutes les tours qui blessent ; « Surcharge » aux tours qui tirent ; « Canon rapide » et « Munitions incendiaires » au canon seulement.
- Brûlure : on garde le DPS le plus fort et la durée la plus longue ; l'identifiant du canon brûleur n'est remplacé que par un canon.
- Interface en code ; pas d'autoload ; aucun `uid=`/`.uid`/`.import` ; `##` et typage statique ; le plafond d'effets en chaîne du T1 s'applique.

## Décisions prises pour ce plan

- `assets/data/towers.json` devient :
  ```json
  { "reserve": {...}, "freeze": {...}, "chain": {...}, "designation": {...},
    "towers": {
      "cannon":  { "label": "Canon", "behaviour": "shooter", "base_cost": 50, "range": 250.0, "radius": 18.0, "sheet": "res://assets/sprites/cannon", "height_px": 110.0, ...valeurs actuelles..., "branches": { ...actuelles... } },
      "frost":   { "label": "Glace", "behaviour": "frost_aura", ... },
      "tesla":   { "label": "Tesla", "behaviour": "chain_lightning", "base_cost": 70, "range": 220.0, "interval": 1.2, "damage": 12.0, "jumps": 3, "jump_range": 120.0, "wet_mult": 2.0,
                   "branches": { "surtension": { "label": "Surtension", "jumps": 6, "wet_mult": 3.0, "l3_jumps": 10 },
                                 "arc": { "label": "Arc", "range": 300.0, "stun": 0.3, "l3_stun": 0.6, "l3_damage_mult": 1.5 } } },
      "flamethrower": { "label": "Lance-flammes", "behaviour": "flame_cone", "base_cost": 60, "range": 140.0, "angle_degrees": 60.0, "dps": 4.0, "burn_dps": 6.0, "burn_duration": 2.0,
                   "branches": { "napalm": { "label": "Napalm", "burn_dps": 10.0, "burn_duration": 4.0, "l3_stack_max": 2.0 },
                                 "souffle": { "label": "Souffle", "angle_degrees": 100.0, "push_speed": 60.0, "l3_range": 200.0 } } },
      "mortar":  { "label": "Mortier", "behaviour": "mortar", "base_cost": 80, "min_range": 120.0, "range": 450.0, "interval": 3.0, "flight": 1.0, "damage": 25.0, "blast_radius": 90.0, "slowed_mult": 1.5,
                   "branches": { "grappe": { "label": "Grappe", "bomblets": 4, "l3_bomblets": 8, "bomblet_damage": 10.0, "bomblet_radius": 50.0 },
                                 "sismique": { "label": "Sismique", "crater_duration": 3.0, "crater_slow": 0.6, "l3_crater_duration": 5.0, "l3_crater_slow": 0.4, "crater_radius": 90.0 } } },
      "amplifier": { "label": "Amplificateur", "behaviour": "amplifier", "base_cost": 90, "range": 160.0, "damage_bonus": 0.25,
                   "branches": { "cadence": { "label": "Cadence", "rate_bonus": 0.3, "l3_rate_bonus": 0.5 },
                                 "catalyseur": { "label": "Catalyseur", "state_bonus": 0.5, "l3_state_bonus": 1.0 } } } },
    "starting_unlocked": ["cannon", "frost"] }
  ```
  (`crater_slow` est un facteur de vitesse : 0,6 = ralentit de 40 %, 0,4 = de 60 %.)
- Nouvelles cartes (`cards.json`), peu communes, ×1, communes à toutes les spés, `min_wave: 2`, effet `{ "type": "unlock_tower", "tower_id": "<id>" }` : `plans_tesla`, `plans_lance_flammes`, `plans_mortier`, `plans_amplificateur`. `CardDef` gagne `min_wave: int` (défaut 1) que `CardPool` respecte.
- `PlayerModifiers` tient l'ensemble des tours débloquées : `is_tower_unlocked(id)`, `unlocked_towers() -> Array[StringName]`, `unlock_tower(id)`, `signal towers_unlocked_changed`.
- Chiffres de dégâts : nouvelle source `&"tower_dot"` (cyan, regroupée) ; les coups des nouvelles tours passent `&"cannon"` (cyan, immédiat).
- Étourdi : `Enemy.stun(seconds)`, `has_state(&"stunned")` ; immobile, ne frappe pas, l'artilleur ne tire pas, la mèche d'un kamikaze déjà allumée continue ; annule la poussée.

## Review Focus

1. **Partie qui commence** : seuls canon et glace sont achetables, en pastilles compactes ; tout le reste du T1 marche comme avant. → Task 1 (`tower_reserve_check` adapté + relecture).
2. **Prendre un plan au trésor** : la carte du même plan ne revient plus ; la tour apparaît dans les boutons ; « Tour de renfort » ne donne jamais une tour verrouillée. → Task 6.
3. **Plusieurs amplificateurs autour d'une tour** : les bonus ne s'additionnent pas (le plus fort par type), un amplificateur ne s'amplifie pas. → Task 4 (`amplifier_rules_check`).
4. **Lance-flammes + canon Incendiaire sur les mêmes ennemis** : la brûlure garde la plus forte, l'explosion niveau 3 se déclenche toujours. → Task 2 (`burn_rules_check`).
5. **Tesla sur 30 ennemis groupés** : pas de double coup par éclair, pas de ralentissement visible. → Task 4.

## Vérification

Godot indisponible : contrôles `tests/unit/**/…_check.gd` écrits et relus, lancés par l'utilisateur ; planches de la fabrique regardées dans la session (planche de contrôle) ; partie de l'utilisateur V-1…V-8 (fin de Task 6), captures dans `production/qa/evidence/tours-t2a/`.

---

### Task 1: Tours génériques (identifiants, définitions, comportements)

**Files:**
- Create: `src/towers/tower_def.gd`, `src/towers/tower_behaviour.gd`, `src/towers/behaviours/shooter_behaviour.gd`, `src/towers/behaviours/frost_aura_behaviour.gd`
- Modify: `assets/data/towers.json` (format ci-dessus, canon et glace seulement à ce stade), `src/towers/tower_stats.gd`, `tower_record.gd`, `tower_reserve.gd`, `tower_placer.gd`, `tower.gd`, `tower_effects.gd`, `cannon_tower.gd` / `frost_tower.gd` (remplacés par les comportements, fichiers supprimés), `src/ui/crystal_hud.gd` (pastilles d'achat), `tower_reserve_bar.gd`, `tower_upgrade_panel.gd`, `stats_panel.gd`, `src/cards/player_modifiers.gd` (tours débloquées), `src/game/main.gd`, `tests/unit/towers/tower_reserve_check.gd`

**Interfaces:**
- Produces:
  - `class_name TowerDef extends RefCounted` : `id: StringName`, `label: String`, `behaviour: StringName`, `base_cost: int`, `range: float`, `radius: float`, `sheet_path: String`, `height_px: float`, `values: Dictionary` (toutes les autres clés), `branches: Dictionary` (id → Dictionary) ; `func value(key: String, branch: StringName, level: int) -> Variant` (valeur de la branche si le niveau ≥ 2 et la clé existe, avec `l3_<key>` au niveau 3, sinon la valeur de base).
  - `TowerStats` : `func defs() -> Array[TowerDef]`, `func def_of(id: StringName) -> TowerDef`, `starting_unlocked: Array[StringName]` ; garde `reserve`, `freeze`, `chain`, `designation`. L'énumération `Kind` disparaît.
  - `TowerRecord.kind: StringName`.
  - `class_name TowerBehaviour extends RefCounted` : `func setup(tower: Tower, def: TowerDef, record: TowerRecord, ctx: TowerContext) -> void`, `func physics_tick(delta: float) -> void`, `func draw(canvas: CanvasItem) -> void`, `func range_now() -> float`. `TowerContext` (petit RefCounted dans `tower_behaviour.gd`) regroupe enemies, bullets, arena, rules, modifiers, designator, chain limiter, damage numbers, `amp_at: Callable` (Task 4 ; renvoie des bonus neutres jusque-là).
  - `PlayerModifiers` : `is_tower_unlocked`, `unlocked_towers`, `unlock_tower`, `signal towers_unlocked_changed` ; initialisé depuis `starting_unlocked`.
  - `TowerReserve.least_owned_kind(unlocked: Array[StringName]) -> StringName`.

- [ ] **Step 1: Adapt `tower_reserve_check.gd`** aux identifiants (`&"cannon"`, `&"frost"`) avec les mêmes valeurs qu'avant ; ajouter : `def_of(&"cannon").value("burn_dps", &"incendiaire", 2) == 8.0`, `value("pierce_total", &"perforant", 3)` lit le niveau 2 faute de `l3_`, `least_owned_kind([&"cannon", &"frost"])` ignore les tours verrouillées, un `towers.json` avec un `behaviour` inconnu est refusé.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement** la migration ; canon = `shooter`, glace = `frost_aura`, avec **exactement** les comportements du T1 (déplacer le code, ne pas le réécrire). Pastilles d'achat compactes (icône de la planche, prix dessous, gris si l'or manque), une par tour débloquée ; `CrystalHud.build_bottom_band_height()` reste la seule mesure.
- [ ] **Step 4: Run, expect `TOWER_RESERVE OK`** ; relire que `chill_rules_check`, `chain_limiter_check` et `modifiers_check` restent valides.
- [ ] **Step 5: Commit** `refactor: tours génériques par identifiant et comportement`.

### Task 2: États d'ennemis (étourdi, brûlure la plus forte, poussée continue) et annonces amies

**Files:**
- Create: `src/enemies/burn_rules.gd`, `tests/unit/enemies/burn_rules_check.gd`
- Modify: `src/enemies/enemy.gd`, `src/enemies/kamikaze_behaviour.gd`, `src/enemies/artillery_behaviour.gd`, `src/hazards/telegraph_zone.gd` (couleur), `src/ui/damage_number_model.gd` + `assets/data/damage_numbers.json` (source `tower_dot`)

**Interfaces:**
- Produces:
  - `class_name BurnRules extends RefCounted` : `static func merge(cur_dps: float, cur_left: float, new_dps: float, new_left: float) -> Vector2` (x = dps, y = temps restant : le plus fort, le plus long) ; `static func stacked_dps(base_dps: float, stacks: float, max_mult: float) -> float`.
  - `Enemy.stun(seconds: float) -> void`, `is_stunned() -> bool`, `has_state(&"stunned")` ; `Enemy.apply_burn(duration, dps, burner_id := -1, stack_max := 1.0)` (au-delà de 1, chaque nouvelle application par la même source ajoute un cran jusqu'à `stack_max` × dps) ; `Enemy.push_along(direction: Vector2, speed: float)` (poussée continue, une image ; ignorée gelé ou étourdi).
  - `TelegraphZone.setup(..., color: Color = <rouge actuel>)`.

- [ ] **Step 1: Write `burn_rules_check.gd`** : `merge(5, 1, 8, 4)` → (8, 4) ; `merge(10, 3, 6, 2)` → (10, 3) ; `merge(6, 1, 6, 4)` → (6, 4) ; `stacked_dps(10, 3, 2)` == 20 ; `stacked_dps(10, 1, 2)` == 10. Affiche `BURN_RULES OK`.
- [ ] **Step 2: Run, expect FAIL** ; **Step 3: implement** `BurnRules`, puis `Enemy` (brûlure via `merge` ; l'identifiant de canon conservé comme au T1), étourdi (contact, artilleur, poussée), `push_along`, couleur des annonces, source `tower_dot` ; **Step 4: expect `BURN_RULES OK`.**
- [ ] **Step 5: Commit** `feat: étourdissement, brûlure la plus forte et poussée continue`.

### Task 3: Planches d'images des quatre tours

**Files:**
- Modify: `tools/sprite_baker/page.html` (constructeurs de formes), `tools/sprite_baker/recipes.json`
- Create: `assets/sprites/{tesla,flamethrower,mortar,amplifier}/` (planches + `sheet.json`, produites par la fabrique)

- [ ] **Step 1:** constructeurs néon dans l'esprit du §8 (Tesla : bobine et sphère ; Lance-flammes : buse ; Mortier : tube court et large ; Amplificateur : antenne et cristal), sur les bases Kenney `tower-round-*` / `tower-square-*`, avec les mêmes réglages de caméra, contour et animations que le canon (`idle`, `shoot`).
- [ ] **Step 2:** lancer la fabrique, produire les planches et `contact_sheet.py` ; regarder la planche de contrôle dans la session (lisible à la taille de jeu, couleurs distinctes des 6 tours).
- [ ] **Step 3: Commit** `feat: planches des nouvelles tours` (aucun `.import`).

### Task 4: Tesla et Amplificateur

**Files:**
- Create: `src/towers/behaviours/chain_lightning_behaviour.gd`, `src/towers/behaviours/amplifier_behaviour.gd`, `src/towers/amplifier_rules.gd`, `tests/unit/towers/amplifier_rules_check.gd`
- Modify: `assets/data/towers.json` (sections `tesla`, `amplifier`), `src/towers/tower_placer.gd` (fournit `amp_at`), comportements existants (lisent les bonus d'amplification : dégâts, cadence, durée des états)

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces:
  - `class_name AmplifierRules extends RefCounted` : `static func combine(boosts: Array[Dictionary]) -> Dictionary` (chaque entrée `{ "damage": float, "rate": float, "state": float }` ; résultat = maximum par clé ; liste vide → zéros).
  - `TowerContext.amp_at.call(position: Vector2, self_id: int) -> Dictionary` (bonus des amplificateurs dont la portée couvre la position, sans l'amplificateur `self_id`).
  - Règles d'application : dégâts × (1 + damage) ; intervalle ÷ (1 + rate) (lance-flammes : dps × (1 + rate) ; glace non concernée) ; durées d'états posés × (1 + state).

- [ ] **Step 1: Write `amplifier_rules_check.gd`** : deux Cadence 0.3 et 0.5 → rate 0.5 ; Cadence 0.3 + Catalyseur 0.5 → rate 0.3 et state 0.5 ; damage = max ; vide → zéros. Affiche `AMPLIFIER_RULES OK`.
- [ ] **Step 2: Run, expect FAIL** ; **Step 3: implement** `AmplifierRules`, `amp_at`, l'amplificateur (anneau pulsé + petits liens vers les tours boostées) et la Tesla (cible désignée prioritaire sinon la plus proche ; rebonds sans répéter un ennemi, pleins dégâts, ×`wet_mult` sur trempés, étourdissement Arc sur toute la chaîne ; éclair en ligne brisée néon visible ~0,15 s ; coups via `take_damage(..., &"cannon")`) ; **Step 4: expect `AMPLIFIER_RULES OK`.**
- [ ] **Step 5: Commit** `feat: tours Tesla et Amplificateur`.

### Task 5: Lance-flammes et Mortier

**Files:**
- Create: `src/towers/behaviours/flame_cone_behaviour.gd`, `src/towers/behaviours/mortar_behaviour.gd`, `src/towers/mortar_shell.gd`, `src/towers/crater.gd`
- Modify: `assets/data/towers.json` (sections `flamethrower`, `mortar`)

**Interfaces:**
- Consumes: Tasks 1, 2, 4 (`amp_at`, `BurnRules` via `Enemy.apply_burn`, `push_along`, `TelegraphZone` couleur, `ChainLimiter`).

- [ ] **Step 1: Lance-flammes** — cône vers la cible (désignée prioritaire) ; chaque image : dégâts continus `dps × delta` via la source `&"tower_dot"`, brûlure (`burner_id` = −1, `stack_max` = `l3_stack_max` au Napalm niveau 3), poussée `push_along` au Souffle ; visuel cône animé léger.
- [ ] **Step 2: Mortier** — tir toutes les `interval` s vers la position de la cible au moment du tir (entre `min_range` et `range`) ; `TelegraphZone` cyan de rayon `blast_radius` pendant `flight` ; impact : dégâts (× `slowed_mult` si ralenti ou gelé), Grappe : `bomblets` petites explosions via `ChainLimiter`, Sismique : `Crater` qui appelle `apply_slow(crater_slow)` chaque image dans son rayon pendant sa durée (× bonus Catalyseur) ; obus visible en arc avec ombre.
- [ ] **Step 3: Relecture** : fin de vague efface obus, cratères et annonces sans dégâts ; ennemis libérés ignorés.
- [ ] **Step 4: Commit** `feat: tours Lance-flammes et Mortier`.

### Task 6: Plans, trésor et cartes

**Files:**
- Modify: `assets/data/cards.json` (4 cartes Plans), `src/cards/card_def.gd` + `card_catalog.gd` (`min_wave`, effet `unlock_tower` validé contre `TowerStats`), `src/cards/card_pool.gd` (respect de `min_wave`, plan déjà débloqué exclu), `src/cards/player_modifiers.gd`, `src/game/main.gd` (trésor : au plus un plan parmi les choix ; « Tour de renfort » → tours débloquées seulement), `src/world/treasure_screen.gd` (affiche un plan comme une carte-objet spéciale), `tests/unit/cards/modifiers_check.gd`, `tests/unit/cards/rarity_draw_check.gd`

- [ ] **Step 1: Extend checks** : `take(plans_tesla)` → `is_tower_unlocked(&"tesla")` et `towers_unlocked_changed` émis ; un plan n'est pas tiré à la vague 1 ; un plan déjà débloqué (par le trésor) n'est plus tiré ; `CardCatalog` refuse un `unlock_tower` dont l'identifiant n'existe pas.
- [ ] **Step 2: Run, expect FAIL** ; **Step 3: implement** ; **Step 4: expect `MODIFIERS OK` / `RARITY_DRAW OK`.**
- [ ] **Step 5: Commit** `feat: plans des nouvelles tours`.
- [ ] **Step 6: Playtest de l'utilisateur** (captures) : V-1 début : canon et glace seulement, pastilles d'achat ; V-2 prendre un plan (carte et trésor) ; V-3 Tesla : rebonds, ×2 trempés, étourdissement Arc ; V-4 Lance-flammes : brûlure, Souffle qui repousse ; V-5 Mortier : annonce cyan, Grappe, cratère ; V-6 Amplificateur : bonus visibles dans les chiffres et la cadence ; V-7 canon et glace inchangés ; V-8 pas de ralentissement aux hautes vagues.
