# Étape 5a — Carte du monde : Design

> **Date** : 2026-11-20
> **Statut** : en relecture par l'utilisateur
> **Design du jeu** : `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md` (sections carte du monde, magasin, objets ; § 9 étape 5)

---

## 1. Intention

Aujourd'hui, une partie est une suite de vagues sans fin ni repère. L'étape 5a donne une **forme** à la partie : des mondes de 8 vagues, une **carte avec des chemins** qu'on planifie, et des **bonus** entre les vagues (magasin, trésor, repos) qui apportent une nouvelle famille de récompenses : les **objets passifs**. L'or gagne enfin un usage hors des tours.

## 2. Ce qui a été validé avec l'utilisateur

- **Découpage B** : 5a = carte + magasin + trésor + repos avec objets **passifs** ; 5b = objets **actifs** (touches 1 et 2), testés à part.
- **Objets séparés des cartes (A)** : famille à part, avec icônes, rangée dans l'affichage, effets un peu plus forts ou originaux.
- **Bonus en plus des vagues (B)** : chaque étape est une vague ; après la vague (et le choix de carte), on va sur un lieu bonus.
- **Vraie carte avec chemins (A)** : tout le réseau du monde est visible dès le début, on planifie son trajet.
- **Approche 1** : carte générée au hasard par du code, avec des règles garanties et testées.
- Propositions acceptées : prix par rareté, 12 objets, valeurs du repos et du magasin, vague finale renforcée, aperçu des ennemis sur l'écran de carte.

## 3. Objectifs

1. Mondes de 8 vagues ; vague 8 = vague finale renforcée ; puis monde suivant, la difficulté continuant de monter.
2. Écran de carte généré au hasard, avec chemins, icônes néon, position du joueur et lieux atteignables.
3. Trois lieux : magasin, trésor, repos.
4. 12 objets passifs décrits en données, rangée d'icônes dans l'affichage, effets pris en compte par le panneau de stats.

## 4. Non-objectifs

- Pas d'objets actifs ni de touches 1 et 2 (étape 5b).
- Pas de mini-boss ni de boss (étape 6) : la vague finale les remplace provisoirement.
- Pas de décor ni d'ennemis propres à chaque monde (étape 7) : le monde 2 ressemble au monde 1.
- Pas de nouveau type d'ennemi, pas de changement des cartes existantes.
- Pas de sauvegarde d'une partie en cours.

## 5. Le déroulé d'une partie

| Moment | Ce qui se passe |
|---|---|
| Début de partie | choix de spécialisation (inchangé), puis la carte du monde 1 est générée et montrée une première fois, puis la vague 1 |
| Fin des vagues 1 à 7 | choix de carte (inchangé), puis **écran de carte** : on choisit le lieu suivant parmi ceux reliés à sa position, on y entre, puis phase de construction et vague suivante |
| Vague 8 | **vague finale** : +50 % d'ennemis, bandeau « VAGUE FINALE ! » à son annonce |
| Fin de la vague 8 | choix de carte, puis bandeau « MONDE 2 », nouvelle carte générée, et on recommence |

- Le numéro de vague **continue** d'un monde à l'autre (monde 2 = vagues 9 à 16) : la courbe de difficulté actuelle (`waves.json`) s'applique telle quelle.
- L'affichage montre « Monde X — Vague Y/8 ».
- Le choix de carte et le lieu bonus ont lieu **avant** la phase de construction, pour que les objets achetés comptent dès la pose des tours.

## 6. L'écran de carte

### 6.1 Forme

- Lecture de **gauche à droite** : un point de départ à gauche, puis **7 colonnes de lieux** (une après chacune des vagues 1 à 7), puis le drapeau de la vague finale à droite.
- Chaque colonne a **2 ou 3 lieux**. Chaque lieu est relié à **1 ou 2 lieux** de la colonne suivante ; chaque lieu a au moins un lien entrant ; **les traits ne se croisent jamais**.
- Chaque lieu a une **icône néon** et sa couleur : magasin, trésor, repos.
- Le lieu actuel est marqué ; les lieux **atteignables** clignotent ; les lieux déjà passés et le chemin parcouru restent en surbrillance ; les lieux devenus inaccessibles sont assombris.
- Survol d'un lieu : son nom et ce qu'il propose en une ligne.
- Un clic sur un lieu atteignable y entre directement.
- **Aperçu de la prochaine vague** dans un coin : numéro, types d'ennemis et nombre (même information que l'aperçu actuel, complétée par les kamikazes et artilleurs).

