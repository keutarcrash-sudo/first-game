# Viseur et pointeur : Design (court)

> **Date** : 2026-11-25
> **Statut** : en relecture par l'utilisateur

## Intention

La souris est le pointeur du système, qui ne va pas avec le jeu. En combat, elle sert à viser (tir, compétences au clic droit, désignation au clic gauche) : un viseur la rend lisible et satisfaisante. Dans les écrans de choix, elle doit suivre la direction artistique BD néon pop.

## Ce qui a été validé avec l'utilisateur

- **En combat : un viseur néon.**
  - Forme : une croix cyan à contour noir avec un point central.
  - Au survol d'un ennemi, il devient rose et se resserre, pour montrer ce que le clic gauche désigne.
- **Ailleurs (menus, choix de carte, carte du monde, magasin, trésor, repos, construction, défaite) : un pointeur flèche stylé.**
  - Forme : une flèche jaune à gros contour noir et ombre décalée, comme les étiquettes de la barre de compétences.
- Tout est dessiné par le code et réglable en données (tailles, couleurs).

## Non-objectifs

- Pas de changement de ce que font les clics.
- Pas d'animation lourde ni de traînée derrière la souris.

## Contraintes

- Règles du projet :
  - dessins en code ;
  - réglages dans un fichier JSON validé ;
  - pas d'autoload ;
  - pas de `.uid`/`.import` écrits par les agents ;
  - `##` et typage statique.
- Le curseur doit suivre la souris **sans aucun retard**, ce qui est essentiel pour viser. Il fonctionne en plein écran, en fenêtre et dans la version web.
- Le point visé, c'est-à-dire le « point chaud », est exactement au centre du viseur et à la pointe de la flèche.
- En pause, par exemple à la mort du héros, l'écran de défaite montre la flèche.

## Approches envisagées

| Approche | Pour | Contre |
|---|---|---|
| **1. Curseur matériel (choisie)** : les images du viseur et de la flèche sont dessinées par le code au lancement, puis données au système comme curseur personnalisé (`Input.set_custom_mouse_cursor`) | Aucun retard, comme la vraie souris ; marche partout, web compris | Taille limitée par le système (en général jusqu'à 128 px) ; pas d'animation continue |
| 2. Souris cachée et dessin d'un nœud qui suit la souris | Animations libres | Un léger retard d'une image, gênant pour viser |

## Ce qui est laissé au constructeur

- Le dessin exact du viseur (resserré ou non) et de la flèche, et leurs tailles (autour de 32 à 48 px).
- La détection « survol d'un ennemi », sans coût notable, par exemple vérifiée quelques fois par seconde.
- Le changement de curseur selon la phase du jeu.
