# Tours T2b — Les 12 évolutions : Design

> **Date** : 2026-11-27
> **Statut** : en relecture par l'utilisateur
> **Suit** : T1 (réserve, branches) et T2a (tours génériques, Tesla, Lance-flammes, Mortier, Amplificateur) — faits et validés en jeu.

---

## 1. Intention

Le joueur veut des builds « god run » où plusieurs couches de combinaisons s'empilent (Risk of Rain 2, Vampire Survivors). Le contenu validé est découpé en trois morceaux :

| Morceau | Contenu |
|---|---|
| **T2b** (ce document) | les 12 évolutions + 3 nouvelles cartes |
| **T2c** | 8 liens entre tours voisines + 6 reliques de tours (nouveaux objets) |
| **T2d** | 6 fusions de tours évoluées en tours légendaires + boost des tours par l'ultime du héros |

Le T2b pose la mécanique d'évolution, sur laquelle s'appuieront les fusions du T2d.

## 2. Ce qui a été validé avec l'utilisateur

- **Évolution = tour de niveau 3 + une carte ou un objet précis**, une par branche, soit 12 en tout (choix A, parmi « niveau 3 + carte/objet » et « fusion de deux tours » ; la fusion vient au T2d).
- **Trois évolutions réservées à un héros** (A) : Canon de siège (archer, objet Lunette), Avalanche (maître de l'eau, carte Zéro absolu), Fournaise (maître du feu, carte Combustion). Les 9 autres sont ouvertes à tous.
- **Liste, valeurs et règles ci-dessous acceptées**, ainsi que le découpage T2b, T2c, T2d (« tout me va »).

## 3. Objectifs

1. Une tour de niveau 3 qui remplit sa condition peut **évoluer** gratuitement, depuis son panneau en construction.
2. Les 12 évolutions du §5, chacune avec son effet.
3. Le panneau indique ce qui manque pour évoluer.
4. Trois nouvelles cartes : Condensateur, Réservoir sous pression, Artillerie lourde.

## 4. Non-objectifs

- Pas de liens entre tours, de reliques (T2c), ni de fusions ou de boost par l'ultime (T2d).
- Pas de changement des tours non évoluées ni des règles T1 et T2a.

## 5. Les 12 évolutions

| Tour, branche | Condition | Évolution | Effet |
|---|---|---|---|
| Canon, Incendiaire | objet **Poudre noire** | **Volcan** | chaque explosion laisse une flaque de lave (rayon 60, 3 s) qui brûle (10 dégâts/s) |
| Canon, Perforant | objet **Lunette** *(archer)* | **Canon de siège** | obus géants qui traversent tous les ennemis, dégâts ×1,5, portée ×1,5 |
| Glace, Blizzard | carte **Gel mordant** | **Cœur de l'hiver** | toutes les 4 s, gèle d'un coup tous les ennemis de sa zone pendant 1,5 s |
| Glace, Éclats | carte **Zéro absolu** *(eau)* | **Avalanche** | chaque éclat rebondit sur 3 ennemis de plus |
| Tesla, Surtension | carte **Condensateur** *(nouvelle)* | **Orage** | chaque éclair en relance un second depuis un ennemi touché |
| Tesla, Arc | objet **Bottes de vent** | **Champ magnétique** | attire les ennemis de sa zone vers la tour (environ 50 px/s) |
| Lance-flammes, Napalm | carte **Réservoir sous pression** *(nouvelle)* | **Dragon** | le feu sort tout autour de la tour (360°) |
| Lance-flammes, Souffle | carte **Combustion** *(feu)* | **Fournaise** | un ennemi en feu qui meurt dans sa zone enflamme ses voisins (rayon 80) |
| Mortier, Grappe | carte **Artillerie lourde** *(nouvelle)* | **Bombardement** | 3 obus par tir, sur 3 cibles différentes si possible |
| Mortier, Sismique | objet **Bouclier de cristal** | **Tremblement** | chaque impact étourdit 0,5 s |
| Amplificateur, Cadence | objet **Gâchette légère** | **Surrégime** | son bonus de cadence est doublé |
| Amplificateur, Catalyseur | objet **Plans d'ingénieur** | **Nexus** | chaque tir d'une tour boostée pose aussi les états que posent les autres tours boostées (brûlure, gel, trempé, étourdissement, ralentissement) |

Toutes les valeurs sont dans les données.

## 6. Règles d'évolution

| Élément | Règle |
|---|---|
| Quand | en construction, depuis le panneau d'une tour posée |
| Condition | niveau 3 **et** la carte ou l'objet demandé possédé |
| Prix | gratuit |
| Ensuite | la tour reste évoluée à vie (réserve comprise), garde sa branche et ses bonus de niveau 3 ; **halo doré** et nom de l'évolution dans son panneau et dans la barre de réserve |
| Panneau | au niveau 3 : bouton « ÉVOLUER ! » si la condition est remplie ; sinon « Évolue avec : <carte ou objet> » (grisé) ; pour une évolution réservée à un autre héros : « Évolution réservée à <héros> » |
| Les tours de même type | chaque tour évolue séparément |

## 7. Nouvelles cartes

| Carte | Rareté | Effet | Apparition |
|---|---|---|---|
| Condensateur | rare, ×1 | aucun effet seul ; permet l'évolution Orage | seulement si la Tesla est débloquée |
| Réservoir sous pression | rare, ×1 | aucun effet seul ; permet l'évolution Dragon | seulement si le lance-flammes est débloqué |
| Artillerie lourde | rare, ×1 | aucun effet seul ; permet l'évolution Bombardement | seulement si le mortier est débloqué |

Elles sont ouvertes à tous les héros, et leur description dit clairement à quoi elles servent.

## 7bis. Précisions (relecture du design)

- **Volcan** *(choix de Claude)* : les obus du canon n'explosent pas. C'est l'**explosion de mort de l'Incendiaire niveau 3** qui laisse la flaque de lave.
  - La lave inflige des dégâts continus (chiffres cyan regroupés).
  - Elle ne pose **pas** de brûlure de canon, pour ne pas relancer des explosions sans fin.
  - Les flaques passent par le plafond par image.
- **Cœur de l'hiver** *(choix de Claude)* : son gel d'onde **ignore le temps d'attente avant de regeler**, sinon une onde sur deux raterait. Le gel normal de la glace garde ses règles.
- **Avalanche** *(choix de Claude)* :
  - L'éclat de mort de la branche Éclats fait en plus **3 sauts** à la façon de la Tesla, vers l'ennemi le plus proche pas encore touché.
  - Chaque saut inflige les dégâts d'éclat et compte dans le plafond par image.
- **Orage** *(choix de Claude)* :
  - Le second éclair part du **dernier ennemi touché**, avec les mêmes dégâts et le même nombre de rebonds.
  - Il ne touche que des ennemis nouveaux, ne se relance pas lui-même, et compte dans le plafond.
- **Champ magnétique** *(choix de Claude)* :
  - L'aspiration (environ 50 px/s) agit **aussi sur les ennemis étourdis**, mais pas sur les gelés : l'Arc étourdit puis aspire, c'est le combo voulu.
  - Elle s'arrête à 40 px de la tour, pour que les ennemis ne tremblent pas dessus.
  - Elle s'ajoute aux autres poussées au lieu de les remplacer.
- **Dragon** *(choix de Claude)* : le feu est un anneau tout autour de la tour, sans visée ; il est dessiné en anneau.
- **Fournaise** *(choix de Claude)* :
  - Un ennemi en feu qui meurt **dans la portée** de cette tour explose en flammes : 15 dégâts et une brûlure dans un rayon de 80.
  - Si le joueur possède aussi Brasier éternel, les deux effets s'ajoutent.
  - Le tout compte dans le plafond par image.
- **Bombardement** *(choix de Claude)* :
  - 3 obus, sur 3 ennemis différents si possible ; sinon, les obus en trop tombent près de la même cible (±40 px).
  - Chaque obus garde tous ses effets.
  - Les petites explosions passent par le plafond par image.
- **Nexus** *(choix de Claude)*. Pour rester lisible, chaque tir d'une tour boostée pose **une version légère** des états des autres tours boostées, avec des valeurs fixées dans les données :

  | Tour boostée | État partagé |
  |---|---|
  | canon Incendiaire ou lance-flammes | brûlure légère, 4 dégâts par seconde pendant 2 s |
  | glace | ralentissement de 30 % pendant 1 s ; jamais de gel direct, qui sauterait le temps de présence dans la zone |
  | glace Blizzard niveau 3 | trempé 2 s |
  | Tesla Arc ou mortier Tremblement | étourdissement 0,2 s |
- **Nouvelles cartes** *(choix de Claude)* : un type d'effet « clé d'évolution », sans effet seul, et un champ « tour requise » pour qu'elles n'apparaissent que si la tour est débloquée.
- **Évolutions réservées à un héros** *(réponse du projet)* : Lunette, Zéro absolu et Combustion sont déjà réservés à leur héros. Le message du panneau prend le héros de là.
- **Noms** *(réponse du projet)* : l'objet s'appelle « Gâchette légère ».
- **Barre de réserve** *(choix de Claude)* : une tour évoluée y porte une **étoile dorée**, et son nom complet s'affiche au survol.
- **Plafond par image** *(choix de Claude)* : il couvre désormais aussi les éclairs relancés, les sauts d'éclats, les flaques de lave, les explosions de la Fournaise et les obus du Bombardement.

## 8. Approche

Une seule façon s'impose : prolonger le système générique du T2a.
- Les évolutions sont décrites dans les données des tours, par tour et par branche : nom, condition et valeurs.
- La fiche de tour retient si elle est évoluée.
- Chaque comportement de tour lit l'état « évoluée » et ajoute son effet.

Une autre façon, des classes de tours séparées pour chaque évolution, dupliquerait les 6 comportements et compliquerait les fusions du T2d.

## 9. Contraintes

- Règles du projet :
  - données JSON validées (null + push_error nommant le fichier et la clé, clés requises pour chaque évolution) ;
  - interface en code ;
  - pas d'autoload ;
  - pas de `.uid`/`.import` écrits par les agents ;
  - `##` et typage statique.
- Les conditions désignent des objets (`items.json`) ou des cartes (`cards.json`) **existants**, vérifiés au chargement.
- Les effets en chaîne (lave, éclats, éclairs relancés, embrasement) passent par le plafond par image du T1, pour rester fluides aux hautes vagues.
- Les dégâts des évolutions profitent des multiplicateurs existants (Balles lourdes, amplificateur), apparaissent dans les chiffres de dégâts et s'effacent en fin de vague comme le reste.

## 10. Ce qui est laissé au constructeur

- Le détail des effets visuels (halo doré, lave, aspiration, éclair relancé), dans le style néon BD.
- L'organisation des données d'évolution, dans l'esprit de `towers.json`.
- Les valeurs fines non fixées ci-dessus (durées des effets visuels, petits rayons), réglables en données.

## 11. Questions ouvertes

Aucune (points de relecture tranchés au §7bis).
