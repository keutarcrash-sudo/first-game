# Cartes et lisibilité — Design

> **Date** : 2026-11-20
> **Statut** : en relecture par l'utilisateur
> **Suite de** : `docs/superpowers/specs/2026-11-18-passe-graphique-1-design.md` (passe graphique 1, livrée) ; design du jeu : `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md`

---

## 1. Intention

Retours de l'utilisateur après la passe graphique 1 :

- les effets d'impact (« POW ! », « BOUM ! », tremblement) ne se voient qu'avec le Maître du feu ;
- le Maître de l'eau se voit proposer des améliorations de feu ;
- il veut des cartes qui **s'adaptent au personnage et à ses sorts**, « ce qui enrichira le jeu », la possibilité de **relancer** le tirage, un **aimant** pour l'or, une carte qui donne **4 choix** ;
- il veut voir dans l'affichage le **% de critique, la cadence de tir, la vitesse de déplacement**, etc., qui augmentent quand il prend une carte liée ;
- des cartes **commune, peu commune, rare, épique, légendaire** ;
- le terrain est **plat et sans décor**.

Ce design rend chaque build lisible et désirable : on voit ce qu'on gagne, on comprend ce que fait sa spé, on chasse les cartes rares.

## 2. Ce qui a été validé avec l'utilisateur

- Impacts propres à chaque spé (proposition acceptée telle quelle).
- Cartes par spé et par compétence, cartes communes à toutes les spés, plus de cartes « feu » pour l'Eau ou l'Archer.
- **Relance payante en or, de plus en plus chère** (option B choisie parmi : gratuite / payante / nombre limité).
- Contenu des cartes proposé (section 5), puis **cinq raretés** avec couleurs, chances qui montent au fil des vagues, une seule légendaire par partie.
- Panneau de stats.
- Décor : le terrain est plat et vide, à habiller.

## 3. Objectifs

1. Chaque spé a des impacts visibles et sonores à l'œil (onomatopées, tremblement) sur ses propres sorts.
2. Les cartes proposées viennent de la réserve **commune** + la réserve **de la spé** ; les cartes d'une compétence n'apparaissent qu'une fois la compétence débloquée.
3. Chaque carte a une **rareté** ; le tirage tient compte des raretés et de la vague ; la carte affiche sa rareté (couleur, nom).
4. Le joueur peut **relancer** le tirage contre de l'or.
5. Un **panneau de stats** montre les valeurs du héros et signale ce qui vient d'augmenter.
6. Le terrain reçoit un **décor** néon.

## 4. Non-objectifs

- Pas de magasin (étape 5 du design v2) : l'aimant arrive ici sous forme de carte.
- Pas de nouvelles spécialisations ni de nouveaux ennemis.
- Pas de rééquilibrage global des vagues (seulement les nouvelles cartes).
- Pas d'obstacles : le décor ne bloque rien.

## 5. Les cartes

### 5.1 Règles de tirage

- Réserve d'un tirage = cartes **communes** (sans `requires_spec`) + cartes **de la spé** choisie, moins les cartes épuisées (`max_stacks`), les cartes verrouillées par l'arbre (`locked_by_default` non débloquées), les cartes de compétence dont la compétence n'est pas débloquée, et les cartes dont la condition n'est pas remplie (section 5.4).
- Pour chaque emplacement proposé : on tire d'abord une **rareté** selon les poids (5.2), parmi les raretés qui ont encore au moins une carte disponible ; puis une carte au hasard de cette rareté. Pas deux fois la même carte dans une offre.
- La carte « Nouvelle compétence » (étape 3b) garde sa règle actuelle et n'a pas de rareté.
- **Une seule légendaire par partie** : une fois une légendaire prise, plus aucune légendaire n'est proposée.

### 5.2 Raretés

| Rareté | Couleur du cadre | Poids de départ | Hausse par vague après la 1re |
|---|---|---|---|
| Commune | gris `#b8b8c8` | 50 | 0 |
| Peu commune | vert `#3bff7a` | 28 | +3 % du poids de départ |
| Rare | bleu `#3b9dff` | 14 | +6 % |
| Épique | violet `#b44bff` | 6 | +10 % |
| Légendaire | orange `#ff9a1f` | 2 | +12 % |

