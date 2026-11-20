# Cartes et lisibilité : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cartes par spé et par compétence avec cinq raretés et relance payante, panneau de stats, impacts propres à chaque spé, et décor néon sur le terrain.

**Architecture:** On prolonge le système existant : `cards.json` gagne une rareté et des conditions, `CardCatalog`/`CardDef` les lisent, `PlayerModifiers` gagne les nouveaux types d'effet et devient la source unique des stats du héros (lue par le jeu et par le panneau), `CardPool` tire par rareté et sait relancer. Les effets spéciaux (épiques, légendaires) se branchent sur les signaux existants des ennemis et des tirs. Les impacts réutilisent `PopBurst` et `ImpactFeedback` ; le décor est produit par la fabrique d'images et posé par un nœud `DecorField`.

**Tech Stack:** Godot 4.7.2 / GDScript typé ; JSON dans `assets/data/` ; fabrique `tools/sprite_baker/` (Node + Playwright + three.js).

**Spec:** `docs/superpowers/specs/2026-11-20-cartes-et-lisibilite-design.md`

## Global Constraints

- Valeurs dans des JSON de `assets/data/`, chargés par une classe `RefCounted` qui valide et renvoie `null` + `push_error` nommant le fichier et la clé fautive. Interface en code, pas de `.tscn` nouveau, pas d'autoload, pas de `uid=`/`.uid`/`.import` écrits.
- `##` sur toute fonction publique ; typage statique partout.
- Aucune règle existante ne change, sauf (spec §9) : Jet puissant héros seulement, Munitions incendiaires → « Canons incendiaires », Frappe du brasier → carte du Maître du feu sans déblocage, tremblement « petit » 6 px, arrêt sur image au plus toutes les 0,25 s.
- Raretés, poids, hausse par vague, coûts de relance, contenu des cartes : **exactement** les tables de la spec §5.
- Une seule légendaire **prise** par partie ; la clic-droit est débloquée d'office, A/E/R par « Nouvelle compétence » (spec §8bis).
- Réductions de recharge plafonnées à −75 % ; ralentissements : le plus fort l'emporte.

## Décisions prises pour ce plan

- `cards.json` : chaque carte gagne `"rarity"` (`common`, `uncommon`, `rare`, `epic`, `legendary`) ; optionnels `"requires_ability"` (id d'une compétence de `abilities.json`) et `"requires_card"` (id d'une carte à avoir prise au moins une fois). Les raretés, poids, couleurs, hausses et coûts de relance vivent dans un nouveau `assets/data/card_rarities.json`.
- Nouveaux types d'effet (noms figés pour tout le plan) : `hero_damage_bonus` (value), `move_speed_bonus` (value), `pickup_radius_mult` (value, multiplicatif : 1.4 ou 2.0), `gold_lifetime_bonus` (value, secondes), `cards_offered_bonus` (value), `ability_cooldown_mult` (ability_id, value : 0.7), `ability_value_mult` (ability_id, key, value), `ability_value_bonus` (ability_id, key, value), et des drapeaux sans valeur : `burst_on_crit` (chance), `ghost_arrows`, `burning_vulnerability` (value 0.25), `burn_spread_on_death` (radius 80), `wet_slow` (factor 0.75), `shatter_on_frozen_death` (damage 20, radius 60, freeze 1.0).
- L'offre et la relance vivent dans `CardPool` ; l'écran de choix affiche et émet `reroll_requested`.

## Review Focus

1. **Réserve vide ou presque** (fin de partie, beaucoup de cartes épuisées) : l'offre montre moins de cartes ou rien, la relance se désactive, le jeu continue. → Task 2.
2. **Légendaire prise** : plus jamais proposée, y compris après relance. → Task 2.
3. **Effets en chaîne** (Brasier éternel qui enflamme un ennemi qui meurt en brûlant…, Zéro absolu sur des ennemis gelés en série) : pas de boucle infinie dans une même image, pas de plantage sur un ennemi libéré. → Task 3.
4. **Stat affichée ≠ stat utilisée** : le panneau lit les mêmes fonctions que le jeu. → Task 4.
5. **Décor au point de départ du cristal ou sur le trajet** : jamais sous le chariot au départ ; caché le long du trajet de la vague. → Task 6.

## Vérification

