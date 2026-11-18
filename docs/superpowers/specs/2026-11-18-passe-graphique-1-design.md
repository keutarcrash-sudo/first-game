# Passe graphique 1 — Néon pop : Design

> **Date** : 2026-11-18
> **Statut** : approuvé par l'utilisateur le 2026-11-18 (« partons là-dessus pour l'instant »), après l'essai de la fabrique https://claude.ai/artifact/99ZfLAAZtsfi5tmssEG3NX
> **Contexte** : l'étape 4 du design v2 (danger pour le héros) est mise en pause à la demande de l'utilisateur, qui veut explorer l'univers graphique.
> **Design de référence du jeu** : `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md`

---

## 1. Intention

Donner au jeu une identité visuelle **néon pop** : couleurs pop et nuits violettes façon Hotline Miami, personnages cernés de noir comme en bande dessinée, sorts spectaculaires « à la Diablo » mais très pop art (étoiles d'explosion, onomatopées), et sensation d'impact (tremblement d'écran, arrêt sur image).

Pourquoi maintenant : le jeu marche (étapes 1 à 3b validées) mais tout est dessiné avec des ronds et des losanges ; l'utilisateur veut voir à quoi ressemble son univers avant de continuer le contenu.

Ce qui compte pour l'utilisateur :

- des personnages **détaillés et stylés**, pas des formes basiques ;
- **zéro coût** : uniquement des ressources gratuites ;
- un dépôt **léger** : seuls les fichiers réellement utilisés entrent dans le projet.

## 2. Ce qui a été validé avec l'utilisateur

- **Style « Néon pop »** (piste C de la maquette https://claude.ai/artifact/LveKkahbvBmZL4dHNEfrfi) : fond violet nuit avec trame de points, personnages et objets saturés avec contour noir épais et halo de couleur dessous, étoiles d'explosion remplies de points avec onomatopées, affichage en lettres de BD.
- **Tremblement d'écran et arrêt sur image** : à ajouter.
- **Personnages 3D gratuits** plutôt que dessin par le code ou IA payante : pack *Ultimate Animated Character Pack* de Quaternius (fourni par l'utilisateur) et *Tower Defense Kit* de Kenney (fourni, licence CC0 lue dans son `License.txt`).
- **Rendu validé** sur l'aperçu https://claude.ai/artifact/VyRY9yZ1tZ3qdvZ6trBJrS (personnages recolorés néon, aplats en 3 tons, contour noir, halo au sol).
- **Caméra inclinée (environ 50°)**. La vue « tout à fait de dessus » a d'abord été choisie, puis abandonnée après l'essai de la fabrique : de pile au-dessus, les héros ne montraient que leur chapeau. Vue en biais validée par l'utilisateur.
- **Cristal et tour de glace fabriqués sur mesure** (formes 3D simples générées par la fabrique) : le cristal et la tour à cristaux du pack Kenney ne ressemblaient à rien ; versions sur mesure validées (gemme cyan à facettes sur un chariot à phares ; socle Kenney violet + pic de glace + anneau de givre).
- **Approche C** (voir section 3).
- **Ne garder que les fichiers utilisés** des packs.

## 3. Approches envisagées

| Approche | Principe | Pour | Contre |
|---|---|---|---|
| A. Jeu en 3D | Monde 3D, caméra fixe au-dessus | Fidèle à l'aperçu, animations fluides | Réécriture d'une grande partie du code (déplacements, collisions, tirs, zones, caméra), plus lourd en navigateur |
| B. 3D dans le jeu 2D | Chaque personnage 2D contient une petite vue 3D | Peu de code changé | Très lent avec beaucoup d'ennemis, surtout en navigateur |
| **C. 3D → images 2D (choisie)** | Photographier chaque modèle en biais (environ 50°), avec le rendu néon BD, image par image pour chaque animation et chacune des 8 directions ; le jeu 2D affiche l'image de la direction la plus proche | Le code de jeu reste en 2D, léger, personnages animés, détaillés et cohérents, fabrication automatique | 8 fois plus d'images (toujours légères) ; changer d'angle demande de relancer la fabrique |

## 4. Objectifs

1. Une **fabrique d'images** reproductible dans le projet, qui transforme un modèle 3D + une palette en planches d'animation PNG vues de dessus, au rendu néon BD.
2. Le **héros** (3 spécialisations) et l'**ennemi de base** affichés avec ces planches, animés et orientés.
3. Les **tours** et le **cristal** affichés avec des images tirées du pack Kenney.
4. Le **sol, le trajet, l'affichage et les effets de sorts** au style néon pop.
5. **Tremblement d'écran** et **arrêt sur image**.

## 5. Non-objectifs

- Pas de nouvelle mécanique de jeu (l'étape 4 reste en pause) ; aucune valeur d'équilibrage ne change.
- Pas de passage en 3D, pas de lumière dynamique.
- Pas de décor de niveau (arbres, rochers, tuiles du pack Kenney).
- Pas de nouveaux types d'ennemis (le zombie est préparé, pas utilisé).
- Pas de sons.

## 6. Anti-objectifs (échec même si « ça marche »)

- Un jeu **moins lisible** qu'avant : les ennemis, l'or, les zones annoncées, la cible désignée et les états (brûle, trempé, gelé, marqué) doivent rester visibles d'un coup d'œil, même avec beaucoup d'ennemis.
- Un jeu **plus lent** dans le navigateur.
- Un dépôt alourdi de fichiers inutilisés.
- Des effets d'impact qui **fatiguent** (tremblements permanents, arrêts trop longs).

## 7. Contraintes

- Godot 4.7.2, rendu Compatibility, export web ; vue 1280×720 ; terrain 2400×1600, caméra qui suit le héros.
- Règles du projet : valeurs dans des fichiers de données JSON validés au chargement, interface construite en code, pas d'autoload, pas de fichiers `uid=` / `.uid` écrits par les agents.
- Godot n'est pas disponible dans la session de travail : la vérification finale se fait par une partie de l'utilisateur sur Windows.
- La fabrique d'images tourne dans la session de travail (Linux, Chromium sans écran) ; elle n'a pas besoin de tourner chez l'utilisateur.
- Réseau de la session : le registre npm est accessible, le CDN jsDelivr ne l'est pas.

## 8. Ressources retenues

### 8.1 Personnages (Quaternius, *Ultimate Animated Character Pack*)

Le pack fourni n'a pas de fichier de licence ; Quaternius publie ses packs en CC0. **L'utilisateur confirme la licence sur la page de téléchargement.**

| Rôle | Modèle | Palette néon (matériau → couleur) |
|---|---|---|
| Archer | `Elf` | Clothes `#ff2bd6`, Hat `#7a1fd6`, Belt `#2a1a5e`, Gold `#ffe23b`, Skin `#f2b48a`, Face `#ffffff` |
| Maître du feu | `Wizard` | Clothes `#ff8a1f`, Hat `#ff3b3b`, Belt `#2a1a5e`, Gold `#ffe23b`, Hair `#fff1d0`, Skin `#f2b48a`, Face `#ffffff` |
| Maître de l'eau | `Witch` | Clothes `#1e6bff`, Hat `#19e3ff`, Belt `#2a1a5e`, Gold `#ffffff`, Hair `#8ff4ff`, Skin `#f2b48a`, Face `#ffffff` |
| Ennemi de base | `Goblin_Male` | Skin `#9dff3b`, Pants `#7a1fd6`, Teeth `#ffffff`, Face `#000000` |
| (plus tard) ennemi lent | `Zombie_Male` | Skin `#19e3ff`, Clothes `#ff2bd6`, DarkClothes `#2a1a5e`, Pants `#ffe23b`, Guts `#ff3b3b`, Bones `#fff1d0`, Brain `#ff8ef0`, Face `#000000` |

Animations utilisées (noms du pack) : héros `Idle`, `Run`, `Shoot_OneHanded`, `Roll`, `RecieveHit`, `Death` ; ennemi `Run`, `Punch`, `RecieveHit`, `Death` (zombie : `Walk` au lieu de `Run`).

### 8.2 Tours et cristal (Kenney, *Tower Defense Kit* 2.1, CC0)

Les modèles Kenney n'ont pas de matériaux par couleur : ils lisent leurs couleurs dans une petite image de palette partagée (`Textures/colormap.png`). Le recolorage néon se fait en **remplaçant cette palette** par une version néon.

Fichiers gardés (format GLB uniquement) :

- **Canon** : socle `tower-round-bottom-a` + `tower-round-middle-a`, arme `weapon-cannon`.
- **Socle de la tour de glace** : `tower-square-bottom-a` + `tower-square-middle-a` (le haut est fabriqué sur mesure).
- **Ennemis volants pour plus tard** : `enemy-ufo-a` à `enemy-ufo-d`.
- `Textures/colormap.png` et `License.txt`.

**Recolorage** : chaque pièce reçoit sa propre version néon de la palette (teinte unique par pièce, gris → violet foncé) : socles violets, arme du canon orange.

**Fabriqués sur mesure par la fabrique** (formes 3D simples, même rendu) : le **cristal** (grande gemme cyan à facettes avec deux éclats, sur un chariot orange à roues et phares jaunes) et le **haut de la tour de glace** (grand pic de glace blanc-cyan, petits éclats, anneau de givre).

Écartés : tuiles, neige, arbres, rochers, terre, cristaux, toits, autres armes, structures en bois, sélecteurs, munitions.

### 8.3 Polices

Bangers (titres, onomatopées) et Bungee (chiffres, nombres) depuis Google Fonts, licence SIL OFL (usage commercial autorisé), fichiers `.ttf` ajoutés au projet avec leur licence.

## 9. Le design

### 9.1 La fabrique d'images (`tools/sprite_baker/`)

- Programme Node.js qui ouvre une page dans Chromium sans écran (Playwright, déjà installé dans la session) et y charge three.js (version 0.147, installée par npm dans `tools/sprite_baker/`, pas depuis un CDN).
- Une **recette** JSON (`tools/sprite_baker/recipes.json`) décrit chaque image à fabriquer : modèle source, palette (par matériau pour Quaternius, image de palette pour Kenney), animations, nombre d'images par seconde, taille de case.
- Rendu : caméra **orthographique inclinée d'environ 50°**, aplats en 3 tons, contour noir épais, fond transparent. Chaque animation est photographiée dans **8 directions** (tous les 45°, la direction 0 regardant vers la droite de l'écran). Point d'ancrage de chaque image : les pieds (ou la base) de l'objet.
- Sortie, par élément : une planche PNG par animation (cases alignées sur une ligne) et un fichier JSON de description (taille de case, nombre d'images, images par seconde, boucle ou non, point d'ancrage) dans `assets/sprites/<élément>/`.
- Le **canon** est rendu tour + arme assemblés, dans les 8 directions de l'arme ; la **tour de glace** est une image fixe (son anneau peut tourner en jeu) ; le **cristal** est une image fixe.
- Lancement documenté dans `tools/sprite_baker/README.md` ; le résultat est commité, la fabrique n'est relancée que pour changer une couleur ou ajouter une animation.

### 9.2 Où vont les fichiers

- Modèles sources (convertis en GLB, environ 5 Mo pour Quaternius) : `assets/models/source/quaternius/` et `assets/models/source/kenney/` (avec `License.txt`). Un fichier `.gdignore` dans `assets/models/source/` empêche Godot de les importer (ils ne servent qu'à la fabrique).
- Images produites : `assets/sprites/<élément>/` (PNG + JSON), importées par Godot.
- Polices : `assets/fonts/`.
- Rien d'autre des packs n'entre dans le dépôt ; les zips restent hors du projet.

### 9.3 Dans le jeu

- **Personnages animés** : un composant d'affichage lit le JSON d'une planche et anime les images. Le héros joue *course* quand il bouge et *repos* sinon, *tir* au moment d'un tir (par-dessus la course), *roulade* pendant un saut, *coup reçu* quand il est touché (prévu pour l'étape 4), *mort* à la défaite. L'ennemi joue *course* en marchant, *frappe* au contact du cristal, *coup reçu* quand il prend des dégâts.
- **Orientation** : le jeu affiche, parmi les 8 directions, celle la plus proche de la souris (héros) ou de la direction de marche (ennemi) ; les images ne pivotent pas.
- **Mort des ennemis** : l'ennemi est retiré du jeu comme aujourd'hui (logique inchangée), et une **image de mort** séparée joue l'animation de mort à sa place puis disparaît ; elle n'a aucun effet sur le jeu.
- **États** : les marques actuelles (brûle, trempé, gelé, marqué, ralenti, cible désignée) restent dessinées **par-dessus** l'image, adaptées au style (contour noir, couleurs néon) pour rester lisibles.
- **Tours** : le canon affiche la direction la plus proche de sa cible ; la tour de glace est fixe ; halo de couleur au sol.
- **Cristal** : image du chariot à cristal, halo cyan qui pulse.
- **Sol et trajet** : fond violet nuit avec trame de points (motif répété), trajet bordé de noir avec pointillés cyan lumineux, comme la maquette C.
- **Effets de sorts** : les explosions (Boule de feu, Météore) et les zones gardent leurs formes actuelles mais au style néon pop ; les grosses explosions ajoutent une **étoile** remplie de points et une **onomatopée** (« BOUM ! », « POW ! ») ; les coups critiques affichent « CRIT ! ».
- **Affichage** : lettres de BD (Bangers / Bungee), contours noirs, cases de compétences sombres à liseré néon.
- **Tremblement d'écran** : sur les grosses explosions, quand le cristal est touché, et à la mort d'un ennemi par une compétence ; intensité et durée en données.
- **Arrêt sur image** : très court (de l'ordre de 0,05 s), quand un ennemi meurt d'un coup critique ou d'une compétence, et sur les grosses explosions ; valeurs en données ; deux arrêts ne s'empilent pas.

### 9.4 Précisions (relecture du design)

- **Caméra de la fabrique** : inclinée d'environ 50°, 8 directions. *(réponse de l'utilisateur, après l'essai)*
- **Taille à l'écran** *(choix de Claude)* : les zones de collision et les rayons de jeu actuels ne changent pas ; l'image d'un personnage peut déborder un peu de son rayon (de l'ordre de 2 à 2,5 fois le rayon) pour être lisible. Cases des planches entre 64 et 96 px, choisies pour rester nettes à cette taille.
- **Performance** *(choix de Claude)* : rester fluide dans le navigateur avec une soixantaine d'ennemis à l'écran (fin de partie actuelle) ; une image animée par ennemi suffit à cette échelle.
- **Avant le choix de spécialisation** *(choix de Claude)* : l'écran de choix couvre le terrain ; le héros affiche la planche de l'Archer par défaut et prend celle de sa spé au moment du choix. La spé ne change pas en cours de partie.
- **Tours** *(réponse du projet)* : il n'existe que deux tours (canon et glace), sans amélioration. L'aperçu de pose montre l'image de la tour en transparence, verte si l'emplacement est valide, rouge sinon.
- **Déclencheurs d'impact** *(choix de Claude)* : il est permis d'ajouter au code une information « coup lourd » (coup critique ou dégâts de compétence) transmise jusqu'à la mort de l'ennemi, sans rien changer aux règles du jeu.
- **Arrêt sur image** *(choix de Claude)* : un seul nœud de jeu (créé par `main.gd`, pas d'autoload) gère tremblement et arrêt sur image ; l'arrêt ralentit tout le jeu très brièvement (vitesse du temps quasi nulle pendant la durée), deux arrêts ne s'empilent pas, et l'arrêt est ignoré pendant les écrans de choix et la défaite.
- **Couleurs des états** *(choix de Claude)* : les états gardent leurs teintes actuelles (brûle orange, trempé bleu foncé, gelé blanc glacé, marqué jaune, ralenti bleu clair, cible désignée rose-orangé). Pour éviter la confusion avec le cristal cyan, le Maître de l'eau est **bleu électrique** (`#1e6bff`) avec des touches cyan, plutôt que tout cyan.
- **Vérification** *(règle du projet)* : les planches produites sont vérifiées dans la session (images regardées) ; le jeu est vérifié par la partie de l'utilisateur, avec des captures conservées dans `production/qa/evidence/`.
- **Fichiers `.import` et `.uid`** *(règle du projet)* : jamais écrits par les agents ; l'éditeur de l'utilisateur les crée à l'ouverture et il les commite.

## 10. Ce qui est laissé au constructeur

- Taille exacte des cases des planches (de l'ordre de 128 px) et nombre d'images par seconde, tant que le résultat reste net et léger.
- Répartition du travail en étapes et en fichiers, structure du composant d'animation.
- Valeurs précises du tremblement et de l'arrêt sur image (à régler en partie).
- Réglage fin des couleurs et des proportions du cristal, des tours et des personnages, dans l'esprit de l'essai validé (le rose des socles peut être adouci vers le violet).
- Le code de l'essai de la fabrique (spike) est gardé comme référence dans `docs/superpowers/spikes/2026-11-18-sprite-baker-spike.html` (+ `-run.js`) ; il sera réécrit proprement dans `tools/sprite_baker/`.

## 11. Questions ouvertes

- Licence Quaternius à confirmer par l'utilisateur sur sa page de téléchargement.