Formule : `poids(rareté, vague) = poids_départ × (1 + hausse × (vague − 1))`. Toutes les valeurs dans un fichier de données.

### 5.3 Relance

- Bouton « Relancer (X or) » sur l'écran de choix. Elle remplace toute l'offre par un nouveau tirage.
- Coût : 20 or, puis 40, puis 60… (+20 à chaque relance) ; **le coût revient à 20 à chaque nouvel écran de choix**. Valeurs en données.
- Bouton grisé avec le prix en rouge si l'or manque.

### 5.4 Contenu

Les valeurs des cartes existantes ne changent pas, sauf mention. « ×N » = nombre maximum de fois. « (compétence) » = proposée seulement si cette compétence est débloquée.

**Communes à toutes les spés**

| Carte | Rareté | Effet |
|---|---|---|
| Canon rapide ×4 | commune | inchangé (cadence des canons +25 %) |
| Balles lourdes ×4 | commune | inchangé (dégâts +30 %) |
| Réparation | commune | inchangé (soigne 25 PV du cristal) |
| Pillage ×4 | commune | inchangé (+5 or par ennemi) |
| **Aimant** ×3 | commune | portée de ramassage de l'or +40 % |
| **Pas léger** ×3 | commune | vitesse de déplacement +10 % |
| Glace profonde ×3 | peu commune | inchangé |
| **Canons incendiaires** ×1 | peu commune | ancienne « Munitions incendiaires », renommée, effet inchangé ; reste à débloquer dans l'arbre |
| Tir brisant ×1 | rare | inchangé (combo glace + héros) ; reste à débloquer dans l'arbre |
| **Plus de choix** ×1 | rare | 4 cartes proposées au lieu de 3 (s'ajoute au bonus de l'arbre) |
| **Collectionneur** ×1 | épique | portée de ramassage ×2 et l'or reste 15 s au sol au lieu de 10 |

**Archer**

| Carte | Rareté | Effet |
|---|---|---|
| Œil de faucon ×4 | commune | inchangé (critique +10 %) |
| Marque prolongée ×3 | commune | inchangé (+2 s) |
| Carquois profond ×3 | peu commune | inchangé (+1 ennemi traversé) |
| Flèche lourde ×3 | peu commune | inchangé (multiplicateur de critique +0,5) |
| **Esquive** ×2 (Roulade) | peu commune | recharge de la Roulade −30 % |
| **Pointe d'acier** ×2 (Flèche perforante) | rare | dégâts de la Flèche perforante +50 % |
| **Déluge** ×2 (Pluie de flèches) | rare | zone +30 % et durée +1 s |
| **Regard perçant** ×1 (Œil du chasseur) | rare | durée +3 s |
| **Tir en rafale** ×1 | épique | chaque coup critique a 30 % de chance de tirer aussitôt une seconde flèche |
| **Flèches fantômes** ×1 | légendaire | les flèches normales traversent tous les ennemis |

**Maître du feu**

| Carte | Rareté | Effet |
|---|---|---|
| Braises ardentes ×4 | commune | inchangé (+2 dégâts/s de brûlure) |
| Longue combustion ×3 | commune | inchangé (+1 s) |
| Cadence infernale ×4 | peu commune | inchangé (cadence +20 %) |
| **Grosse boule** ×2 (Boule de feu) | peu commune | rayon d'explosion +30 % |
| **Traînée ardente** ×2 (Bond enflammé) | peu commune | traînée +2 s |
| **Frappe du brasier** ×1 | rare | inchangé (combo feu + héros) ; devient une carte du Maître du feu, sans déblocage dans l'arbre |
| **Rempart de flammes** ×2 (Mur de feu) | rare | longueur +50 % |
| **Apocalypse** ×1 (Météore) | rare | dégâts +50 % |
| **Combustion** ×1 | épique | les ennemis qui brûlent subissent +25 % de dégâts de toutes les sources |
| **Brasier éternel** ×1 | légendaire | un ennemi qui meurt en brûlant enflamme les ennemis à moins de 80 px |