### 6.2 Règles de génération

| Règle | Valeur |
|---|---|
| Chances de chaque lieu | magasin 40 %, trésor 30 %, repos 30 % (données) |
| Pas de doublon | deux lieux d'une même colonne reliés au même lieu précédent ne sont jamais du même type |
| Magasins | **tout chemin possible** passe par au moins 2 magasins |
| Variété | aucun chemin possible ne passe par 3 lieux identiques de suite |

- Les règles sont garanties par la génération (par exemple : tirage, vérification, nouveau tirage si une règle échoue) et vérifiées par des tests automatiques sur de nombreuses graines.

## 7. Les lieux

### 7.1 Magasin

- **4 objets passifs** tirés au hasard (catégories mélangées), chacun au prix de sa rareté ; un objet acheté disparaît de l'étal.
- **Réparation du cristal** : 40 d'or pour +20 PV, sans limite d'achats, sans dépasser le maximum.
- Un objet trop cher est grisé ; un bouton « Partir » ferme le magasin.

| Rareté | Prix |
|---|---|
| commune | 60 |
| peu commune | 100 |
| rare | 150 |
| épique | 220 |
| légendaire | 300 |

### 7.2 Trésor

- **3 objets passifs** au choix, gratuits ; on en prend un (obligatoire, comme les cartes).
- Les raretés du trésor suivent les poids de rareté des cartes de la même vague (`card_rarities.json`).

### 7.3 Repos

- Deux choix, un seul possible : **soigner le héros de 30 % de ses PV maximum**, ou **réparer le cristal de 20 PV**.

### 7.4 Règles communes

- Un objet possédé ne réapparaît plus, ni au magasin ni au trésor.
- Si moins d'objets restent disponibles que d'emplacements, on en montre moins ; s'il n'en reste aucun, le trésor donne 100 d'or à la place.
- Tirage du magasin : poids de rareté des cartes de la même vague, comme le trésor.

## 8. Les objets passifs

