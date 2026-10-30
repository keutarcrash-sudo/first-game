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
- Arbre limité à environ 6 améliorations.
- Pas de contrôles tactiles (clavier + souris uniquement).
- Une seule carte et un seul héros.
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
