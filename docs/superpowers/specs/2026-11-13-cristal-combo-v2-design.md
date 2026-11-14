# Cristal Combo v2 — Design

> **Date** : 2026-11-13
> **Statut** : approuvé par l'utilisateur le 2026-11-13
> **Remplace** : le concept « arène fixe + tours permanentes » du MVP (`design/game-brief.md`)
> **Inspirations** : Deadlock et Overwatch (skill, focus, escorte), Ember Knights (mondes, carte, mode sans fin), Clover Pit (fins multiples)

---

## 1. Vision

Un jeu de défense en vue de dessus, 2D, navigateur. Le joueur escorte un **cristal qui avance** à travers 4 mondes. À chaque vague, il pose des **tours temporaires** le long du trajet du cristal, puis se bat avec son héros.

Le skill se joue sur deux axes :

- **Game sense et build** : lire la menace, placer ses tours, choisir son chemin sur la carte, décider où va l'or (tours pour cette vague, ou objets pour toute la partie), monter des combos.
- **Aim et réflexes** : viser, désigner les bonnes cibles, esquiver les attaques annoncées, aller ramasser l'or sans laisser le cristal mourir.

Un mauvais build perd. Un build malin et bien joué mène à une « god run ».

Ce qui ne change pas : vue de dessus uniquement (ni 1re ni 3e personne), clavier et souris (ZQSD + souris), parties courtes, combos entre effets (procs).

---

## 2. Structure d'une partie

1. **Départ** : choix de la spécialisation (écran actuel). Le cristal part du début du monde 1.
2. **Un monde = une carte à embranchements** d'environ 6 à 8 étapes (réglable). À chaque étape, le joueur choisit entre 2 ou 3 lieux :

   | Lieu | Contenu |
   |---|---|
   | Vague | Combat normal (section 3) |
   | Magasin | Achat d'objets passifs et actifs (section 4) |
   | Trésor | Récompense gratuite, au choix parmi plusieurs |
   | Repos | Soin du héros et/ou du cristal |
   | Mini-boss | Vague avec un mini-boss, risquée, grosse récompense |

   Chaque lieu annonce ce qu'il contient avant d'être choisi.
3. **Fin d'un monde** : le boss du monde, puis passage au monde suivant (nouveaux décors, nouveaux ennemis).
4. **Arrivée**, après le boss du monde 4 : la fin dépend de l'état du cristal et des fragments cachés (section 6). Certaines fins ouvrent le **monde 5 caché**.
5. **Défaite** : le héros **ou** le cristal tombe à 0 PV. Écran de défaite et arbre de déblocages, comme aujourd'hui.
6. **Mode sans fin** : débloqué après la première victoire (section 6).

**Durée visée** : à fixer à l'équilibrage, une fois le monde 1 jouable. Ordre de grandeur : un monde = 8 à 12 minutes.

---

## 3. Déroulé d'une vague

### 3.1 Préparation (sans minuteur)

- Le **trajet du cristal** s'affiche : une ligne du départ à l'arrivée de la vague.
- Un **aperçu des ennemis** donne **les types et le nombre** de chaque type, sans dire d'où ils arrivent.
- Le joueur **place ses tours** le long du trajet avec son or. Pour commencer : canon et glace, les tours actuelles.
- **Espace** lance la vague.

### 3.2 Combat

- **Le cristal avance tout seul**, à vitesse régulière (données), le long du trajet. Il ne s'arrête pas.
- **La caméra suit le héros.** Le terrain d'une vague peut être plus grand que l'écran. Quand le cristal sort de l'écran, une flèche au bord de l'écran indique où il est, avec ses PV.
- **Les ennemis** apparaissent pendant la vague et visent tous le cristal. Aucun ne traque le héros.
- **Le héros** :

  | Commande | Effet |
  |---|---|
  | ZQSD | Se déplacer |
  | Souris | Viser : l'arme tire seule vers la souris |
  | Clic gauche | **Désigner** une cible |
  | Clic droit | Compétence principale de la spé |
  | A | Deuxième compétence de la spé |
  | E | Troisième compétence de la spé |
  | R | Ultime de la spé (longue recharge) |
  | 1, 2 | Objets actifs |