| Catégorie | Objet | Rareté | Effet |
|---|---|---|---|
| Attaque | Lunette | commune | +5 % de chances de critique |
| Attaque | Gâchette | peu commune | +10 % de cadence de l'arme |
| Attaque | Poudre noire | rare | +15 % de dégâts du héros |
| Attaque | Œil de faucon | peu commune | +20 % de portée des tours |
| Survie | Cœur de néon | commune | +20 PV maximum (et soigne d'autant) |
| Survie | Pansement doré | peu commune | soigne le héros de 10 PV au début de chaque vague |
| Survie | Bouclier du cristal | rare | le cristal subit 15 % de dégâts en moins |
| Survie | Seconde chance | légendaire | une fois par partie : à 0 PV, le héros revient à 30 % de ses PV au lieu de mourir |
| Utilité | Bottes | commune | +10 % de vitesse de déplacement |
| Utilité | Aimant | commune | +30 % de rayon de ramassage de l'or |
| Utilité | Plans d'ingénieur | épique | les tours coûtent 20 % de moins |
| Utilité | Bourse percée | rare | +20 % d'or par ennemi tué |

- Chaque objet ne se possède qu'**une fois**.
- Valeurs, rareté, catégorie, nom, description et icône dans un fichier de données.
- Les effets passent par la source unique de stats (`PlayerModifiers`) ou à côté d'elle, pour que le panneau de stats affiche les valeurs réelles (cartes + objets).
- **Seconde chance** : flash, texte « SECONDE CHANCE ! » avec l'étoile pop, 0,5 s d'invincibilité comme après un coup ; l'icône s'éteint une fois utilisée.
- **Rangée d'icônes** dans l'affichage (style néon) ; survol d'une icône = nom et effet.

## 8bis. Précisions (relecture du design)

- **Aperçu des vagues** *(réponse du projet)* : l'aperçu actuel ne montre que le nombre de gobelins (les kamikazes et artilleurs s'ajoutent ensuite). Un seul calcul donne le détail par type, vague finale comprise ; il sert à l'écran de carte **et** à l'aperçu de l'affichage, qui devient juste.
- **Vague finale** *(choix de Claude)* : +50 % sur **chaque** type d'ennemi, arrondi au plus proche ; le multiplicateur est dans les données des vagues.
- **Première carte** *(choix de Claude)* : en début de partie, la carte est montrée **en consultation** (rien à choisir, bouton « C'est parti ! »). Ordre : spécialisation, choix de carte d'ouverture s'il existe, carte en consultation, construction, vague 1.
- **Départ et arrivée** *(choix de Claude)* : le départ est relié à tous les lieux de la colonne 1 ; tous les lieux de la colonne 7 sont reliés au drapeau de la vague finale.
- **Magasin** *(choix de Claude)* : l'étal est tiré à l'entrée et ne change plus ; pas de relance ; on ne revient jamais sur un lieu.
- **Arrondis de l'or** *(choix de Claude)* : Bourse percée = or par ennemi × 1,2 arrondi au plus proche ; prix, réparation, repos et or de remplacement du trésor sont dans les données.
- **Lunette** *(réponse du projet)* : seule l'arme de l'archer peut faire des critiques ; la Lunette n'est proposée qu'aux spécialisations qui peuvent critiquer (comme les cartes adaptées à la spé).
- **Œil de faucon et Plans d'ingénieur** *(réponse du projet)* : il faut un multiplicateur de portée des tours (canon, glace, et cercle d'aperçu à la pose) et un multiplicateur de coût (pose et prix affichés sur les boutons).
- **Bouclier du cristal, Seconde chance, Pansement doré** *(réponse du projet)* : le cristal reçoit un facteur de dégâts ; la vie du héros reçoit un « sauvetage » vérifié avant la mort ; le Pansement soigne au début de chaque vague, indépendamment de la régénération.
- **Monde en cours** *(choix de Claude)* : le numéro de monde est gardé avec l'état de la partie ; l'affichage montre « Monde X — Vague Y/8 » ; les nouvelles phases (carte, lieu) ont leur libellé.
- **Génération** *(choix de Claude)* : d'abord les colonnes et les liens sans croisement, puis les types de lieux, puis vérification des règles sur tous les chemins ; nouveau tirage si une règle échoue ; après 50 essais, un modèle fixe valide est utilisé, pour que la génération se termine toujours.

## 9. Approches envisagées

| Approche | Pour | Contre |
|---|---|---|
| **1. Carte générée au hasard par du code, avec règles (choisie)** | Chaque partie est différente ; les règles sont garanties et testées | Un peu plus de code |
| 2. Cartes dessinées à la main dans un fichier | Contrôle total | Répétitif très vite |
| 3. Objets = cartes déguisées | Très rapide | Contraire au choix « objets séparés » |

## 10. Contraintes

- Règles du projet : données JSON validées (null + push_error nommant le fichier et la clé), interface en code, pas d'autoload, pas de `.uid`/`.import` écrits par les agents, typage statique et docs `##` ; Godot 4.7.2, export web.
- La génération de carte est une logique pure (graine fournie, sans nœud) pour être testée par les scripts de vérification.
- Les vagues, cartes, ennemis et compétences existants gardent leurs règles ; seuls changent l'enchaînement entre les vagues et l'ajout des objets.
- Défaite (héros ou cristal) : inchangée, à n'importe quel monde ; les points de fin de partie se calculent comme aujourd'hui.

## 11. Ce qui est laissé au constructeur

- Organisation des fichiers (générateur, écran de carte, magasin, trésor, repos, catalogue d'objets).
- Disposition exacte de l'écran de carte et des écrans de lieux, dans le style néon des écrans existants.
- Icônes des lieux et des objets : dessinées en code (formes néon simples) ou petites images ; pas de nouveaux modèles 3D.
- Méthode exacte pour garantir les règles de génération.

## 12. Questions ouvertes

Aucune.
