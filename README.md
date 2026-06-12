# Tickwork — dépôt ombrelle

Ce dépôt (`tickwork/workspace`) agrège via des submodules Git l'ensemble des dépôts du projet Tickwork. Il ne contient pas de code source : tout le code vit dans les submodules.

> **Attention — trois noms proches :**
> - `tickwork` (organisation GitHub) — héberge tous les dépôts
> - `tickwork` (crate Rust, dépôt `tickwork/tickwork`) — facade réexportant engine/shell/store
> - `workspace` (ce dépôt, `tickwork/workspace`) — l'ombrelle Git

## Vision

**Tickwork** est un moteur de jeux incrémentaux réutilisable, jouable dans un navigateur web (WebAssembly) ou nativement sur desktop (Windows, Linux, macOS via eframe). Le premier jeu est **Holum** (physique de la matière, Planck → Univers, 15 phases).

## Architecture des crates

```
holum → tickwork (TW)  → tickwork-engine  (TW-engine)
                       → tickwork-shell   (TW-shell)  → tickwork-engine
                       → tickwork-store   (TW-store)  → tickwork-engine
tickwork-macros    (proc-macros, dépendance optionnelle de TW-engine)
tickwork-inspector (outil CLI indépendant)
tickwork-demo      (démo standalone)
```