- **Désignation** : clic gauche sur un ennemi. Les tours à portée le visent en priorité jusqu'à sa mort, puis reprennent leur cible par défaut. **Pas de limite ni de temps de recharge** : la limite, c'est la puissance de feu des tours et l'attention du joueur. Une seule cible désignée à la fois ; un nouveau clic remplace l'ancienne.
- **Cible par défaut des tours** : l'ennemi le plus proche (comme aujourd'hui).
- **L'or** tombe des ennemis tués et **disparaît** au bout d'un temps donné (environ 10 s, données). Le héros le ramasse en passant dans sa **portée de ramassage** (statistique améliorable : objets « aimant »).
- **Dangers pour le héros** : zones annoncées au sol, tirs chargés, explosions des kamikazes près du cristal. Le héros n'est pas invincible.

### 3.3 Fin de vague

- La vague se termine quand **le cristal arrive au bout de son trajet**. Les ennemis encore vivants s'enfuient ; l'or qu'ils auraient lâché est perdu. L'or encore au sol est perdu aussi.
- **Les tours disparaissent.**
- **L'or non dépensé est conservé.** Le joueur peut économiser.
- **Choix d'une carte parmi 3** (système actuel).
- **Déblocage des compétences** : la partie commence avec le seul clic droit. Certains choix de fin de vague proposent à la place la compétence suivante (A, puis E, puis R). Moments par défaut : après la vague 2, la vague 4 et le premier boss (données).

### 3.4 Ce qui grandit d'une vague à l'autre

- La **longueur du trajet**.
- Le **nombre d'ennemis**.
- L'**or** lâché.

Chaque vague demande donc une ligne de tours plus longue, pour plus d'ennemis, avec plus d'or. Le joueur voit sa puissance grandir à l'écran même si les tours sont perdues.

---

### 3.5 Compétences actives des spécialisations (validé le 2026-11-14)

| Spé | Clic droit | A | E | R (ultime) |
|---|---|---|---|---|
| Archer | **Flèche perforante** : ligne droite qui traverse tout, dégâts ×3, marque les ennemis touchés (6 s) | **Roulade** : saut dans la direction du mouvement, la flèche suivante est critique (5 s) | **Pluie de flèches** : zone sous la souris criblée 3 s (12 s) | **Œil du chasseur** : 8 s, ennemis à l'écran marqués, tous les tirs critiques (60 s) |
| Maître du feu | **Boule de feu** : explose en zone et enflamme (5 s) | **Bond enflammé** : saut qui laisse une traînée de flammes (6 s) | **Mur de feu** : ligne de flammes 4 s qui enflamme ceux qui la traversent (12 s) | **Météore** : énorme explosion sous la souris après 1 s d'annonce (60 s) |
| Maître de l'eau | **Vague** : cône devant le héros qui repousse et trempe (6 s) | **Glissade** : saut qui trempe les ennemis sur le passage (6 s) | **Flaque** : zone 5 s qui trempe et ralentit ; près d'une tour de glace, gèle (12 s) | **Raz-de-marée** : ennemis à l'écran trempés puis gelés 2 s (60 s) |

Recharges entre parenthèses (données). Déblocage pendant la partie : clic droit dès le départ ; A, E puis R proposés comme choix de fin de vague après les vagues 2, 4 et 6 (le R passera après le premier boss quand les boss existeront). Construction en deux morceaux : **3a** (système, affichage des touches et recharges, clic droit des 3 spés) puis **3b** (A, E, R et leur déblocage).

## 4. Économie et progression pendant une partie

### 4.1 L'or

Seule monnaie pendant la partie. Ramassé au sol (section 3.2). Il paie :

- les **tours**, valables une seule vague ;
- les achats au **magasin**.

