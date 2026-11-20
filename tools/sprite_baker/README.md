# Fabrique d'images (sprite baker)

Rend les modeles 3D sources (`assets/models/source/`) en planches PNG 2D pour le jeu :
camera orthographique inclinee de 50 degres, aplats 3 tons, contour noir, fond transparent,
8 directions, cases de 128x128. Le resultat (`assets/sprites/<id>/`) est commite ; on ne relance
la fabrique que pour changer une couleur, une animation ou un modele.

## Relancer

```
cd tools/sprite_baker
npm install                  # three@0.147.0 + playwright@1.63.0 dans node_modules (non commite)
npx playwright install chromium   # une fois, si Chromium n'est pas deja installe
node bake.js                 # tous les elements ; ou : node bake.js elf goblin
python3 contact_sheet.py     # contact.png (non commite) pour controler a l'oeil
```

Il faut Node.js, Chromium (via `playwright` 1.63.0, version exacte dans `package.json`) et Python 3 avec Pillow. `bake.js` lance un petit
serveur HTTP local (three.js vient de `node_modules`, jamais d'un CDN) et affiche `ATTENTION` si une
silhouette touche le bord d'une case (code de sortie 1).

## Ou sont les recettes

`recipes.json` : taille de case, point d'ancrage, images par seconde, tangage de la camera, et un bloc
par element dans `items` :

- `kind: "character"` (Quaternius) : `model`, `palette` (materiau -> couleur), `animations`
  (nom court -> nom du pack, nombre d'images, boucle), `half_size` (demi-largeur du champ en unites monde).
- `kind: "prop"` (Kenney + sur mesure) : `parts` (GLB empiles, palette `kenney_palettes`, `rotates`
  pour la piece qui tourne selon la direction), `builder` (`frostTop`, `crystalCart`, dans `page.html`),
  `directions` (8 ou 1).

Sortie par element : une planche `<animation>.png` (8 lignes = directions, une colonne par image)
et `sheet.json` (`cell`, `anchor`, `directions`, `animations`).

## Conventions

- Direction `k` = l'objet regarde vers l'angle ecran `k x 45 deg` (0 droite, 2 bas, 4 gauche, 6 haut).
- Ancrage `[64, 112]` = bas-centre de la silhouette, calcule sur la pose de depart (toutes directions).
  C'est la position de jeu de l'objet, sur CHAQUE image de CHAQUE animation : rien n'est decale.
- Une animation dont la silhouette depasse la case standard (mort, roulade : corps allonge) recoit sa
  propre case, plus grande (multiples de 16, mesuree sur toutes ses images et directions), et son propre
  ancrage. `sheet.json` porte alors `"cell": [w, h]` et `"anchor": [x, y]` sur cette animation ; sans ces
  cles, l'animation utilise `cell` / `anchor` de la racine. `bake.js` affiche la case choisie.
- Les modeles Quaternius sont des `.gltf` convertis en `.glb` sans re-encodage (tampon integre
  decode, conteneur binaire ecrit).
