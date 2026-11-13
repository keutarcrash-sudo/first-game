# Game Brief: Cristal Combo

**One-sentence pitch:** Un jeu de défense vu du dessus où tu escortes un cristal à travers 4 mondes : à chaque vague tu poses des tours temporaires sur son trajet, tu désignes leurs cibles, tu esquives, tu ramasses l'or, et tes choix de build créent des combos jusqu'à la « god run ».

> **Design complet :** `docs/superpowers/specs/2026-11-13-cristal-combo-v2-design.md` (approuvé le 2026-11-13). Ce brief en est le résumé ; en cas de doute, le design complet fait foi.

## Core loop
- **Carte** : dans chaque monde, choisir son prochain lieu parmi 2 ou 3 (vague, magasin, trésor, repos, mini-boss), jusqu'au boss du monde.
- **Préparation d'une vague** : on voit le trajet du cristal et les types et nombres d'ennemis à venir ; on pose des tours le long du trajet avec son or. Espace lance la vague.
- **Combat** : le cristal avance seul ; le héros (ZQSD, tir automatique vers la souris) désigne au clic gauche la cible des tours, utilise ses compétences (clic droit, A, E, R) et ses objets actifs (1, 2), esquive les attaques annoncées et va ramasser l'or tombé au sol.
- **Fin de vague** : les tours disparaissent, l'or non dépensé reste, choix d'une carte parmi 3.
- **À la fin de la partie** : dépenser ses points dans l'arbre de déblocages, puis relancer.

## Player goal & fail state — what "working" looks like
- Amener le cristal au bout du monde 4 dans le meilleur état possible. La fin dépend des PV du cristal à l'arrivée et des fragments cachés trouvés ; la meilleure ouvre un 5e monde caché.
- La partie est perdue quand **le cristal ou le héros** tombe à 0 PV. Chaque partie rapporte des points pour l'arbre.

## Version actuelle (MVP + spécialisations, construits)
Héros ZQSD + tir vers la souris, cristal fixe dans une arène, vagues, tours canon et glace permanentes, or automatique, choix de cartes, système de combos, arbre de déblocages sauvegardé dans le navigateur, spécialisations Archer, Maître du feu et Maître de l'eau. Le plan de construction ci-dessous transforme cette version.

## Build order
1. **Le cristal qui avance** : trajet, préparation (trajet visible + aperçu des ennemis), tours valables une vague, fin de vague à l'arrivée, caméra qui suit le héros.
2. **Or au sol et désignation** : l'or tombe et disparaît, portée de ramassage, clic gauche pour le focus des tours.
3. **Compétences actives** : clic droit, A, E, R pour l'Archer, le Maître du feu et le Maître de l'eau.
4. **Danger pour le héros** : PV du héros, défaite du héros, kamikazes, artilleurs, zones annoncées, soins.
5. **Carte du monde** : embranchements, magasin, trésor, repos.
6. **Mini-boss et boss du monde 1** : le monde 1 est complet.
7. **Suite** : fins et fragments, mondes 2 à 4, monde caché, mode sans fin, nouvelles spécialisations, habillage visuel.

## Out of scope — not building this
- Pas de multijoueur.
- Pas de compte ni de sauvegarde en ligne : la progression est sauvegardée seulement dans le navigateur.
- Pas de contrôles tactiles (clavier + souris uniquement).
- Pas de vue à la 1re ni à la 3e personne : vue de dessus uniquement.
- Pas d'ennemis qui traquent le héros : tous visent le cristal.
- Pas de sons ni de musique pour l'instant.
- Pas d'histoire racontée au-delà des textes de fin.

---
**Who it's for / what they feel:** les joueurs qui aiment les jeux à skill (Deadlock, Overwatch) et les roguelites à builds (Ember Knights) : la satisfaction de lire la menace, de bien placer ses tours, de focus la bonne cible et de trouver un build trop fort. Un monde dure environ 8 à 12 minutes.

**Art & audio direction:** d'abord des formes simples et des lumières fortes sur fond sombre (lisibles en combat, faites par le code) ; ensuite, monde par monde, un habillage peint et élégant façon Deadlock. Audio : plus tard.

**Reference games:** *Deadlock* (montée en puissance pendant la partie, skill, style), *Overwatch* (escorte de convoi, focus), *Ember Knights* (mondes, carte, mode sans fin), *Clover Pit* (fins multiples).

---

## Spécialisations

**Règles :**
- Un écran de choix s'affiche avant le départ ; une seule spécialisation par partie.
- **Archer** est disponible dès la première partie ; les autres se débloquent dans la branche « Spécialisations » de l'arbre.
- Chaque spécialisation a son arme, son état sur les ennemis, ses compétences actives (clic droit, A, E, R), ses cartes et ses combos.
- Tout est décrit dans des fichiers de données.

**Les 9 spécialisations :** Archer, Maître du feu et Maître de l'eau sont construits. Les 6 autres reviennent à l'étape 7 du plan, adaptées au nouveau jeu (compétences actives, tours temporaires) ; les idées ci-dessous servent de point de départ.

| Spécialisation | Façon de combattre | État | Exemple de combo |
|---|---|---|---|
| Archer (départ) | Flèches perçantes à longue portée, coups critiques | marqué | marqué + tours = dégâts en plus |
| Maître du feu | Tirs qui enflamment | brûle | brûle + canon = dégâts en plus |
| Maître de l'eau | Tirs qui trempent | trempé | trempé + glace = gelé |
| Mage du temps | Ralentit le temps autour de lui, peut figer les ennemis | figé | figé + coup critique garanti |
| Berserker | Combat au corps à corps autour de lui, plus fort quand le cristal est en danger | saigne | saigne + canons = dégâts en plus |
| Piégeur | Pose des mines et des pièges sur le chemin des ennemis | piégé | piégé + canons = ×2 |
| Gardien du cristal | Bouclier et réparation du cristal, aura qui renforce les tours proches | affaibli | affaibli près du cristal = cristal protégé |
| Maître de la terre | Rochers lourds, ondes de choc | ébranlé | trempé + ébranlé = boue |
| Maître du vent | Rafales qui repoussent les ennemis | déséquilibré | brûle + vent = l'incendie se propage |
