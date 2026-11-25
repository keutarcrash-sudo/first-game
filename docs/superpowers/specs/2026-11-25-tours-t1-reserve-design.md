# Tours T1 — Réserve, améliorations à branches, glace de soutien : Design

> **Date** : 2026-11-25
> **Statut** : en relecture par l'utilisateur
> **Design du jeu** : `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md` — **remplace** la règle « les tours disparaissent à chaque vague » (§ tours, dilemme tours/objets).

---

## 1. Intention

Le joueur veut des parties « god run » à la Risk of Rain 2 / Vampire Survivors : aux hautes vagues, l'écran est plein d'ennemis et le build qu'il a construit rase tout. **Le but n'est pas de simplifier le jeu mais de l'enrichir.** Tours, compétences, cartes, objets et arbre de compétences forment **un seul build**, avec beaucoup de combinaisons pour que chaque partie soit différente.

Le chantier « tours » est découpé en trois :
- **T1** (ce document) : réserve, améliorations à branches, glace refaite ;
- **T2** : nouvelles tours (Tesla, lance-flammes, mortier, amplificateur), déclenchements entre tours, évolutions ;
- **T3** : tours attaquables par les ennemis.

L'arbre de compétences sera refait dans son propre chantier, plus tard.

## 2. Ce qui a été validé avec l'utilisateur

- **Réserve de tours** (plutôt que des tours plantées sur place) : on achète une tour une fois, puis on la replace gratuitement à chaque vague le long du nouveau trajet.
- **Améliorations : choix d'une branche au niveau 2 (B)**, plutôt que des niveaux simples.
- **Découpage T1 → T2 → T3**, dans cet ordre.
- **Principe de build global** : tout ce qu'on ajoute s'appuie sur les états des ennemis (brûlé, marqué, trempé, gelé, ralenti), soit pour les poser, soit pour en profiter.
- **Proposition complète du T1 acceptée telle quelle** (valeurs, branches, glace).

## 3. Objectifs

1. Une réserve de tours qui dure toute la partie : achat à prix croissant, placement gratuit à chaque construction, reprise possible avant la vague.
2. Les améliorations par tour : niveau 2 avec choix de branche, puis niveau 3 qui renforce la branche, deux branches par type.
3. La tour de glace devient une tour de soutien qui gèle, et un ennemi gelé subit plus de dégâts de toutes les sources.
4. De nouvelles cartes liées aux tours, pour que les tours entrent dans le build.

## 4. Non-objectifs

- Pas de nouvelles tours (T2), pas de tours attaquables (T3).
- Pas de refonte de l'arbre de compétences.
- Pas de revente de tours.
- Les compétences du héros et les ennemis ne changent pas.

## 5. Réserve et placement

