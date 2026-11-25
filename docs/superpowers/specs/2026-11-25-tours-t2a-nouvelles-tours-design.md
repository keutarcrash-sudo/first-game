# Tours T2a — Quatre nouvelles tours débloquables : Design

> **Date** : 2026-11-25
> **Statut** : en relecture par l'utilisateur
> **Suit** : `docs/superpowers/specs/2026-11-25-tours-t1-reserve-design.md` (réserve, branches, glace de soutien — fait et validé en jeu)

---

## 1. Intention

Le joueur veut des parties « god run » où **tout se combine** (tours, compétences, cartes, objets) et où **chaque partie est différente**. Le T2a ajoute quatre tours aux rôles bien distincts, qui se **débloquent pendant la partie** (comme les armes de Vampire Survivors), et qui jouent avec les états des ennemis (brûlé, trempé, gelé, ralenti) pour créer des combos entre tours.

Le chantier T2 est découpé :
- **T2a** (ce document) : les 4 tours, leurs branches, les cartes « Plans » qui les débloquent, et un système de tours générique ;
- **T2b** : les 12 évolutions, deux par type de tour, une par branche (tour niveau 3 + carte ou objet précis).

## 2. Ce qui a été validé avec l'utilisateur

- **Déblocage pendant la partie (B)**. Au départ, seuls le canon et la glace sont disponibles ; les autres tours arrivent par des cartes « Plans : … » ou par le trésor. (Autres options écartées : tout achetable dès le début ; déblocage permanent par l'arbre. Un futur arbre pourra permettre de *commencer* avec une tour au choix.)
- **Évolutions : tour niveau 3 + carte ou objet (A)**, **une par branche**, soit 12 en tout. Elles sont faites au T2b.
- **Découpage T2a puis T2b**, avec un test entre les deux.
- **Approche 1 : système de tours générique**. Les tours viennent des données, chacune a un petit comportement, et la réserve, le placement, les boutons et le panneau marchent pour toutes.
- Proposition des 4 tours acceptée (rôles, prix, branches, combos), avec les valeurs ci-dessous.

## 3. Objectifs

1. Un système de tours générique : ajouter une tour = des données + un comportement. Le canon et la glace passent dans ce système sans changer pour le joueur.
2. Quatre nouvelles tours (Tesla, Lance-flammes, Mortier, Amplificateur), chacune avec deux branches au niveau 2 et un renfort au niveau 3.
3. Quatre cartes « Plans » qui débloquent ces tours pour la partie ; le trésor peut aussi proposer un plan.
4. Les combos entre tours passent par les états des ennemis (§5).

## 4. Non-objectifs

- Pas d'évolutions (T2b), pas de tours attaquables (T3), pas de refonte de l'arbre de compétences.
- Les règles du T1 ne changent pas : réserve, prix croissants, retour à la fin de vague, panneau, gel et vulnérabilité des gelés.
- Pas de nouveaux modèles 3D téléchargés : les apparences sont faites avec les pièces Kenney déjà présentes et des formes faites par la fabrique d'images.

## 5. Les quatre tours

Prix d'achat : la base ci-dessous, puis **+25 par tour de ce type déjà possédée** (règle du T1). Améliorations : 80 (niveau 2, choix de branche) et 150 (niveau 3), comme au T1.

### 5.1 Tesla — 70 d'or
| Élément | Valeur |
|---|---|
| Base | toutes les 1,2 s, un éclair de 12 dégâts frappe l'ennemi le plus proche (portée 220) puis **rebondit sur 3 ennemis** (chaque saut jusqu'à 120 px) |
| Combo | **×2 sur les ennemis trempés** |
| **Surtension** (branche A) | niv. 2 : 6 rebonds et ×3 sur les trempés · niv. 3 : 10 rebonds |
| **Arc** (branche B) | niv. 2 : portée 300 et l'éclair **étourdit 0,3 s** · niv. 3 : étourdit 0,6 s et +50 % de dégâts |

