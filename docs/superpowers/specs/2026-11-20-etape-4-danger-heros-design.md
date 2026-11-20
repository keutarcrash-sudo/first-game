# Étape 4 — Danger pour le héros : Design

> **Date** : 2026-11-20
> **Statut** : en relecture par l'utilisateur
> **Design du jeu** : `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md` (sections 5.1, 4.4, 9 étape 4)

---

## 1. Intention

Le héros ne risque encore rien : les compétences de saut, le placement et l'esquive n'ont pas d'enjeu. L'étape 4 rend le héros vulnérable aux **zones annoncées** (jamais traqué : tous les ennemis visent le cristal), ajoute deux ennemis qui créent ce danger, et des cartes de survie. Objectif « skill » du design : un bon joueur peut tout esquiver.

## 2. Ce qui a été validé avec l'utilisateur

- Défaite si le héros tombe à 0 PV (design v2).
- **Option A** : les sauts rendent invincible pendant leur durée, et 0,5 s d'invincibilité après chaque coup (parmi : invincibilité sauts + après coup / après coup seulement / aucune).
- Proposition complète acceptée telle quelle : valeurs, kamikaze (zombie néon), artilleur (soucoupe néon), cartes de soin, ennemis décrits en données.

## 3. Objectifs

1. PV du héros, barre de PV, retour visuel des coups, invincibilité (sauts, après coup), défaite à 0 PV.
2. Kamikaze et artilleur, avec attaques **annoncées au sol** avant de frapper.
3. Types d'ennemis décrits dans un fichier de données, pour ajouter facilement tank, rapide, bouclier plus tard.
4. Cartes de soin et de survie ; panneau de stats complété.

## 4. Non-objectifs

- Pas d'ennemi qui traque le héros. Pas de tank, rapide, bouclier (plus tard, en données).
- Pas de magasin, de lieu de repos ni de carte du monde (étape 5).
- Pas de nouvelles spécialisations.
- Les ennemis existants (gobelins) gardent exactement leurs règles.

## 5. Le héros

| Élément | Valeur |
|---|---|
| PV de départ | 100 (données) |
| Invincibilité après un coup | 0,5 s, le héros clignote |
| Invincibilité pendant un saut | toute la durée du saut (Roulade, Bond enflammé, Glissade) |
| Retour visuel d'un coup | flash rouge sur le héros + tremblement « petit » |
| 0 PV | animation de mort du héros, puis même écran de défaite que la destruction du cristal (points, arbre, rejouer) |
| Soin automatique | aucun, ni pendant ni entre les vagues |

- Barre de PV du héros dans l'affichage, à côté de celle du cristal, même style néon.
- Les points de fin de partie se calculent comme aujourd'hui, quelle que soit la cause de la défaite.

## 6. Les nouveaux ennemis

Tous visent le cristal. Valeurs dans les données.

### 6.1 Kamikaze (zombie néon)

| Élément | Valeur |
|---|---|
| Apparition | à partir de la vague 3 : 1 à la vague 3, +1 par vague ensuite, **en plus** des gobelins |
| PV | 0,6 × PV d'un gobelin de la même vague |
| Vitesse | 1,4 × vitesse d'un gobelin |
| Au contact du cristal | il s'arrête, clignote rouge, un cercle rouge de 90 px apparaît et se remplit en 0,6 s, puis il explose |
| Explosion | 20 dégâts au cristal ; 25 dégâts au héros s'il est dans le cercle ; le kamikaze disparaît sans lâcher d'or |
| Tué avant d'exploser | meurt normalement (or, combos, effets de cartes), pas d'explosion |

### 6.2 Artilleur (soucoupe néon)

| Élément | Valeur |
|---|---|
| Apparition | à partir de la vague 5 : 1 à la vague 5, +1 toutes les 2 vagues, en plus des autres |
| PV | 1,5 × PV d'un gobelin |
| Vitesse | 0,8 × vitesse d'un gobelin |
| Comportement | avance vers le cristal et s'arrête à 350 px de lui ; suit le cristal à cette distance |
| Tir | toutes les 3 s : un cercle rouge de 70 px se remplit en 1,2 s à une position tirée au hasard à moins de 60 px du cristal, puis frappe |
| Impact | 10 dégâts au cristal s'il est dans le cercle ; 20 dégâts au héros s'il est dedans |
| Mort | normale (or, combos, effets de cartes) |

### 6.3 Attaques annoncées