| Élément | Règle |
|---|---|
| Début de partie | réserve vide, or de départ inchangé (100) |
| Achat | le prix monte avec le nombre de tours **déjà possédées de ce type** : 50, 75, 100, 125… (+25 par tour) |
| Achat pendant | la construction uniquement ; la tour achetée est aussitôt posée là où on clique, comme aujourd'hui |
| Début de chaque construction | toutes les tours de la réserve sont hors du terrain, prêtes à être posées **gratuitement** |
| Reprendre une tour | clic sur une tour posée → elle revient dans la réserve (jusqu'au lancement de la vague) |
| Fin de vague | les tours posées retournent dans la réserve (elles ne restent pas sur l'ancien trajet) |
| Améliorations | chaque tour garde ses améliorations à vie, réserve comprise |
| Objets et cartes existants | « Plans d'ingénieur » (−20 %) s'applique au prix d'achat et aux améliorations ; « Œil de faucon » à la portée de toutes les tours |

Affichage en construction : les boutons des tours montrent, pour chaque type, **combien de tours sont encore dans la réserve** et le **prix de la prochaine**. Poser depuis la réserve est gratuit ; quand la réserve de ce type est vide, poser = acheter.

## 6. Améliorations

En construction, un clic sur une tour posée ouvre un petit panneau près d'elle : son niveau, sa branche, l'amélioration suivante et son prix, et un bouton « Reprendre ». C'est ce même clic qui permet de reprendre la tour.

| Niveau | Prix | Effet |
|---|---|---|
| 1 | — | la tour de base |
| 2 | 80 | **choix d'une branche** (A ou B) |
| 3 | 150 | la branche devient beaucoup plus forte |

### 6.1 Canon

| Branche | Niveau 2 | Niveau 3 |
|---|---|---|
| **Incendiaire** | ses obus brûlent (même brûlure que la carte « Munitions incendiaires ») | les ennemis tués en brûlant **explosent** et blessent leurs voisins |
| **Perforant** | ses obus traversent 3 ennemis | **double tir** (deux obus par tir) |

### 6.2 Glace

| Branche | Niveau 2 | Niveau 3 |
|---|---|---|
| **Blizzard** | zone plus grande, gel plus rapide | les ennemis gelés sont aussi **trempés** |
| **Éclats** | un ennemi gelé qui meurt **éclate** et blesse ses voisins | les éclats **gèlent** les ennemis touchés |

Valeurs exactes (bonus de zone, vitesse de gel, dégâts et rayon des explosions et éclats) : en données, à proposer par le constructeur dans l'esprit ci-dessus.

## 7. Glace de soutien (base, niveau 1)

| Élément | Valeur |
|---|---|
| Ralentissement | 50 % dans sa zone (comme aujourd'hui) |
| Gel | un ennemi qui reste **1,5 s** dans la zone est **gelé 1 s** |
| Temps avant de pouvoir regeler | **3 s** par ennemi |
| Ennemi gelé | subit **+25 % de dégâts de toutes les sources** |
| Prix | comme le canon : 50, puis +25 par tour possédée |

## 8. Nouvelles cartes liées aux tours

Quelques cartes, aux raretés habituelles, communes à toutes les spés. Valeurs proposées par le constructeur :
- « Tour de renfort » : +1 tour gratuite dans la réserve ;
- « Ingénieur chevronné » : améliorations −25 % ;
- « Surcharge » : les tours de niveau 3 tirent 20 % plus vite ;
- « Gel mordant » : les ennemis gelés subissent +25 % de dégâts en plus.

Elles suivent les règles de rareté, de tirage et de relance existantes.

## 8bis. Précisions (relecture du design)

- **Ralentissement** *(réponse du projet)* : la glace ralentit aujourd'hui de 55 % (facteur de vitesse 0,45). On garde cette valeur ; « 50 % » dans le §7 est arrondi.
- **Choisir quelle tour poser** *(choix de Claude)* :
  - En construction, une **barre de réserve** montre une petite icône par tour possédée, avec son niveau et la lettre de sa branche. On clique sur une icône, puis sur le terrain pour la poser.
  - Les boutons par type deviennent « Acheter canon — 75 » et « Acheter glace — 75 » : on achète la tour suivante et on la pose dans la foulée.
- **Reprendre une tour** *(choix de Claude)* : un clic sur une tour posée ouvre le panneau du §6. Le bouton « Reprendre » renvoie la tour dans la réserve.
- **Le gel des tours et le gel du maître de l'eau** *(choix de Claude)* : les deux existent ensemble, avec un **seul temps d'attente avant de regeler** par ennemi (3 s, compté à la fin du gel).
  - Le gel de la spé eau (instantané sur un ennemi trempé) ne change pas.
  - Le temps passé dans les zones de plusieurs tours de glace ne s'additionne pas : on compte le temps passé dans au moins une zone.
  - La carte « Gel profond » rallonge aussi le gel des tours.
- **+25 % de dégâts sur un ennemi gelé** *(choix de Claude)* :
  - Ce bonus vaut pour **tous les gels**, quelle que soit leur source : tours, Raz-de-marée, flaque, Zéro absolu. C'est le « langage commun » des états.
  - Il se multiplie avec Combustion.
  - « Gel mordant » l'augmente à +50 %.
- **Éclats et Incendiaire niveau 3** *(choix de Claude)* :
  - Seuls comptent les ennemis **gelés par cette tour** (Éclats) ou **brûlés par les obus de ce canon** (Incendiaire), au moment de leur mort. L'effet se déclenche une fois par mort.
  - Les réactions en chaîne sont permises, c'est le plaisir du « god run » : une explosion qui tue un ennemi brûlant le fait exploser à son tour.
  - Garde-fous : un nombre maximum d'explosions et d'éclats par image, et le gel des éclats respecte le temps d'attente avant de regeler.
  - Les cartes Zéro absolu et Brasier éternel continuent d'agir pour tous les gels et brûlures. Leurs effets s'ajoutent à ceux des branches.
- **Incendiaire et la carte « Munitions incendiaires »** *(choix de Claude)* :
  - La branche a sa propre brûlure, plus forte que celle de la carte.
  - Si on possède aussi la carte, les canons Incendiaire brûlent 50 % plus longtemps, pour que la carte ne soit jamais inutile.
- **Perforant** *(choix de Claude)* : l'obus touche **3 ennemis au total**.
- **« Tour de renfort »** *(choix de Claude)* :
  - Elle donne une tour de base gratuite, du type dont on possède le moins (le canon en cas d'égalité).
  - Cette tour ne fait pas monter le prix des suivantes.
- **Réductions de prix** *(choix de Claude)* : elles se multiplient. Plans d'ingénieur ×0,8 et Ingénieur chevronné ×0,75 sur les améliorations donnent ×0,6. Le résultat est arrondi.
- **« Surcharge »** *(choix de Claude)* : elle ne concerne que les tours qui tirent, donc le canon pour l'instant. Au T2, elle s'appliquera aux autres tours qui tirent.
- **Fin de vague** *(réponse du projet)* : l'arrivée du cristal renvoie toutes les tours posées dans la réserve. Aujourd'hui, ce même moment les efface.

## 9. Approches envisagées

| Approche | Pour | Contre |
|---|---|---|
| **1. Les tours deviennent des fiches de données (choisie)** : la réserve est une liste de fiches (type, niveau, branche) ; poser une tour crée le nœud depuis sa fiche ; reprendre ou finir la vague supprime le nœud et garde la fiche | Simple à tester, à sauvegarder et à faire évoluer (T2, T3) ; les améliorations vivent dans la fiche | Les nœuds de tour lisent leurs réglages depuis la fiche (petit changement) |
| 2. Garder les nœuds de tour vivants et les cacher hors du terrain | Peu de changement au départ | Des nœuds fantômes à gérer à chaque vague ; difficile à tester et à étendre |

## 10. Contraintes

- Règles du projet : données JSON validées (prix, branches, valeurs des branches, glace, cartes), interface en code, pas d'autoload, pas de `.uid`/`.import` écrits par les agents, `##` et typage statique ; Godot 4.7.2, export web.
- La réserve et les améliorations sont une logique pure, testable par les scripts de contrôle.
- Les combos existants (`procs.json` : Glace + Canon ×3 sur ralenti, Feu + Canon, Marque + Canon) restent ; le gel et la brûlure des branches utilisent les états existants (`burning`, `frozen`, `wet`, `slowed`).
- Les effets en chaîne (explosions, éclats) restent légers : ils seront nombreux aux hautes vagues.
- « Plans d'ingénieur » et les modificateurs de portée et de cadence existants s'appliquent à toutes les tours.

## 11. Ce qui est laissé au constructeur

- Les valeurs des branches et des nouvelles cartes, dans l'esprit des tables.
- La disposition du panneau d'amélioration et des compteurs de réserve, dans le style néon BD.
- L'apparence des tours améliorées : un petit signe de niveau et de branche suffit, sans nouveaux modèles 3D.

## 12. Questions ouvertes

Aucune (les points soulevés à la relecture sont tranchés au §8bis).