C'est le dilemme central : investir dans la vague (tours) ou dans la partie (objets).

### 4.2 Le magasin

Sélection au hasard, renouvelée à chaque visite. Trois catégories :

| Catégorie | Exemples |
|---|---|
| Attaque | Dégâts, cadence, critique, effets élémentaires |
| Survie | PV du héros, soin, réduction des dégâts d'explosion, soin ou bouclier du cristal |
| Utilité | Aimant (portée de ramassage), vitesse, tours moins chères ou plus fortes |

- Objets **passifs** : pas de limite de nombre.
- Objets **actifs** (dash, bombe, bouclier du cristal…) : **2 emplacements** (touches 1 et 2).

### 4.3 Les cartes

Choix d'une carte parmi 3 en fin de vague : améliorations des compétences de la spé, combos (système de procs actuel), déblocage de la compétence suivante.

### 4.4 Les PV

- **Héros** : ses PV se gèrent sur toute la partie. Soins par le lieu de repos, les objets de survie et certaines compétences de spé. Pas de soin automatique entre les vagues.
- **Cristal** : ses dégâts restent d'une vague à l'autre. Soins par le repos, des objets et certaines compétences. Son état à l'arrivée décide de la fin.

---

## 5. Ennemis et boss

### 5.1 Familles d'ennemis

Tous visent le cristal ; chacun demande une réponse différente.

| Ennemi | Comportement | Ce qu'il teste |
|---|---|---|
| Coureur | Fonce sur le cristal | La base |
| Rapide | Petit, zigzague | L'aim |
| Tank | Lent, énormément de PV | La désignation |
| Bouclier | Protégé de face, vulnérable de dos ou sur un point faible | Le placement |
| Kamikaze | Explose au contact du cristal, blesse le héros autour | Les réflexes |
| Artilleur | S'arrête à distance, tir chargé annoncé par un cercle au sol | L'esquive et la priorité de cible |

Chaque monde introduit 1 ou 2 nouveaux types et son ambiance visuelle. Toutes les attaques qui touchent le héros sont **annoncées** avant de frapper (cercle, ligne, charge visible).

### 5.2 Mini-boss

Un par monde, dans un lieu « Mini-boss » de la carte. Gros ennemi avec 1 ou 2 attaques annoncées.

### 5.3 Boss

Un par monde, plus celui du monde caché. Il attaque le cristal **pendant qu'il avance**, avec des attaques de zone annoncées qui touchent aussi le héros. Plusieurs phases : ses attaques changent quand ses PV baissent.

---

## 6. Fins, monde caché et mode sans fin

### 6.1 État du cristal à l'arrivée

| État | PV restants (seuils en données) |
|---|---|
| Intact | 80 % et plus |
| Abîmé | De 30 à 80 % |
| De justesse | Moins de 30 % |

### 6.2 Fragments cachés

Un fragment par monde, caché dans certaines vagues : un ennemi rare à tuer ou un objet à récupérer hors du trajet (donc loin du cristal).

### 6.3 Fins

| À l'arrivée | Résultat |
|---|---|
| Cristal intact + 4 fragments | Ouvre le **monde 5 caché** (boss caché, fin secrète) |
| Autres combinaisons | Fins différentes, plus ou moins de points pour l'arbre |

La liste exacte des fins et leurs textes seront écrits à l'étape 7.

### 6.4 Mode sans fin

Débloqué après la première victoire. Les mondes s'enchaînent en boucle, de plus en plus durs. Un record (distance ou nombre de vagues) est enregistré.

---

## 7. Entre les parties : l'arbre de déblocages

L'arbre et la sauvegarde actuels sont conservés. À la fin de chaque partie, gagnée ou perdue, le joueur reçoit des points. Les meilleures fins et le monde caché en rapportent plus. Ils débloquent :

- de nouvelles spécialisations ;
- de nouvelles cartes et de nouveaux objets (qui rejoignent le magasin) ;
- de petits bonus de départ.

