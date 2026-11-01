# Epic: Cristal Combo

> **Source**: `design/game-brief.md`
> **Workflow**: minimal (pas de GDD, pas d'ADR)
> **Engine**: Godot 4.7.2 (GDScript), export web

## Goal

Un jeu de défense vu du dessus où le joueur protège un cristal avec son héros et des tours, et où chaque compétence choisie réagit aux autres pour créer des combos.

## Scope

Le MVP du brief : 7 éléments, dans l'ordre de construction du brief.

## Build order

1. Héros, cristal et une vague d'ennemis (stories 001, 002).
2. Cycle de jeu, tours et premier combo glace + canon : la partie la plus risquée (stories 003, 004, 005).
3. Choix de 3 compétences et autres combos (story 006).
4. Écran de défaite avec l'arbre de compétences permanent (story 007).

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Héros déplacé en ZQSD, tir automatique vers la souris | Visual/Feel | Ready | N/A |
| 002 | Cristal de 100 PV, ennemis qui le ciblent, vagues croissantes | Integration | Ready | N/A |
| 003 | Cycle combat / construction, or gagné à chaque kill | Logic | Ready | N/A |
| 004 | Tours canon et glace posées au clic | Integration | Ready | N/A |
| 005 | Système de procs, avec le premier combo glace + canon | Logic | Ready | N/A |
| 006 | Choix d'1 compétence parmi 3, avec 2 autres combos | UI | Ready | N/A |
| 007 | À la mort, arbre de compétences, sauvegarde navigateur, rejouer | UI | Ready | N/A |
| 008 | Système de spécialisations et Archer | Integration | Ready | N/A |
| 009 | Maître du feu et Maître de l'eau | Integration | Ready | N/A |
| 010 | Maître de la terre et Maître du vent | Integration | Ready | N/A |
| 011 | Mage du temps et Gardien du cristal | Integration | Ready | N/A |
| 012 | Berserker et Piégeur | Integration | Ready | N/A |
| 013 | Équilibrage et finitions | UI | Ready | N/A |

## Après le MVP

Source : partie « Après le MVP — Spécialisations et builds » de `design/game-brief.md` ; stories 008 à 013, dans l'ordre de construction de cette partie.