Godot indisponible dans la session : relecture `godot-gdscript-specialist` par tâche, relecture finale, puis partie de l'utilisateur (V-1 à V-9 en fin de Task 6) avec captures dans `production/qa/evidence/story-019-cartes-et-lisibilite/`. La fabrique (Task 6) est lancée et ses planches regardées dans la session.

---

### Task 1: Données des cartes et nouveaux effets de base

**Files:**
- Create: `assets/data/card_rarities.json`, `src/cards/card_rarities.gd`
- Modify: `assets/data/cards.json`, `src/cards/card_def.gd`, `src/cards/card_catalog.gd`, `src/cards/player_modifiers.gd`, `src/hero/hero.gd` (vitesse), `src/economy/gold_field.gd` (portée et durée), `src/abilities/ability_caster.gd` et `src/abilities/effects/*.gd` (bonus de compétence), `src/specs/elemental_weapon.gd` / `archer_weapon.gd` (dégâts héros), `src/towers/cannon_tower.gd` (dégâts généraux seulement), `assets/data/skill_tree.json` (Frappe du brasier n'est plus à débloquer)

**Interfaces:**
- Produces:
  - `CardDef.rarity: StringName`, `CardDef.requires_ability: String`, `CardDef.requires_card: String`.
  - `class_name CardRarities extends RefCounted` — `static func load_from_file(path) -> CardRarities` ; `func order() -> Array[StringName]` (`common`→`legendary`) ; `func weight(rarity: StringName, wave: int) -> float` (formule spec §5.2) ; `func color(rarity) -> Color` ; `func label(rarity) -> String` (« COMMUNE », « PEU COMMUNE », « RARE », « ÉPIQUE », « LÉGENDAIRE ») ; `func reroll_cost(rerolls_done: int) -> int` (`base + step × rerolls_done`, 20 et 20).
  - `PlayerModifiers` (source unique, lue par le jeu et le panneau) : `hero_damage_multiplier() -> float` (général × héros), `damage_multiplier()` (général, canons), `move_speed_factor() -> float`, `pickup_radius_factor() -> float`, `gold_lifetime_bonus() -> float`, `cards_offered_bonus() -> int`, `ability_cooldown_factor(ability_id: String) -> float` (plancher 0.25), `ability_value(ability_id: String, key: String, base: float) -> float` (base × mult + bonus), `has_flag(flag: StringName) -> bool`, `flag_value(flag: StringName, key: String) -> float`, `took_legendary() -> bool`.
- `assets/data/card_rarities.json` :
  ```json
  { "rarities": [
      { "id": "common", "label": "COMMUNE", "color": "#b8b8c8", "weight": 50, "growth": 0.0 },
      { "id": "uncommon", "label": "PEU COMMUNE", "color": "#3bff7a", "weight": 28, "growth": 0.03 },
      { "id": "rare", "label": "RARE", "color": "#3b9dff", "weight": 14, "growth": 0.06 },
      { "id": "epic", "label": "ÉPIQUE", "color": "#b44bff", "weight": 6, "growth": 0.10 },
      { "id": "legendary", "label": "LÉGENDAIRE", "color": "#ff9a1f", "weight": 2, "growth": 0.12 } ],
    "reroll": { "base_cost": 20, "step": 20 } }
  ```

- [ ] **Step 1:** `cards.json` réécrit selon la spec §5.4 (cartes existantes : mêmes ids et valeurs, rareté ajoutée ; `munitions_incendiaires` garde son id mais s'affiche « Canons incendiaires » ; `frappe_du_brasier` : `requires_spec` `maitre_feu`, `locked_by_default` retiré ; `jet_puissant` passe en `hero_damage_bonus`). Nouvelles cartes avec les ids : `aimant`, `pas_leger`, `plus_de_choix`, `collectionneur`, `esquive`, `pointe_acier`, `deluge`, `regard_percant`, `tir_en_rafale`, `fleches_fantomes`, `grosse_boule`, `trainee_ardente`, `rempart_flammes`, `apocalypse`, `combustion`, `brasier_eternel`, `lame_de_fond`, `glisse`, `grande_flaque`, `grand_froid`, `maree_montante`, `zero_absolu`. Ids de compétence et clés de valeurs : ceux de `assets/data/abilities.json`.
- [ ] **Step 2:** `CardRarities`, extension de `CardDef`/`CardCatalog` (validation : rareté connue, `requires_ability` existe, `requires_card` existe, types d'effet connus avec leurs clés).
- [ ] **Step 3:** `PlayerModifiers` : nouveaux types et lectures ; branchements : vitesse du héros, portée et durée de l'or, bonus de compétences lus au lancement, dégâts héros / généraux, `cards_offered_bonus` additionné au bonus de l'arbre.
- [ ] **Step 4:** Relecture puis commit `feat: cartes par spé avec raretés et nouveaux effets de base`.

### Task 2: Tirage par rareté, relance et écran de choix

**Files:**
- Modify: `src/cards/card_pool.gd`, `src/cards/card_choice_screen.gd`, `src/game/main.gd`
- Create: `tests/unit/cards/rarity_draw_check.gd`

**Interfaces:**
- Consumes: Task 1.
- Produces: `CardPool.draw(wave: int) -> Array[CardDef]` (rareté par emplacement, réserve filtrée selon spec §5.1 et §8bis, `is_ability_unlocked: Callable` fourni au constructeur) ; `CardPool.reroll_cost() -> int` ; `CardPool.reroll(wave: int) -> Array[CardDef]` (n'achète rien : `main.gd` dépense l'or via `GameState.spend_gold` puis appelle `reroll`) ; `CardPool.begin_choice() -> void` (remet le compteur de relances à 0) ; `CardChoiceScreen.signal reroll_requested` ; `CardChoiceScreen.show_cards(cards: Array[CardDef], reroll_cost: int, can_afford: bool)`.

- [ ] **Step 1:** `rarity_draw_check.gd` (`extends SceneTree`, imprime `RARITY OK` / `RARITY FAIL: <nom>`) avec une `RandomNumberGenerator` de graine fixe et un catalogue construit en code : aucune carte en double dans une offre ; une légendaire prise n'apparaît plus sur 200 tirages ; réserve de 2 cartes → offre de 2 ; carte de compétence absente tant que la compétence n'est pas débloquée ; `requires_card` respecté ; sur 2000 tirages à la vague 1, proportion de communes entre 0.45 et 0.55.
- [ ] **Step 2:** Implémenter le tirage et la relance.
- [ ] **Step 3:** Écran : cadre et libellé de rareté colorés, bouton « Relancer (X or) » grisé si l'or manque ou si la réserve est vide, nom et touche de la compétence sur les cartes de compétence, légendaire avec cadre qui pulse et « LÉGENDAIRE ! » en Bangers.
- [ ] **Step 4:** Relecture puis commit `feat: tirage par rareté et relance payante`.

### Task 3: Épiques et légendaires

**Files:**
- Modify: `src/enemies/enemy.gd`, `src/hero/hero.gd`, `src/hero/hero_bullet.gd`, `src/waves/wave_spawner.gd` (ou un nouveau `src/cards/card_effects.gd` qui écoute les morts), `src/game/main.gd`

**Interfaces:**
- Consumes: `PlayerModifiers.has_flag/flag_value` (Task 1).
- Produces: `Enemy.signal died_with_state(position: Vector2, was_burning: bool, was_frozen: bool)` (émis avec `died`) ; `class_name CardEffects extends Node` (créé par `main.gd`) qui applique Brasier éternel et Zéro absolu à la mort, Combustion (+25 % de dégâts sur un ennemi qui brûle, dans `Enemy._damage`), Marée montante (ralentissement 0,75 tant que trempé, via la règle « le plus fort l'emporte »), Tir en rafale (dans `Hero` : sur un critique, 30 % de chance d'une seconde flèche marquée « sans rafale »), Flèches fantômes (traversée illimitée des flèches normales), Collectionneur (déjà couvert par Task 1).

- [ ] **Step 1:** Implémenter ; propagation en chaîne différée d'une image (`call_deferred`) et jamais sur un ennemi libéré.
- [ ] **Step 2:** Relecture puis commit `feat: cartes épiques et légendaires`.

### Task 4: Panneau de stats

**Files:**
- Create: `src/ui/stats_panel.gd`
- Modify: `src/ui/crystal_hud.gd`, `src/game/main.gd`

**Interfaces:**
- Consumes: lectures de `PlayerModifiers` (Task 1), armes du héros (`ArcherWeapon`/`ElementalWeapon`), `HeroStats`, `EconomyStats`.
- Produces: `class_name StatsPanel extends Control` — `func setup(hero: Hero, modifiers: PlayerModifiers, economy: EconomyStats) -> void` ; se rafraîchit sur `PlayerModifiers.changed` ; lignes selon spec §6 ; valeur augmentée en vert avec « ▲ » pendant 4 s.

- [ ] **Step 1:** Implémenter (en haut à droite, Bungee pour les chiffres, sous la ligne de spécialisation actuelle).
- [ ] **Step 2:** Relecture puis commit `feat: panneau de stats du héros`.

### Task 5: Impacts par spé

**Files:**
- Modify: `assets/data/impact.json` (petit 6 px ; `"hitstop": { …, "min_interval": 0.25 }`), `src/visuals/impact_stats.gd`, `src/visuals/impact_feedback.gd`, `src/abilities/ability_caster.gd`, `src/abilities/effects/{piercing_arrow,water_wave,ground_zone,fireball,meteor}.gd`

**Interfaces:**
- Consumes: `PopBurst.spawn` (ou l'API existante de `src/visuals/pop_burst.gd`), `ImpactFeedback.shake/hitstop`.
- Produces: table spec §7 appliquée exactement ; `ImpactFeedback.hitstop()` ignoré si le précédent date de moins de `min_interval` (temps réel).

- [ ] **Step 1:** Implémenter. **Step 2:** Relecture puis commit `feat: impacts propres à chaque spé`.

### Task 6: Décor néon

**Files:**
- Modify: `tools/sprite_baker/recipes.json` (+ `page.html` si besoin), `assets/data/visuals.json`
- Create: `assets/models/source/kenney/` (pièces de décor ajoutées), `assets/sprites/decor_*/`, `assets/data/decor.json`, `src/visuals/decor_field.gd`
- Modify: `src/game/main.gd`

**Interfaces:**
- Produces: `assets/data/decor.json` : `{ "count": 40, "min_spacing": 120.0, "crystal_clearance": 220.0, "path_clearance": 70.0, "pieces": [ { "sheet": "res://assets/sprites/decor_rock_a", "height_px": 70.0 }, … ] }` ; `class_name DecorField extends Node2D` — `func setup(stats: DecorStats, field_rect: Rect2, crystal_start: Vector2, rng: RandomNumberGenerator) -> void` (pose une fois), `func show_path(path: CrystalPath) -> void` (cache les pièces à moins de `path_clearance` du trajet).

- [ ] **Step 1:** Choisir dans le pack Kenney (`/root/.claude/uploads/dc8da191-41f7-5183-8267-1281bff2f7d6/524b08b7-kenney_tower-defense-kit.zip`) 5 à 8 pièces : rochers, arbres, cristaux de décor (`detail-rocks`, `detail-rocks-large`, `detail-tree`, `detail-tree-large`, `detail-crystal`, `detail-crystal-large`, `detail-dirt`…), ajouter leurs `.glb` aux sources, les recettes (palette violette / cyan / rose, 1 direction), lancer la fabrique, regarder la planche de contrôle.
- [ ] **Step 2:** `DecorStats` (loader), `DecorField`, branchement dans `main.gd` (au-dessus du sol, sous le trajet ; `show_path` sur `wave_prepared`).
- [ ] **Step 3:** Relecture, relecture finale de la branche, commit et push `feat: décor néon du terrain`.
- [ ] **Step 4: Partie jouée par l'utilisateur**

| N° | À vérifier | Attendu |
|---|---|---|
| V-1 | Choix de cartes, chaque spé | Seulement communes + cartes de la spé ; plus de cartes « feu » pour l'Eau ou l'Archer |
| V-2 | Raretés | Cadres colorés et libellés ; plus de rares en fin de partie |
| V-3 | Relance | 20, 40, 60 or ; grisée sans or ; revient à 20 au choix suivant |
| V-4 | Cartes de compétence | N'apparaissent qu'après avoir débloqué la compétence ; leur effet se voit |
| V-5 | Aimant, Pas léger, Plus de choix | Ramassage plus large, héros plus rapide, 4 cartes |
| V-6 | Épique / légendaire (si tirée) | Effet visible ; une légendaire prise ne revient plus |
| V-7 | Panneau de stats | Valeurs justes ; ▲ vert après une carte liée |
| V-8 | Impacts | Archer « TCHAK ! », « ZIP ZIP ! » ; Eau « SPLASH ! », « PLOUF ! », « SPLOOSH ! » ; Feu « FWOOSH ! » ; tremblement perceptible ; pas d'arrêts sur image en rafale |
| V-9 | Décor | Rochers, arbres, cristaux néon sur le terrain ; jamais sur le trajet de la vague |