**Maître de l'eau**

| Carte | Rareté | Effet |
|---|---|---|
| **Jet puissant** ×3 | commune | dégâts **du héros seulement** +25 % (corrigé : ne renforce plus les canons) |
| Trempage durable ×3 | commune | inchangé (+2 s) |
| Gel profond ×3 | peu commune | inchangé (+1 s) |
| Marée ×4 | peu commune | inchangé (cadence +20 %) |
| **Lame de fond** ×2 (Vague) | peu commune | portée et recul +40 % |
| **Glisse** ×2 (Glissade) | peu commune | recharge −30 % |
| **Grande flaque** ×2 (Flaque) | rare | taille +30 % |
| **Grand froid** ×1 (Raz-de-marée) | rare | gel +1 s |
| **Marée montante** ×1 | épique | un ennemi trempé est ralenti de 25 % tant qu'il est trempé |
| **Zéro absolu** ×1 | légendaire | un ennemi gelé qui meurt explose : 20 dégâts et gel 1 s aux ennemis à moins de 60 px |

Les bonus de même type s'additionnent (ex. deux Esquive = −60 % de recharge, plafonné à −75 %).

### 5.5 Affichage des cartes

- Cadre et nom de rareté (« RARE », « LÉGENDAIRE ») dans la couleur de la rareté, en lettres de BD.
- Légendaire : cadre lumineux qui pulse, éclats, et le mot « LÉGENDAIRE ! » quand elle apparaît.
- Une carte de compétence affiche le nom de la compétence et sa touche (« Vague — clic droit »).

## 6. Panneau de stats

- Petit panneau dans l'affichage, en haut à droite, visible en préparation et en combat, chiffres en Bungee.
- Lignes : dégâts (multiplicateur), cadence de tir (tirs/s), vitesse de déplacement, portée de ramassage ; pour l'Archer critique (chance %, multiplicateur) et ennemis traversés ; pour le Feu brûlure (dégâts/s, durée) ; pour l'Eau trempé (durée) et gel (durée).
- Les valeurs sont celles réellement utilisées par le jeu (cartes comprises).
- Une valeur qui vient d'augmenter s'affiche en vert avec « ▲ » pendant 4 s.

## 7. Impacts par spé

Les onomatopées utilisent l'effet « étoile pop » existant (`PopBurst`).

| Spé | Sort | Onomatopée | Tremblement | Arrêt sur image |
|---|---|---|---|---|
| Archer | Flèche perforante (au lancement, devant le héros) | « TCHAK ! » | petit | — |
| Archer | Pluie de flèches (au centre de la zone) | « ZIP ZIP ! » | petit | — |
| Archer | Œil du chasseur | « FOCUS ! » au-dessus du héros | — | — |
| Feu | Boule de feu / Météore | inchangé (« POW ! » / « BOUM ! ») | inchangé | inchangé |
| Feu | Mur de feu | « FWOOSH ! » | petit | — |
| Eau | Vague | « SPLASH ! » | petit | — |
| Eau | Flaque | « PLOUF ! » | — | — |
| Eau | Raz-de-marée | « SPLOOSH ! » | grand | oui |

- Tremblement « petit » porté de 4 à **6 px** pour être perceptible.
- Mort par coup lourd (critique ou compétence) : inchangé (petit tremblement + arrêt sur image), mais au plus un arrêt sur image toutes les 0,25 s pour éviter les enchaînements (pluie de flèches).

## 8. Décor

- Pièces du pack Kenney déjà fourni (rochers, arbres, cristaux, souches), recolorées néon par la fabrique d'images, en 1 direction, 2 ou 3 variantes chacune.
- Posées au hasard **une fois par partie** sur tout le terrain, avec une densité en données (environ 40 pièces sur 2400×1600), espacées entre elles et loin du point de départ du cristal.
- **Purement visuel** : rien n'est bloqué. Pendant une vague, les pièces qui touchent le trajet de cette vague (à moins de 70 px de la ligne) sont cachées pour garder le trajet lisible.
- Dessinées au-dessus du sol et sous le trajet.

## 8bis. Précisions (relecture du design)

