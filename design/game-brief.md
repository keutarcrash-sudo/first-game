# Game Brief: Cristal Combo

**One-sentence pitch:** Un jeu de défense vu du dessus où tu protèges un cristal avec ton héros et des tours, et où chaque compétence choisie réagit aux autres pour créer des combos.

## Core loop
- Combat : une vague d'ennemis attaque le cristal ; le héros se déplace (ZQSD) et tire tout seul vers le curseur de la souris.
- Construction : entre deux vagues, dépenser l'or pour poser une tour ou un piège.
- Choix : prendre 1 compétence parmi 3, puis affronter la vague suivante, plus dure.
- À la mort : dépenser les points gagnés dans l'arbre de compétences, puis relancer une partie.

## Player goal & fail state — what "working" looks like
- Tenir le plus de vagues possible. La partie est perdue quand le cristal tombe à 0 PV. Chaque partie rapporte des points, donc même une défaite rend plus fort pour la suivante.

## MVP — what must exist to be the game
1. Héros déplacé avec ZQSD, qui tire automatiquement dans la direction de la souris.
2. Cristal de 100 PV et ennemis qui le ciblent, par vagues croissantes.
3. Cycle combat / construction, avec de l'or gagné à chaque kill.
4. Deux tours posées au clic : canon et piège de glace.
5. Choix d'1 compétence parmi 3 entre les vagues.
6. Système de procs : au moins 3 combos entre compétences (ex. glace + canon : dégâts en plus sur les ennemis ralentis).
7. À la mort : écran avec l'arbre de compétences (environ 6 améliorations permanentes) où dépenser les points, puis bouton rejouer.

## Out of scope — not building this
- Pas de multijoueur.
- Pas de compte ni de sauvegarde en ligne : l'arbre est sauvegardé seulement dans le navigateur.
- Arbre : environ 6 améliorations dans le MVP ; une branche « Spécialisations » s'y ajoute après le MVP (voir plus bas).
- Pas de contrôles tactiles (clavier + souris uniquement).
- Une seule carte (arène). Un seul héros, mais avec des spécialisations après le MVP (voir plus bas).
- Pas de boss ni d'histoire.
- Pas de sons ni de musique dans la première version.

## Build order
1. Héros, cristal et une vague d'ennemis, pour vérifier que se déplacer et viser est agréable.
2. Les deux tours et un premier combo (glace + canon). C'est la partie la plus risquée : si ce combo n'est pas amusant, tout le jeu est à repenser.
3. Le choix de 3 cartes et les autres combos.
4. L'écran de défaite avec l'arbre de compétences (progression sauvegardée dans le navigateur), puis les réglages de difficulté.

---
**Who it's for / what they feel:** les joueurs de jeux « une partie de plus » qui aiment trouver une combinaison trop puissante, par parties de 10 à 15 minutes.

**Art & audio direction:** formes simples et colorées sur fond sombre, avec de gros effets visibles quand un combo se déclenche. Audio : pas dans la première version.

**Reference game:** *Vampire Survivors* — on garde la vue de dessus, le tir automatique et la montée en puissance par choix de compétences ; on y ajoute les tours et la base à défendre.

---

## Après le MVP — Spécialisations et builds

**Pitch :** au début de chaque partie, le joueur choisit une spécialisation pour son héros ; chacune change sa façon de combattre, crée son propre état sur les ennemis et apporte ses cartes et ses combos, pour que chaque partie soit un build différent (esprit *Risk of Rain* : on débloque de la variété plutôt que de la puissance).

**Règles :**
- Un écran de choix de spécialisation s'affiche avant la vague 1 ; une seule spécialisation par partie.
- **Archer** est disponible dès la première partie ; les 8 autres se débloquent avec des points dans une nouvelle branche « Spécialisations » de l'arbre.
- Chaque spécialisation a son arme ou sa façon de combattre, son état sur les ennemis, 3 ou 4 cartes à elle (proposées seulement quand elle est choisie) et au moins 2 combos avec les tours ou les états des autres.
- Tout (spécialisations, états, cartes, combos, coûts de déblocage) est décrit dans des fichiers de données.

**Les 9 spécialisations :**

| Spécialisation | Façon de combattre | État | Exemple de combo |
|---|---|---|---|
| Archer (départ) | Flèches perçantes à longue portée, coups critiques | marqué | marqué + tours = dégâts en plus |
| Mage du temps | Ralentit le temps autour de lui, peut figer tous les ennemis quelques secondes | figé | figé + Archer = critique garanti |
| Berserker | Combat au corps à corps tout autour de lui, plus fort quand le cristal est en danger | saigne (dégâts dans la durée) | saigne + canons = dégâts en plus |
| Piégeur | Pose tout seul des mines et des pièges sur le chemin des ennemis | piégé (immobilisé) | piégé + canons = ×2 |
| Gardien du cristal | Bouclier et réparation du cristal, aura qui renforce les tours proches | affaibli (fait moins de dégâts) | affaibli près du cristal = cristal protégé |
| Maître du feu | Tirs qui enflamment | brûle | brûle + vent = l'incendie se propage |
| Maître de l'eau | Tirs qui trempent | trempé | trempé + glace = gelé |
| Maître de la terre | Rochers lourds, ondes de choc | ébranlé (reçoit plus de dégâts) | trempé + ébranlé = boue (très lent) |
| Maître du vent | Rafales qui repoussent les ennemis | déséquilibré | déséquilibré + pièges = ils tombent dedans |

**Ordre de construction (après le MVP) :**
1. Le système de spécialisations : écran de choix avant la vague 1, Archer, branche « Spécialisations » de l'arbre.
2. Maître du feu et Maître de l'eau.
3. Maître de la terre et Maître du vent.
4. Mage du temps et Gardien du cristal.
5. Berserker et Piégeur.
6. Équilibrage (or, ennemis, prix de l'arbre) et finitions (ligne « Cartes » qui déborde, héros qui bouge pendant le choix de carte, double-clic sur « Rejouer »).
