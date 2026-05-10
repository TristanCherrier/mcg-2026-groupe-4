# MCG 2026 - Groupe 4

Projet réalisé dans le cadre du cours MCG

## Description

Jeu 3D composé de 3 niveaux enchaînés, chacun avec un gameplay différent. Le joueur accumule des points tout au long de la partie. Un score trop bas en cours de jeu renvoie au début.

---

## Niveaux

### Niveau 1 - Salle de TP
Vous incarnez un **robot** qui roule dans une salle de TP. Trouvez et validez les 3 écrans d'ordinateur pour passer au niveau suivant.

**Contrôles :**
- `Z Q S D` - rouler
- Souris - regarder
- `V` - changer de vue (1ère / 3ème personne)

---

### Niveau 2 - Couloir motorisé
Vous pilotez une **voiture** dans un couloir. Passez les 3 checkpoints dans l'ordre puis atteignez la ligne d'arrivée. Chaque checkpoint répare le véhicule.

> ⚠️ Si votre score atteint **-150**, la partie repart depuis le niveau 1.

**Contrôles :**
- `Z` - accélérer
- `Q / D` - diriger
- `Espace` - frein à main

---

### Niveau 3 - Réacteur Mirande
Vous pilotez un **vaisseau spatial** dans un réacteur. Décollez, suivez les balises, traversez les 3 anneaux dans l'ordre, puis posez-vous sur la couronne verte.

**Contrôles :**
- `Z` - monter et avancer
- `S` - redescendre
- `Q / D` - se déplacer latéralement
- `Espace` - forte poussée (consomme de l'énergie)
- Souris - orienter la caméra (indépendant du vaisseau)

---

## Techniques notables

- Caméra 3ème personne anti-collision via **SpringArm3D** sur les 3 niveaux
- Système de **score et d'énergie** global via un autoload `GameState`
- Physique via `RigidBody3D` (voiture et vaisseau) et `RigidBody3D` + `CharacterBody3D` (robot)
- Détection de collision et checkpoints via `Area3D`

---

## Stack

| Outil | Version |
|-------|---------|
| Godot | 4.6 |
| Langage | GDScript |
| Rendu | Forward Plus |
| Résolution | 1600 × 900 |

---

## Lancer le projet

1. Ouvrir Godot 4.6
2. Importer le dossier du projet
3. Lancer avec `F5` ou le bouton **Lancer**
