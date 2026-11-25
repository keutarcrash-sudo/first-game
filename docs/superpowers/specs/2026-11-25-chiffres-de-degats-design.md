# Chiffres de dégâts : Design (court)

> **Date** : 2026-11-25
> **Statut** : en relecture par l'utilisateur

## Intention

Le joueur veut voir combien chaque coup inflige, au-dessus de l'ennemi touché. Il lit mieux ses dégâts et peut juger son build et ses tours (la glace notamment, avant leur refonte). C'est le premier des trois chantiers demandés : chiffres de dégâts, puis tours, puis arbre de compétences.

## Ce qui a été validé avec l'utilisateur

- Un chiffre à chaque coup, au-dessus de l'ennemi. Il monte un peu puis s'efface en moins d'une seconde, dans la police des onomatopées (Bangers) avec un contour noir.
- Couleur selon la source :
  - blanc : tirs et compétences du héros ;
  - cyan : canons ;
  - orange : brûlure ;
  - **jaune, plus gros, suivi de « ! »** : coup critique.
- Les petits dégâts répétés (brûlure, pluie de flèches, mur de feu…) sont regroupés : un seul chiffre par ennemi, qui additionne et se ré-affiche toutes les demi-secondes, au lieu d'une pluie de chiffres.
- Un réglage permet de les couper.

## Non-objectifs

- Pas de chiffres sur le héros ni sur le cristal : ils ont déjà leur barre et leurs flashs.
- Aucune règle de dégâts ne change ; c'est de l'affichage seulement.

## Contraintes

- Règles du projet :
  - interface et effets en code ;
  - réglages (couleurs, tailles, durées, intervalle de regroupement, interrupteur) dans un fichier de données validé ;
  - pas d'autoload ;
  - pas de `.uid`/`.import` écrits par les agents ;
  - `##` et typage statique.
- **Aujourd'hui, `Enemy.take_damage(amount, heavy)` ne dit ni la source ni le critique** : `heavy` vaut vrai pour les critiques du héros comme pour toutes les compétences. Il faut donc faire passer la source (héros, canon, brûlure, zone) et le fait d'être un critique jusqu'à l'ennemi, sans changer les dégâts eux-mêmes. Points d'appel actuels :
  - balle du héros ;
  - boule de feu, météore, vague, flèche perforante ;
  - pluie de flèches ;
  - effets de cartes ;
  - canon ;
  - brûlure (`_damage` avec `burn_tick`).
- Les dégâts affichés sont ceux réellement retirés, après Combustion (`burning_vulnerability`) ; un coup mortel affiche aussi son chiffre.
- Plusieurs dizaines d'ennemis peuvent être touchés en même temps (pluie, météore) : les chiffres doivent rester légers (pas de nœud lourd par chiffre, ou un nombre maximum à l'écran).
- Le chiffre suit le temps réel même pendant l'arrêt sur image (hitstop), comme les autres effets.
- Arrondi à l'entier ; un dégât inférieur à 1 regroupé jusqu'à atteindre au moins 1.

## Approches envisagées

| Approche | Pour | Contre |
|---|---|---|
| **1. Un calque unique qui dessine tous les chiffres (choisie)** : un nœud reçoit les coups, garde une petite liste de chiffres et les dessine dans son `_draw` | Léger même avec beaucoup de coups ; regroupement par ennemi simple à faire au même endroit | Un peu plus de code qu'un Label par chiffre |
| 2. Un petit Label animé par chiffre (comme `PopBurst`) | Très simple | Lourd avec la pluie ou le météore ; regroupement plus compliqué |

## Ce qui est laissé au constructeur

- La forme exacte du passage de la source et du critique (nouveaux paramètres, petit type de coup…), tant que les dégâts ne changent pas.
- Le petit décalage au hasard des chiffres pour qu'ils ne se superposent pas, et la courbe exacte de montée et de fondu.
- Le nombre maximum de chiffres à l'écran.