- Cercle rouge translucide au sol avec contour, qui se remplit du centre vers le bord pendant l'annonce ; au moment de l'impact, flash et onomatopée (« BAM ! » pour l'artilleur, « KABOUM ! » pour le kamikaze) avec l'étoile pop existante ; tremblement « petit » (kamikaze : « grand » si le héros est touché).
- Les annonces restent lisibles par-dessus le décor et le trajet, sous les personnages.
- Fin de vague : les annonces en cours disparaissent sans frapper.

### 6.4 Apparence

Zombie néon (`Zombie_Male` du pack Quaternius, palette du design graphique) pour le kamikaze, soucoupe Kenney (`enemy-ufo-*`, recolorée néon) pour l'artilleur, produits par la fabrique d'images (8 directions ; la soucoupe peut n'avoir qu'une direction et tourner sur elle-même).

## 7. Cartes de survie

| Carte | Rareté | Effet |
|---|---|---|
| Bandage (illimitée) | commune | soigne le héros de 30 PV |
| Peau dure ×3 | peu commune | +25 PV maximum, et soigne d'autant |
| Régénération ×1 | rare | +1 PV par seconde pendant les vagues |
| Vampirisme ×1 | épique | 1 PV rendu à chaque ennemi tué |

Communes à toutes les spés. Le panneau de stats affiche les PV maximum et la régénération (si > 0).

## 7bis. Précisions (relecture du design)

- **Mort du héros** *(réponse du projet)* : les planches des héros ont déjà une animation `death`. À 0 PV, la vague s'arrête (plus d'apparitions, ennemis immobiles), l'animation de mort joue (environ 0,8 s), puis le jeu se met en pause et l'écran de défaite s'ouvre comme aujourd'hui.
- **Cercles** *(choix de Claude)* : 90 px et 70 px sont des **rayons**. Le héros est touché si son corps (rayon du héros) chevauche le cercle.
- **Tir de l'artilleur** *(choix de Claude)* : le cercle vise la position que le cristal aura **au moment de l'impact** (le long de son trajet, 1,2 s plus loin), à ±60 px près, pour que le cristal puisse vraiment être touché ; le cristal prend les 10 dégâts si son centre est dans le cercle.
- **Explosion du kamikaze** *(choix de Claude)* : les 20 dégâts au cristal sont toujours appliqués (il est au contact) ; seuls les dégâts au héros dépendent du cercle.
- **États pendant la mèche** *(choix de Claude)* : un kamikaze gelé ou repoussé pendant ses 0,6 s explose quand même à la fin, là où il se trouve ; le cercle le suit ; le tuer pendant la mèche annule l'explosion.
- **Apparence** *(réponse du projet)* : `Zombie_Male.glb` et `enemy-ufo-a…d.glb` sont déjà dans `assets/models/source/` ; la fabrique d'images produit le zombie en 8 directions avec ses animations du pack ; pour la soucoupe (modèle fixe), la fabrique fabrique des animations simples : `run` = la soucoupe qui tourne sur elle-même et oscille, `hit` = légère secousse, `death` = rétrécit en tournant.
- **Stats de base** *(choix de Claude)* : `defence_stats.json` reste la référence du gobelin ; le fichier des types d'ennemis donne des multiplicateurs par rapport à lui.
- **Sauts** *(réponse du projet)* : Roulade, Bond enflammé et Glissade passent tous par `Hero.dash()` ; l'invincibilité suit `Hero.is_dashing()`.
- **Numérotation** : vagues à partir de 1 ; les ennemis en plus sont répartis dans la même fenêtre d'apparition que les gobelins.

## 8. Approches envisagées

| Approche | Pour | Contre |
|---|---|---|
| **Types d'ennemis en données (choisie)** : un fichier décrit chaque type (PV, vitesse, apparence, comportement : « foncer », « exploser au contact », « tirer à distance ») ; la classe `Enemy` existante lit son type ; les comportements particuliers sont de petits composants | Ajouter un type = données + modèle ; une seule classe à maintenir ; les combos et états marchent pour tous | La classe `Enemy` grossit un peu |
| Une classe par type d'ennemi (héritage) | Code de chaque type isolé | Duplication des états et combos ; plus de travail à chaque nouveau type |

## 9. Contraintes

- Règles du projet : données JSON validées, interface en code, pas d'autoload, pas de `.uid`/`.import` écrits par les agents ; Godot 4.7.2, export web.
- Les gobelins et tout le reste du jeu gardent exactement leurs règles actuelles.
- Les ennemis libérés (`is_queued_for_deletion()`) sont ignorés par toutes les nouvelles attaques ; l'arrivée du cristal efface ennemis et annonces sans dégâts.
- Pas d'attaque sans annonce visible.

## 10. Ce qui est laissé au constructeur

- Organisation des composants de comportement et du fichier de types d'ennemis.
- Disposition de la barre de PV du héros, dans le style néon.
- Réglage visuel des cercles d'annonce (épaisseur, couleurs) dans l'esprit de la maquette néon pop.

## 11. Questions ouvertes

Aucune.