| Dépôt | Rôle |
|-------|------|
| [`tickwork-engine`](https://github.com/tickwork/tickwork-engine) | Moteur headless — simulation, sérialisation, `World`, sauvegardes |
| [`tickwork-shell`](https://github.com/tickwork/tickwork-shell) | UI partagée — egui, localisation (fluent-rs), thèmes, audio (kira) |
| [`tickwork-store`](https://github.com/tickwork/tickwork-store) | Persistance — IndexedDB / fichier / Supabase |
| [`tickwork-macros`](https://github.com/tickwork/tickwork-macros) | Proc-macros pour la déclaration de contenu |
| [`tickwork`](https://github.com/tickwork/tickwork) | Facade — boucle eframe, `tickwork::launch`, `EventQueue` |
| [`tickwork-inspector`](https://github.com/tickwork/tickwork-inspector) | CLI d'inspection et réparation de sauvegardes |
| [`tickwork-demo`](https://github.com/tickwork/tickwork-demo) | Démo standalone |
| [`holum`](https://github.com/tickwork/holum) | Premier jeu basé sur Tickwork |
| [`docs`](https://github.com/tickwork/docs) | Cahier des charges, CHANGELOG, CLAUDE.md |
| [`www`](https://github.com/tickwork/www) | Site web tickwork.dev |
| [`scripts`](https://github.com/tickwork/scripts) | Scripts utilitaires (pull, switch de branche, rotation de token) |

## Branches

Ce dépôt maintient deux branches parallèles qui **ne se mergent jamais** :

| Branche | Rôle |
|---------|------|
| `main` | Refs stables — submodules pointent sur leur branche `main` |
| `dev` | Refs de développement — submodules code pointent sur leur branche `dev` |

La promotion se fait submodule par submodule (PR `dev → main` dans chaque sous-dépôt), puis mise à jour automatique de la ref dans `workspace/main` via CI.

### Submodules à branche unique

`docs`, `www` et `scripts` n'ont qu'une branche `main`. Leurs gitlinks pointent sur `main` **dans les deux branches** de workspace (main et dev). Leur `notify-workspace.yml` met à jour les deux branches de workspace à chaque push.

## Cloner le projet

```sh
git clone --recurse-submodules https://github.com/tickwork/workspace
cd workspace
```

Si déjà cloné sans submodules :

```sh
git submodule update --init --recursive
```

## Scripts

Les scripts sont dans le submodule `scripts/` (dépôt [`tickwork/scripts`](https://github.com/tickwork/scripts)). Les exécuter depuis la **racine** de `workspace`.

| Script | Rôle |
|--------|------|
| `scripts/pull.sh` | Pull workspace + mise à jour et attachement des submodules |
| `scripts/to-dev.sh` | Bascule vers la branche `dev` |
| `scripts/to-main.sh` | Bascule vers la branche `main` |
| `scripts/sync-workspace.sh` | Resynchronise les gitlinks main et dev avec le HEAD des submodules |
| `scripts/rotate-token.sh` | Déploie `TW_WORKSPACE_CI_TOKEN` dans tous les repos de l'org |

### Workflow quotidien

```sh
# Mettre à jour la branche courante et tous les submodules
scripts/pull.sh

# Basculer vers dev
scripts/to-dev.sh

# Basculer vers main
scripts/to-main.sh
```

`pull.sh` affiche une ligne par submodule avec son nom, sa branche et son état :

```
workspace (dev)      | à jour
docs                 | main
holum                | dev
scripts              | main
tickwork             | dev
tickwork-demo        | dev
tickwork-engine      | dev
tickwork-inspector   | dev
tickwork-macros      | dev
tickwork-shell       | dev
tickwork-store       | dev
www                  | main
```

Si un submodule est en HEAD détachée (gitlink en retard sur le HEAD de sa branche), il apparaît comme `dev @ a1b2c3d (détaché)`. Lancer `scripts/sync-workspace.sh` pour resynchroniser.

### Résynchronisation manuelle

En cas de gitlinks obsolètes (submodules en HEAD détachée après un `pull`) :

```sh
scripts/sync-workspace.sh
```

Ce script resynchronise les branches `main` et `dev` de workspace avec le HEAD actuel de chaque submodule.

## CLAUDE.md

`CLAUDE.md` à la racine est un symlink vers `docs/CLAUDE.md`. Le contenu autoritaire vit dans le submodule `docs`.

## Workflows CI

### `update-submodule-ref.yml` — mise à jour automatique des gitlinks

Workflow réutilisable (`workflow_call`) appelé depuis chaque submodule via `notify-workspace.yml`.

À chaque push sur un submodule, ce workflow met à jour le gitlink correspondant dans `workspace` sur la branche appropriée. Inclut un mécanisme de retry (×5, backoff exponentiel) pour absorber les conflits de push simultanés.

### `compliance-check.yml` — vérification de conformité

Déclenché à chaque push sur `main` et tous les lundis à 08h00 UTC.

Vérifie que chaque dépôt de l'organisation `tickwork` :
1. Possède le fichier `.github/workflows/notify-workspace.yml`
2. Possède le secret `TW_WORKSPACE_CI_TOKEN`

En cas d'écart, crée (ou met à jour) une GitHub Issue dans `workspace`. Les dépôts à exclure sont listés dans `.github/workspace-exclusions.txt`.

## Secrets requis

| Secret | Où | Rôle |
|--------|----|------|
| `TW_WORKSPACE_CI_TOKEN` | Dans chaque submodule | Permet d'appeler le workflow réutilisable de `workspace` et de déclencher `notify-workspace.yml` |
| `TW_WORKSPACE_CI_TOKEN` | Dans `workspace` | Permet aux workflows CI de pusher sur `main`/`dev` et de créer des issues |

Un seul PAT (scope `repo`) suffit, configuré sous le même nom dans tous les dépôts. Pour le déployer ou le renouveler :

```sh
scripts/rotate-token.sh
```

## Règles de contribution

- Pusher **directement** sur `main` ou `dev` dans ce dépôt ombrelle — pas de PR.
- Les PRs sont réservées aux submodules (code Rust).
- Ne jamais proposer de PR `dev → main` dans cet ombrelle.

## Stack technique

| Composant | Choix |
|-----------|-------|
| Langage | Rust |
| Cible web | WebAssembly (trunk) |
| UI + boucle | egui + eframe |
| Sérialisation | serde + RON |
| Localisation | fluent-rs |
| Audio | kira |
| Persistance cloud | Supabase |
| Grands nombres | `BigNum` maison `(f64, i32)` |

## Licence

MIT OR Apache-2.0 — voir chaque dépôt pour les détails.