### 5.2 Lance-flammes — 60 d'or
| Élément | Valeur |
|---|---|
| Base | cône de feu continu (portée 140, ouverture 60°) devant la tour, tourné vers l'ennemi le plus proche ; **4 dégâts par seconde** et pose une **brûlure** (6 par seconde, 2 s) |
| Combo | ses ennemis brûlés déclenchent les explosions de l'Incendiaire niveau 3 si un canon Incendiaire les a aussi brûlés (règle du T1 : on retient le dernier brûleur « canon ») |
| **Napalm** (A) | niv. 2 : brûlure de 10 par seconde pendant 4 s · niv. 3 : la brûlure se cumule jusqu'à ×2 sur un même ennemi |
| **Souffle** (B) | niv. 2 : cône de 100° qui **repousse** les ennemis · niv. 3 : portée 200 |

### 5.3 Mortier — 80 d'or
| Élément | Valeur |
|---|---|
| Base | toutes les 3 s, un obus lent (1 s de vol) vers un ennemi entre 120 et 450 px ; l'impact est **annoncé au sol** (petit cercle) puis explose : 25 dégâts, rayon 90 |
| Combo | **×1,5 sur les ennemis ralentis ou gelés** |
| **Grappe** (A) | niv. 2 : l'explosion libère 4 petites explosions autour (10 dégâts, rayon 50) · niv. 3 : 8 petites explosions |
| **Sismique** (B) | niv. 2 : laisse un **cratère** 3 s qui ralentit de 40 % · niv. 3 : le cratère dure 5 s et ralentit de 60 % |

