# CLAUDE.md — Tickwork (dépôt ombrelle)

## Nature de ce dépôt

Ce dépôt est un **dépôt ombrelle Git** : il ne contient pas de code source directement, mais agrège les dépôts du projet via des submodules. Tout le code vit dans les submodules.

## Structure des submodules

| Chemin | Dépôt | Rôle |
|--------|-------|------|
| `tickwork-engine/` | github.com/tickwork/tickwork-engine | Moteur headless (librairie Rust) |
| `tickwork-shell/` | github.com/tickwork/tickwork-shell | UI partagée egui (librairie Rust) |
| `tickwork-store/` | github.com/tickwork/tickwork-store | Persistance (librairie Rust) — *submodule à venir* |
| `tickwork-macros/` | github.com/tickwork/tickwork-macros | Proc-macros (librairie Rust) |
| `tickwork/` | github.com/tickwork/tickwork | Facade — `tickwork::launch`, `EventQueue` |
| `tickwork-inspector/` | github.com/tickwork/tickwork-inspector | CLI inspection sauvegardes |
| `holum/` | github.com/tickwork/holum | Premier jeu (binaire Rust) |
| `docs/` | github.com/tickwork/docs | Documentation projet |
| `www/` | github.com/tickwork/www | Site web tickwork.dev |

## Règles de navigation

- Pour travailler sur un submodule, entre dans le répertoire correspondant.
- Chaque submodule est un dépôt Git indépendant avec sa propre branche `main`.
- Les commits dans un submodule ne remontent pas automatiquement dans l'ombrelle : après un commit dans un submodule, mettre à jour la référence dans l'ombrelle avec `git add <submodule>` + commit.

## Invariants d'architecture

1. **`tickwork-engine` est headless** : aucune dépendance UI, aucun texte affiché. Pas d'import de `tickwork-shell`, `eframe` ou `egui` dans ce crate.
2. **Les jeux dépendent uniquement de `tickwork`** (la facade), jamais directement de `tickwork-engine`, `tickwork-shell` ou `tickwork-store`.
3. **`tickwork-macros` est `proc-macro = true`** : pas de logique runtime, uniquement de la génération de code.
4. **Monothread acté** (PO-24) : pas de `std::thread`, pas de `tokio::spawn` dans le moteur ou la coque. L'async est réservé aux I/O de `tickwork-store`.
5. **Parité natif/WASM** : tout code dans `tickwork-engine`, `tickwork-shell` et `tickwork` doit compiler en WASM sans feature-flag dédié. Les différences plateforme se gèrent via `#[cfg(target_arch = "wasm32")]`.

## Cahier des charges

Le document de référence est `docs/cahier_des_charges.md` (version 0.12 au 2026-06-11). Il est la source de vérité pour les décisions d'architecture. En cas de contradiction entre ce fichier et le code, questionner plutôt que supposer.

## Conventions de commit

- Préfixes : `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`
- Un commit par crate/submodule concerné
- Les messages en français ou en anglais sont acceptés

## Ce dépôt ombrelle ne contient pas de workspace Cargo

Les crates Rust sont indépendantes et ne partagent pas de `Cargo.toml` racine. Chaque crate gère ses propres dépendances. Pour compiler un jeu ou lancer les tests, travailler directement dans le sous-dossier de la crate concernée.
