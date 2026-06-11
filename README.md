# Tickwork — dépôt ombrelle

Ce dépôt agrège, via des submodules Git, l'ensemble des dépôts du projet Tickwork.

## Vision

**Tickwork** est un moteur de jeux incrémentaux réutilisable, jouable dans un navigateur web ou nativement sur desktop (Windows, Linux, macOS). Il est conçu pour porter plusieurs jeux distincts construits sur les mêmes abstractions. Le premier jeu est **Holum**.

## Architecture

La dépendance entre crates est strictement orientée :

```
holum → tickwork (TW)  → tickwork-engine  (TW-engine)
                       → tickwork-shell   (TW-shell)  → tickwork-engine
                       → tickwork-store   (TW-store)  → tickwork-engine
tickwork-macros  (proc-macros, utilisées par TW-engine)
tickwork-inspector (outil CLI, indépendant)
```

## Dépôts

| Dépôt | Rôle |
|-------|------|
| [`tickwork-engine`](https://github.com/tickwork/tickwork-engine) | Moteur headless — simulation, sérialisation, `World`, sauvegardes |
| [`tickwork-shell`](https://github.com/tickwork/tickwork-shell) | Crate UI partagée — egui, localisation (fluent), thèmes, audio (kira) |
| [`tickwork-store`](https://github.com/tickwork/tickwork-store) | Couche persistance — IndexedDB/fichier + sync Supabase |
| [`tickwork-macros`](https://github.com/tickwork/tickwork-macros) | Proc-macros pour les plugins Tickwork |
| [`tickwork`](https://github.com/tickwork/tickwork) | Crate facade — boucle eframe, `tickwork::launch`, `EventQueue` |
| [`tickwork-inspector`](https://github.com/tickwork/tickwork-inspector) | Outil CLI d'inspection et réparation de fichiers de sauvegarde |
| [`holum`](https://github.com/tickwork/holum) | Premier jeu incrémental basé sur Tickwork |
| [`docs`](https://github.com/tickwork/docs) | Documentation projet (cahier des charges, CHANGELOG) |
| [`www`](https://github.com/tickwork/www) | Site web tickwork.dev |

> **`tickwork-store`** n'est pas encore enregistré comme submodule (dépôt distant à créer).

## Cloner le projet complet

```sh
git clone --recurse-submodules https://github.com/tickwork/tickwork
```

Ou, si le dépôt est déjà cloné sans submodules :

```sh
git submodule update --init --recursive
```

## Stack technique

| Composant | Choix |
|-----------|-------|
| Langage | Rust |
| Cible web | WebAssembly (trunk) |
| UI + boucle | egui + eframe |
| Sérialisation | serde + RON |
| Localisation | fluent-rs |
| Audio | kira |
| Backend | Supabase |
| Grands nombres | `BigNum` maison `(f64, i32)` |

## Licence

MIT OR Apache-2.0 — voir chaque dépôt pour les détails.