### 5.4 Amplificateur — 90 d'or
| Élément | Valeur |
|---|---|
| Base | ne tire pas ; les tours dans un rayon de 160 font **+25 % de dégâts** (plusieurs amplificateurs ne s'additionnent pas : le plus fort compte) |
| Combo | multiplie un groupe de tours ; ne s'amplifie pas lui-même |
| **Cadence** (A) | niv. 2 : les tours autour tirent aussi **+30 % plus vite** · niv. 3 : +50 % |
| **Catalyseur** (B) | niv. 2 : les états que posent les tours autour (brûlure, gel, trempé, étourdissement, ralentissement du cratère) durent **+50 %** · niv. 3 : +100 % |

Toutes les valeurs sont dans les données.

## 6. Débloquer les tours

| Élément | Règle |
|---|---|
| Début de partie | seuls **canon** et **glace** sont achetables |
| Cartes « Plans : Tesla », « Plans : Lance-flammes », « Plans : Mortier », « Plans : Amplificateur » | rareté peu commune, communes à toutes les spés, **une seule fois chacune**, proposées à partir de la **vague 2** ; la prendre débloque l'achat de cette tour **pour la partie** |
| Trésor | quand il reste un plan non obtenu, le trésor peut en proposer un à la place d'un objet (au plus un plan par trésor) |
| Affichage | un bouton « Acheter … » par tour **débloquée** ; les autres n'apparaissent pas |

## 7. Système générique

- La liste des tours, leurs prix, portées, rayons, branches et valeurs viennent des données de tours. Il n'y a plus de « canon / glace » écrit en dur dans la réserve, le placement, les boutons, le panneau, le panneau de stats ni les effets de mort.
- Chaque tour a un **comportement** (tir d'obus, aura de glace, éclair, cône, obus de mortier, aura d'amplification) dans son propre petit fichier ; les réglages communs (portée, cible désignée prioritaire, image, niveau, branche) sont partagés.
- Le canon et la glace passent dans ce système **sans rien changer pour le joueur** : mêmes valeurs, mêmes branches, mêmes effets du T1.
- Les cartes et objets existants qui touchent aux tours (portée, prix, cadence niveau 3, brûlure des canons…) continuent de marcher. « Surcharge » s'applique à toutes les tours qui tirent ; l'amplificateur n'est pas concerné.

## 8. Apparence

- Chaque tour a sa planche d'images, produite par la fabrique d'images (`tools/sprite_baker/`) avec les pièces Kenney présentes (`tower-round-*`, `tower-square-*`, `weapon-cannon`) et des formes simples faites dans la fabrique, en couleurs néon : bobine et sphère pour la Tesla, buse pour le lance-flammes, tube court et large pour le mortier, antenne et cristal pour l'amplificateur.
- Effets visuels dessinés en code, légers : éclair en ligne brisée néon, cône de feu en particules ou polygone animé, obus en arc avec ombre et cercle d'annonce, aura de l'amplificateur en anneau pulsé et petit lien lumineux vers les tours boostées.

## 8bis. Précisions (relecture du design)

- **Identifiants des tours** *(choix de Claude)* : chaque tour a un identifiant texte (`cannon`, `frost`, `tesla`, `flamethrower`, `mortar`, `amplifier`), avec sa propre section dans les données et ses clés requises par branche. La sauvegarde n'est pas touchée, car elle ne contient rien sur les tours.
- **Boutons d'achat** *(choix de Claude)* :
  - Six boutons de 220 px ne tiennent pas en largeur. Les boutons deviennent des **pastilles compactes** : icône de la tour, prix dessous, gris si l'or manque.
  - Ils tiennent sur une ligne, et la bande du bas en construction reste mesurée au même endroit.
  - Seules les tours débloquées ont un bouton.
- **« Tour de renfort »** *(choix de Claude)* : elle ne donne qu'une tour **débloquée**, celle du type le moins possédé.
- **Brûlures qui se croisent** *(choix de Claude)* :
  - Une nouvelle brûlure **garde la plus forte** des deux (dégâts par seconde) et la durée la plus longue, au lieu de remplacer.
  - Le lance-flammes ne remplace pas l'identifiant du dernier canon brûleur : le combo Incendiaire continue de marcher.
  - **Napalm niveau 3** : la brûlure du lance-flammes peut monter jusqu'à ×2 ses dégâts sur un même ennemi qui reste dans le cône.
- **Amplificateur** *(choix de Claude)* :
  - Chaque bonus prend **le plus fort** des amplificateurs qui touchent la tour, séparément : dégâts, cadence, durée des états. Deux Cadence ne s'additionnent pas ; une Cadence et un Catalyseur s'appliquent tous les deux.
  - « +30 % plus vite » veut dire **intervalle ÷ 1,3**. La cadence se multiplie avec Surcharge et Canon rapide.
  - Le lance-flammes boosté en cadence fait **+30 % de dégâts par seconde**. La glace n'est pas concernée par la cadence.
- **Catalyseur** *(choix de Claude)* :
  - Il compte pour la tour qui pose l'état, si elle est dans la zone au moment où elle le pose.
  - Il allonge : la brûlure, le gel des tours (y compris les éclats de niveau 3), le trempé (Blizzard niveau 3), l'étourdissement de la Tesla et la **durée de vie du cratère** du mortier.
  - Le temps d'attente avant de regeler reste compté à la fin du gel.
- **Cartes existantes et nouvelles tours** *(choix de Claude)* :
  - « Balles lourdes » : toutes les tours qui font des dégâts.
  - « Surcharge » : toutes les tours qui tirent, au niveau 3 (canon, Tesla, lance-flammes, mortier).
  - « Canon rapide » et « Munitions incendiaires » restent pour le **canon seulement**, comme leur nom l'indique.
- **Étourdissement** *(choix de Claude)* :
  - C'est un nouvel état : l'ennemi ne bouge plus, ne frappe pas le cristal, et l'artilleur ne tire pas.
  - La mèche d'un kamikaze déjà allumée continue.
  - Il annule une poussée en cours, comme le gel, et compte comme un état pour les combos (`stunned`).
- **Souffle** *(choix de Claude)* : il repousse d'environ 60 px par seconde dans l'axe du cône tant que l'ennemi est dedans. La poussée est ignorée sur un ennemi gelé ou étourdi. La valeur est dans les données.
- **Cibles** *(choix de Claude)* :
  - Toutes les tours qui visent tirent en priorité sur l'**ennemi désigné** s'il est à portée, sinon sur le plus proche.
  - Le mortier vise l'endroit où l'ennemi se trouve au moment du tir.
  - Rebonds de la Tesla :
    - jamais deux fois le même ennemi par éclair ;
    - pleins dégâts à chaque saut ;
    - l'étourdissement de la branche Arc touche tous les ennemis de la chaîne.
- **Chiffres de dégâts** *(choix de Claude)* :
  - Les coups des nouvelles tours s'affichent en **cyan** comme le canon.
  - Les dégâts continus (cône de feu) sont **regroupés** comme la brûlure.
- **Plans** *(choix de Claude)* :
  - Les cartes portent une valeur « vague minimale » (2) et un effet « débloquer la tour ».
  - Le jeu garde une seule liste de tours débloquées, partagée par les cartes, le trésor et l'affichage.
  - Le trésor peut proposer **au plus un plan** parmi ses trois choix.
  - Prendre un plan au trésor retire la carte correspondante du tirage.
  - Le magasin ne vend pas de plans.
  - Les plans n'apparaissent pas dans la rangée d'objets : la tour débloquée apparaît dans les boutons d'achat.
  - Leurs noms sont « Plans : Tesla »… à ne pas confondre avec l'objet « Plans d'ingénieur ».
- **Annonce du mortier** *(choix de Claude)* : le cercle au sol réutilise les annonces existantes, avec une couleur **cyan** pour un tir ami (et non rouge).
- **Fabrique d'images** *(réponse du projet)* : les formes faites dans la fabrique sont de petits constructeurs dans `tools/sprite_baker/page.html`, appelés par `recipes.json`.

## 9. Approches envisagées

| Approche | Pour | Contre |
|---|---|---|
| **1. Système de tours générique (choisie)** : données + un comportement par tour | Ajouter une tour = données + comportement ; T2b, T3 et futures tours en profitent ; moins d'oublis | Une tâche de plus au début pour retirer le « canon / glace » écrit en dur |
| 2. Ajouter les 4 tours à côté des 2 existantes, en dur | Démarre plus vite | Chaque tour touche 5–6 fichiers ; risque d'oubli ; T2b pénible |

## 10. Contraintes

- Règles du projet : données JSON validées (null + push_error nommant le fichier et la clé, clés requises par tour et par branche comme au T1), interface en code, pas d'autoload, pas de `.uid`/`.import` écrits par les agents, `##` et typage statique ; Godot 4.7.2, export web.
- Les règles du T1 restent vraies, avec leurs contrôles existants (`tower_reserve_check`, `chill_rules_check`, `chain_limiter_check`) adaptés à la liste générique.
- Les effets de zone et les rebonds restent légers aux hautes vagues (beaucoup d'ennemis) ; les effets en chaîne passent par le plafond par image du T1.
- Les dégâts des nouvelles tours profitent du multiplicateur de dégâts des cartes (comme les canons) et apparaissent dans les chiffres de dégâts (source « tour » en cyan).
- L'étourdissement est un nouvel état d'ennemi (immobile, ne frappe pas) ; il compte comme un état pour le Catalyseur.

## 11. Ce qui est laissé au constructeur

- L'organisation des fichiers (comportements, données), en suivant les modèles du projet (types d'ennemis en données + composants de comportement).
- Les réglages fins des effets visuels et des planches d'images, dans le style néon BD.
- La façon de mélanger « plan » et objets dans le tirage du trésor.

## 12. Questions ouvertes

Aucune (points de relecture tranchés au §8bis).