- **Compétence débloquée** *(réponse du projet)* : la compétence du clic droit est débloquée dès le départ ; A, E, R le sont quand le joueur prend la carte « Nouvelle compétence » (étape 3b). Une carte de compétence n'entre dans la réserve qu'à ce moment.
- **Offre incomplète** *(choix de Claude)* : s'il reste moins de cartes disponibles que d'emplacements, l'offre en montre moins. La carte « Nouvelle compétence » garde sa règle actuelle (elle prend une place de l'offre). La relance reste possible tant qu'il reste au moins une carte à tirer.
- **Tirage** *(choix de Claude)* : la rareté est tirée pour chaque emplacement, indépendamment ; plusieurs cartes d'une même rareté sont donc possibles. « Une seule légendaire par partie » = une légendaire **prise** ; une légendaire seulement montrée peut revenir.
- **Cumuls** *(choix de Claude)* : Combustion s'applique à toutes les sources de dégâts, brûlure comprise, et se multiplie avec les combos existants. Tir en rafale : la seconde flèche peut être critique mais ne déclenche jamais elle-même de rafale. Ralentissements : le plus fort l'emporte (règle actuelle des tours de glace), Marée montante compris. Réductions de recharge plafonnées à −75 %.
- **Mort des ennemis** *(réponse du projet)* : le signal `died` existe déjà et transporte assez d'informations pour Brasier éternel et Zéro absolu (position, état brûle / gelé au moment de la mort) ; au besoin le constructeur peut l'enrichir sans changer les règles.
- **Source unique des stats** *(choix de Claude)* : le panneau et le jeu lisent la même valeur ; une petite refonte pour exposer des lectures de stats (vitesse, portée de ramassage, cadence, critique…) est permise.
- **Dégâts** *(choix de Claude)* : `damage_bonus` est séparé en bonus « héros » et bonus « général ». Balles lourdes reste générale (héros et canons), Jet puissant devient héros seulement. Aucune sauvegarde ne stocke les cartes (elles ne vivent que pendant une partie).
- **Relance et or** *(choix de Claude)* : la relance prend le même or que les tours ; l'or ne devient jamais négatif. L'écran de choix des cartes s'ouvre entre la fin d'une vague et la préparation, comme aujourd'hui.
- **Trajet et décor** *(réponse du projet)* : le trajet d'une vague est une ligne brisée (`CrystalPath.points`), connue dès la préparation ; la fabrique d'images (`tools/sprite_baker/`) existe et recolore les pièces Kenney par recette.
- **Valeurs des compétences** *(choix de Claude)* : les compétences lisent leurs bonus de cartes au moment du lancement.
- **Plus de choix** *(choix de Claude)* : +1 s'ajoute au bonus de l'arbre (3 + arbre + 1).

## 9. Contraintes

- Godot 4.7.2, Compatibility, export web ; mêmes règles de code que le projet (données JSON validées, interface en code, pas d'autoload, pas de `.uid`/`.import` écrits par les agents).
- Toutes les valeurs (raretés, poids, coûts de relance, effets, impacts, décor) en fichiers de données.
- Aucune règle existante ne change, sauf : Jet puissant (héros seulement), Munitions incendiaires renommée, Frappe du brasier déplacée dans les cartes du Feu, tremblement « petit » 6 px, arrêt sur image espacé de 0,25 s.

## 10. Approches envisagées

Le seul vrai choix de construction a été fait avec l'utilisateur : la relance (gratuite, payante ou limitée → payante). Pour le reste, une seule voie sensée : prolonger le système de cartes existant (`cards.json`, `CardCatalog`, `CardPool`, `PlayerModifiers`) plutôt que d'en créer un second, et réutiliser la fabrique d'images et `PopBurst`.

## 11. Ce qui est laissé au constructeur

- Disposition exacte du panneau de stats et de l'écran de choix (bouton de relance, cadres de rareté), dans le style néon pop.
- Noms des nouveaux types d'effet dans `cards.json` et leur branchement dans `PlayerModifiers` et les compétences.
- Choix et nombre exact des pièces de décor Kenney, dans la limite de la section 8.

## 12. Questions ouvertes

Aucune.
