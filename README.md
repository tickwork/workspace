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
| [`docs`](https://github.com/tickwork/docs) | Cahier des charges, CHANGELOG |
| [`www`](https://github.com/tickwork/www) | Site web tickwork.dev |

## Branches

Ce dépôt maintient deux branches parallèles qui **ne se mergent jamais** :

| Branche | Rôle |
|---------|------|
| `main` | Refs stables — submodules pointent sur leur branche `main` |
| `dev` | Refs de développement — submodules pointent sur leur branche `dev` |

La promotion se fait submodule par submodule (PR `dev → main` dans chaque sous-dépôt), puis mise à jour de la ref dans `workspace/main`.

## Cloner le projet

```sh
git clone --recurse-submodules https://github.com/tickwork/workspace
```

Ou, si déjà cloné sans submodules :

```sh
git submodule update --init --recursive
```

## Scripts

Tous les scripts sont dans `scripts/`. Les exécuter depuis la **racine** de `workspace`.

| Script | Disponible sur | Rôle |
|--------|---------------|------|
| `scripts/pull.sh` | `main` et `dev` | `git pull` + `git submodule update` en une commande |
| `scripts/switch.sh <main\|dev>` | `main` et `dev` | Bascule de branche avec pull et mise à jour des submodules |
| `scripts/to-dev.sh` | `main` | Raccourci vers `switch.sh dev` |
| `scripts/to-main.sh` | `dev` | Raccourci vers `switch.sh main` |

### Utilisation typique

```sh
# Mettre à jour la branche courante et tous les submodules
./scripts/pull.sh

# Basculer vers dev (depuis main)
./scripts/to-dev.sh

# Basculer vers main (depuis dev)
./scripts/to-main.sh
```

## Workflows CI

Tous les workflows sont définis dans `workspace` et s'appliquent à l'ensemble du projet.

### `sync-shared-files.yml` — synchronisation entre branches

Déclenché par tout push sur `main` ou `dev`.

Copie automatiquement vers l'autre branche tous les fichiers modifiés, **sauf** :
- `.gitmodules` (contenu intentionnellement différent entre les branches)
- `scripts/to-main.sh` et `scripts/to-dev.sh` (scripts branch-specific)
- Les répertoires de submodules (gitlinks)

Cela garantit que `CLAUDE.md`, les workflows et les autres fichiers partagés restent synchronisés sans intervention manuelle.

### `update-submodule-ref.yml` — mise à jour automatique des gitlinks

Workflow réutilisable (`workflow_call`) appelé depuis chaque submodule via `notify-workspace.yml`.

À chaque push sur `main` ou `dev` d'un submodule, ce workflow met à jour le gitlink correspondant dans `workspace` sur la même branche. Inclut un mécanisme de retry (×5, backoff exponentiel) pour absorber les conflits de push simultanés.

### `compliance-check.yml` — vérification de conformité

Déclenché à chaque push sur `main` et tous les lundis à 08h00 UTC.

Vérifie que chaque dépôt de l'organisation `tickwork` :
1. Possède le fichier `.github/workflows/notify-workspace.yml`
2. Possède le secret `TW_WORKSPACE_CI_TOKEN`

En cas d'écart, crée (ou met à jour) une GitHub Issue dans `workspace` — ce qui déclenche une notification email. Les dépôts à exclure sont listés dans `.github/workspace-exclusions.txt`.

## Secrets requis

| Secret | Où | Rôle |
|--------|----|------|
| `TW_WORKSPACE_CI_TOKEN` | Dans chaque submodule | Permet d'appeler le workflow réutilisable de `workspace` |
| `TW_WORKSPACE_CI_TOKEN` | Dans `workspace` | Permet aux workflows CI de pusher sur `main`/`dev` et de créer des issues |

Un seul PAT (scope `repo`) suffit, configuré sous le même nom dans tous les dépôts.

## Règles de contribution

- Pusher **directement** sur `main` ou `dev` dans ce dépôt ombrelle — pas de PR.
- Les PRs sont réservées aux submodules (code Rust).
- Ne jamais proposer de PR `dev → main` dans cet ombrelle.
- Toute modification de `CLAUDE.md` est automatiquement synchronisée sur l'autre branche par la CI.

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