---

## 8. Direction artistique

En deux temps :

1. **Formes simples et lumières fortes** pendant toute la construction : formes géométriques nettes, fond sombre, effets lumineux (cristal, sorts, combos, attaques annoncées). Lisible en combat, faisable par le code.
2. **Habillage façon Deadlock**, monde par monde, une fois le jeu bon : style peint, sombre, élégant, rétro-futuriste.

Règle de lisibilité, dès le début : les attaques annoncées, l'or au sol et la cible désignée doivent se repérer d'un coup d'œil, même avec beaucoup d'ennemis.

---

## 9. Plan de construction

On transforme le jeu existant par étapes. Chaque étape est jouable et testée par l'utilisateur avant la suivante.

| Étape | Contenu | Ce qu'on teste |
|---|---|---|
| 1. Le cristal qui avance | Trajet, préparation (trajet visible + aperçu types et nombre), tours par vague, fin de vague à l'arrivée | Le nouveau cœur est-il fun ? |
| 2. Or au sol et désignation | Or qui tombe et disparaît, portée de ramassage, clic gauche | Le dilemme or / cristal, le focus |
| 3. Compétences actives | Clic droit, A, E, R pour l'Archer, le Maître du feu et le Maître de l'eau | Le skill d'adresse |
| 4. Danger pour le héros | PV du héros, défaite du héros, kamikazes, artilleurs, zones annoncées, soins | L'esquive |
| 5. Carte du monde | Embranchements, magasin, trésor, repos | Les choix de chemin et le build |
| 6. Mini-boss et boss du monde 1 | **Monde 1 complet** | Une vraie partie du monde 1 |
| 7. Suite | Fins et fragments, mondes 2 à 4, monde caché, mode sans fin, nouvelles spés, habillage visuel | — |

### 9.1 Ce qu'on garde

- Combos (`src/procs/`, `procs.json`)
- Cartes (`src/cards/`, `cards.json`)
- Spécialisations Archer, Maître du feu, Maître de l'eau (`src/specs/`)
- Arbre de déblocages, sauvegarde, écran de défaite (`src/meta/`)
- Tours canon et glace
- Règles de code actuelles : valeurs dans des fichiers de données, interface construite en code, injection de dépendances

### 9.2 Ce qui change

| Avant | Après |
|---|---|
| Cristal immobile au centre | Cristal qui avance sur un trajet |
| Arène fixe | Trajet par vague, dans un monde à étapes |
| Tours permanentes | Tours valables une vague |
| Or automatique | Or ramassé au sol |
| Défaite si le cristal meurt | Défaite si le cristal **ou** le héros meurt |
| Vagues à la suite | Carte à embranchements avec lieux |

### 9.3 Stories et brief

- Les **stories 010 à 013** sont mises en pause. Les spés Terre, Vent, Temps, Gardien, Berserker et Piégeur reviennent à l'étape 7, adaptées au nouveau jeu (compétences actives, tours temporaires). L'équilibrage est refait sur la nouvelle formule.
- Le **brief** (`design/game-brief.md`) est réécrit pour décrire ce concept.
- Le **plan détaillé de l'étape 1** est écrit ensuite (writing-plans), puis découpé en stories.

---

## 10. Questions ouvertes

À trancher au moment de l'étape concernée :

- Taille du terrain d'une vague (la caméra suit le héros : décidé) — **étape 1**.
- Pendant la préparation, comment voir tout le trajet si le terrain dépasse l'écran (vue dézoomée, ou déplacement libre de la caméra) — **étape 1**.
- Prix et nombre des tours, nouveaux types de tours — étapes 1 et 7.
- Contenu exact des compétences A, E, R de chaque spé — étape 3.
- Ce que donnent le trésor et le repos, en chiffres — étape 5.
- Le choix de carte en fin de vague reste-t-il après chaque vague, ou devient-il un lieu de la carte ? — étape 5.
- Textes et récompenses de chaque fin — étape 7.
