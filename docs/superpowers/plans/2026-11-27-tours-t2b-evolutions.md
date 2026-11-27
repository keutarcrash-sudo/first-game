# Tours T2b — Les 12 évolutions : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Une tour de niveau 3 qui remplit sa condition (carte ou objet) évolue gratuitement depuis son panneau ; 12 évolutions, une par branche ; 3 nouvelles cartes clés.

**Architecture:** Les évolutions sont des données dans `towers.json` (par tour, par branche). `TowerRecord.evolved` les active ; `TowerDef.value()` gagne une couche « évolution » (clés `evo_<key>` lues quand la tour est évoluée). Une règle pure `EvolutionRules` dit si une tour peut évoluer et pourquoi pas. Chaque comportement de tour ajoute son effet évolué ; tous les effets en chaîne passent par le `ChainLimiter`.

**Tech Stack:** Godot 4.7.2 / GDScript typé ; JSON dans `assets/data/`.

**Spec:** `docs/superpowers/specs/2026-11-27-tours-t2b-evolutions-design.md` (§5 tableau, §6 règles, §7 cartes, **§7bis toutes les règles tranchées**).

## Global Constraints

- Condition = niveau 3 + carte (`stacks_of > 0`) ou objet (`owns_item`) ; gratuit ; à vie ; garde branche et bonus du niveau 3 ; halo doré ; étoile dorée et nom au survol dans la barre de réserve.
- Évolutions réservées : Lunette (archer), Zéro absolu (maître de l'eau), Combustion (maître du feu) — le héros du message vient du `requires_spec` de la carte ou de l'objet.
- Valeurs exactes du §5 et du §7bis, en données, clés requises (null + `push_error` nommant le fichier et la clé).
- Tout effet en chaîne (lave, sauts d'éclats, éclair relancé, explosion de Fournaise, obus et petites explosions du Bombardement) passe par le `ChainLimiter` partagé.
- Les tours non évoluées et les règles T1/T2a ne changent pas.
- Interface en code ; pas d'autoload ; aucun `uid=`/`.uid`/`.import` ; `##` et typage statique.

## Décisions prises pour ce plan

- Dans chaque branche de `towers.json`, un bloc `"evolution"` :
  ```json
  "evolution": { "name": "Volcan", "requires_item": "poudre_noire" (ou "requires_card": "gel_mordant"), …valeurs… }
  ```
  Valeurs :
  - Volcan : `lava_radius` 60, `lava_duration` 3.0, `lava_dps` 10.0 ;
  - Canon de siège : `pierce_total` 999, `damage_mult` 1.5, `range_mult` 1.5 ;
  - Cœur de l'hiver : `pulse_interval` 4.0, `pulse_freeze` 1.5 ;
  - Avalanche : `shard_hops` 3, `hop_range` 120.0 ;
  - Orage : `second_bolt` 1 ;
  - Champ magnétique : `pull_speed` 50.0, `pull_stop` 40.0 ;
  - Dragon : `angle_degrees` 360.0 ;
  - Fournaise : `blast_radius` 80.0, `blast_damage` 15.0, `burn_dps` 6.0, `burn_duration` 2.0 ;
  - Bombardement : `shells` 3, `spread` 40.0 ;
  - Tremblement : `impact_stun` 0.5 ;
  - Surrégime : `rate_mult` 2.0 ;
  - Nexus : `share_burn_dps` 4.0, `share_burn_duration` 2.0, `share_slow` 0.7, `share_slow_duration` 1.0, `share_wet` 2.0, `share_stun` 0.2.
- `TowerDef.value(key, branch, level, evolved := false)` : si `evolved` et la clé existe dans `evolution`, c'est elle qui gagne ; sinon les règles actuelles.
- Cartes : type d'effet `evolution_key` (aucune valeur, aucun effet), champ `requires_tower` dans `CardDef` (la carte n'est tirée que si cette tour est débloquée). Ids : `condensateur` (tesla), `reservoir_sous_pression` (flamethrower), `artillerie_lourde` (mortar) ; rares, ×1, toutes spés.
- `Enemy.pull_towards(point: Vector2, speed: float, stop_distance: float)` : déplacement qui **s'ajoute**, actif sur un ennemi étourdi, ignoré sur un gelé.

## Review Focus

1. **Évolution prise puis tour reprise dans la réserve et reposée** : elle reste évoluée (étoile, effet). → Task 1 (`evolution_rules_check` + relecture).
2. **Condition perdue de vue** : un archer ne voit jamais « ÉVOLUER ! » pour Avalanche ; un autre héros lit « Évolution réservée à … ». → Task 1.
3. **Volcan + Fournaise + Brasier sur 40 ennemis brûlants** : aucune boucle sans fin, au plus `max_per_frame` effets par image. → Tasks 2–3 (`chain_limiter` partagé, relecture).
4. **Cœur de l'hiver** : chaque onde gèle vraiment (pas une sur deux). → Task 2.
5. **Nexus** : aucune tour boostée ne gèle directement ; les états partagés restent légers. → Task 4 (`nexus_rules_check`).

## Vérification

Godot indisponible : contrôles `tests/unit/towers/*_check.gd` écrits et relus, lancés par l'utilisateur ; partie de l'utilisateur V-1…V-8 (fin de Task 4), captures dans `production/qa/evidence/tours-t2b/`.

---

### Task 1: Mécanique d'évolution, panneau et cartes clés

**Files:**
- Create: `src/towers/evolution_rules.gd`, `tests/unit/towers/evolution_rules_check.gd`
- Modify: `assets/data/towers.json` (blocs `evolution` des 12 branches), `src/towers/tower_stats.gd` (clés requises des évolutions, condition vers un objet ou une carte existant — l'id est vérifié dans `main` après chargement des catalogues, ou en passant leurs listes d'ids), `tower_def.gd`, `tower_record.gd` (`evolved: bool`), `tower_reserve.gd` (`evolve(record) -> bool`), `src/ui/tower_upgrade_panel.gd`, `tower_reserve_bar.gd`, `src/towers/tower.gd` (halo doré), `src/cards/{card_def.gd, card_catalog.gd, card_pool.gd}`, `assets/data/cards.json`, `src/game/main.gd`

**Interfaces:**
- Produces:
  - `class_name EvolutionRules extends RefCounted` : `static func status(record: TowerRecord, def: TowerDef, has_item: Callable, has_card: Callable, spec_of_requirement: StringName, hero_spec: StringName) -> StringName` → `&"ready"`, `&"evolved"`, `&"needs_level"`, `&"missing"`, `&"other_hero"`, `&"no_branch"` ; `static func requirement_label(def: TowerDef, branch: StringName) -> String`.
  - `TowerReserve.evolve(record: TowerRecord) -> bool` (refuse si déjà évoluée ou niveau < 3) ; signal `changed`.
  - `TowerUpgradePanel` : bouton « ÉVOLUER ! » / texte grisé « Évolue avec : … » / « Évolution réservée à <héros> » ; signal `evolve_requested(record)`.

- [ ] **Step 1: Write `evolution_rules_check.gd`** : niveau 2 → `needs_level` ; niveau 3 sans l'objet → `missing` ; avec → `ready` ; après `evolve` → `evolved` ; condition réservée à `maitre_eau` pour un `archer` → `other_hero` ; `evolve` d'un niveau 2 refusé ; reprise (`mark_returned`) puis `evolved` toujours vrai ; `TowerStats` refuse une évolution sans `name`.
- [ ] **Step 2: Run, expect FAIL** ; **Step 3: implement** ; **Step 4: expect `EVOLUTION_RULES OK`** (et `tower_reserve_check`, `modifiers_check`, `rarity_draw_check` toujours valides, avec une carte `requires_tower` exclue tant que la tour est verrouillée).
- [ ] **Step 5: Commit** `feat: mécanique d'évolution des tours`.

### Task 2: Évolutions du canon et de la glace

**Files:**
- Create: `src/towers/lava_pool.gd`
- Modify: `src/towers/behaviours/shooter_behaviour.gd`, `frost_aura_behaviour.gd`, `src/towers/tower_effects.gd`

- [ ] **Step 1: Volcan** — l'explosion de mort Incendiaire niveau 3 d'un canon évolué pose une `LavaPool` (dégâts continus `&"tower_dot"` via `take_dot_damage`, **sans** brûlure de canon), plafond par image, effacée hors COMBAT.
- [ ] **Step 2: Canon de siège** — obus qui traversent tout (`pierce_total` 999), dégâts ×1,5, portée et `bullet_max_range` ×1,5, obus dessinés plus gros.
- [ ] **Step 3: Cœur de l'hiver** — toutes les 4 s, `force_freeze`-like de 1,5 s (× Catalyseur) sur les ennemis de la zone, en ignorant le temps d'attente avant de regeler ; anneau de choc visuel.
- [ ] **Step 4: Avalanche** — l'éclat de mort Éclats d'une glace évoluée fait 3 sauts (plus proche non touché dans 120 px), chaque saut = dégâts d'éclat et une consommation du plafond ; trait de glace visible.
- [ ] **Step 5: Relecture** des points 3 et 4 du Review Focus ; **Commit** `feat: évolutions du canon et de la glace`.

### Task 3: Évolutions de la Tesla et du lance-flammes

**Files:**
- Modify: `src/towers/behaviours/chain_lightning_behaviour.gd`, `flame_cone_behaviour.gd`, `src/enemies/enemy.gd` (`pull_towards`), `src/towers/tower_effects.gd` (Fournaise)

- [ ] **Step 1: Orage** — après la chaîne, un second éclair depuis le dernier ennemi touché, mêmes valeurs, ennemis nouveaux seulement, une seule fois, plafond par image.
- [ ] **Step 2: Champ magnétique** — chaque image, `pull_towards(tour, 50, 40)` sur les ennemis de la zone (étourdis compris, gelés exclus).
- [ ] **Step 3: Dragon** — `angle_degrees` 360 : pas de visée, anneau de feu dessiné.
- [ ] **Step 4: Fournaise** — à la mort d'un ennemi en feu dans la portée d'un lance-flammes évolué Souffle : 15 dégâts et brûlure (6/s, 2 s) dans un rayon de 80, via le plafond ; s'ajoute à Brasier éternel.
- [ ] **Step 5: Relecture** du point 3 du Review Focus ; **Commit** `feat: évolutions de la Tesla et du lance-flammes`.

### Task 4: Évolutions du mortier et de l'amplificateur

**Files:**
- Create: `src/towers/nexus_rules.gd`, `tests/unit/towers/nexus_rules_check.gd`
- Modify: `src/towers/behaviours/mortar_behaviour.gd`, `amplifier_behaviour.gd`, `src/towers/tower_placer.gd` (`amp_at` renvoie aussi les états partagés), comportements qui tirent (appliquent les états partagés à leurs coups)

**Interfaces:**
- Produces: `class_name NexusRules extends RefCounted` : `static func shared_states(boosted: Array[Dictionary], values: Dictionary) -> Array[Dictionary]` (entrée : `{ "id": StringName, "branch": StringName, "level": int }` des tours boostées ; sortie : états légers `{ "state": &"burn"|&"slow"|&"wet"|&"stun", … }` selon la table §7bis ; jamais de gel).

- [ ] **Step 1: Write `nexus_rules_check.gd`** : canon Incendiaire → brûlure 4/s 2 s ; glace → ralentissement 0,7 1 s et aucun gel ; glace Blizzard niveau 3 → aussi trempé 2 s ; Tesla Arc → étourdissement 0,2 s ; mortier Sismique non évolué → rien ; liste vide → rien ; une tour ne reçoit pas ses propres états. Affiche `NEXUS_RULES OK`.
- [ ] **Step 2: Run, expect FAIL** ; **Step 3: implement** `NexusRules`, Surrégime (`rate` ×2), Nexus (états appliqués à chaque coup des tours boostées), Bombardement (3 obus sur 3 cibles différentes, sinon ±40 px, petites explosions via le plafond), Tremblement (chaque impact étourdit 0,5 s × Catalyseur) ; **Step 4: expect `NEXUS_RULES OK`.**
- [ ] **Step 5: Commit** `feat: évolutions du mortier et de l'amplificateur`.
- [ ] **Step 6: Playtest de l'utilisateur** : V-1 bouton « ÉVOLUER ! » / « Évolue avec … » / héros réservé ; V-2 tour évoluée reprise et reposée reste évoluée ; V-3 Volcan et Canon de siège ; V-4 Cœur de l'hiver et Avalanche ; V-5 Orage et Champ magnétique ; V-6 Dragon et Fournaise ; V-7 Bombardement, Tremblement, Surrégime, Nexus ; V-8 aucun ralentissement aux hautes vagues.
