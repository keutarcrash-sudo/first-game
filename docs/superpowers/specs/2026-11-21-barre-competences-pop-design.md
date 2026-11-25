# Barre de compétences « badges pop » : Design (court)

> **Date** : 2026-11-21
> **Statut** : en relecture par l'utilisateur
> **Maquette** : https://claude.ai/artifact/F2YvCU467PW3Lj16C62tpu (piste B)

## Intention

La barre de compétences (clic droit, A, E, R) ne va pas avec le reste du jeu (onomatopées POW / BOUM, cartes néon). On la refait dans le même style BD néon pop, sans changer son rôle ni sa place.

## Ce qui a été validé avec l'utilisateur

- **Piste B, « badges pop »** (parmi : actuelle, badges pop, cartes penchées, icônes néon).
- **Couleur par rôle (A)**, la même pour tous les héros (plutôt qu'une couleur par héros) :
  - tir principal (clic droit) : rose ;
  - saut (A) : cyan ;
  - zone (E) : violet ;
  - ultime (R) : jaune.
- **Approche 1** : tout est dessiné par le code (parmi : tout en code / icônes SVG / nœuds d'interface).

## Le résultat attendu

| Élément | Rendu |
|---|---|
| Emplacement | une pastille ronde par compétence, en bas au centre comme aujourd'hui |
| Pastille | disque de la couleur du rôle, gros contour noir, ombre noire décalée (style BD), léger halo de la couleur |
| Icône | une icône par compétence (12 au total, 4 par héros), en traits noirs épais au centre |
| Touche | étiquette jaune penchée en haut à droite (« CLIC D. », « A », « E », « R ») |
| Nom | dessous, police Bangers, contour noir |
| Recharge | voile sombre qui se vide comme une horloge, gros chiffre au centre |
| Prête | la pastille « respire » doucement (léger grossissement en boucle) |
| Fin de recharge | petit « pop » : grossissement bref et flash |
| Verrouillée | pastille grise, icône cadenas, nom en gris |

## Non-objectifs

- Pas de changement des compétences, de leurs touches ni de leurs temps de recharge.
- Pas de nouvelle place à l'écran, pas de clic sur les pastilles.
- Les autres éléments de l'affichage (PV, or, cartes, objets) ne changent pas.

## Contraintes

- Règles du projet : interface en code, valeurs réglables (couleurs, tailles, durées d'animation) dans un fichier de données validé, pas d'autoload, pas de `.uid`/`.import` écrits par les agents, `##` et typage statique.
- La hauteur de la bande du bas reste lue à **un seul endroit** (`AbilityBar.bottom_band_height()`), utilisée par la caméra pour garder le cristal visible.
- L'animation « respire » et le « pop » ne doivent pas gêner la lecture du chiffre de recharge.

## Approches envisagées

| Approche | Pour | Contre |
|---|---|---|
| **1. Tout dessiné par le code (choisie)** | Net à toute taille, aucun fichier image, réglable en données, même technique que la barre actuelle | Icônes simples (traits) |
| 2. Icônes en SVG dans des pastilles dessinées | Icônes plus détaillées | 12 fichiers à dessiner, fichiers d'import Godot à envoyer par l'utilisateur |
| 3. Pastilles en nœuds d'interface | Survol et clic faciles | Horloge, ombre BD et « respiration » plus difficiles qu'en dessin direct |

## Ce qui est laissé au constructeur

- Le dessin exact des 12 icônes, reconnaissables et en traits simples, par exemple : flèche perforante, roulade, pluie de flèches, œil, boule de feu, bond enflammé, mur de feu, météore, vague, glissade, flaque, raz-de-marée.
- Les tailles exactes, pour que la barre tienne dans la bande du bas à 1280×720.
- Le réglage de l'animation et des couleurs exactes, dans la palette néon du jeu.
