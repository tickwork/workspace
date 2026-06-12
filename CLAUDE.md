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

## Contexte du projet

**Tickwork** est un moteur de jeux incrémentaux réutilisable, écrit en Rust et jouable en
WASM (navigateur) comme en natif (Windows, Linux, macOS via eframe). **Holum**, un jeu sur
la physique de la matière (Planck → Univers, 15 phases), est le premier jeu construit dessus.

Le cahier des charges (`cahier_des_charges.md`) fait **autorité** sur toutes les décisions
d'architecture. En cas de doute, il prime sur toute reconstitution de mémoire. Le
`CHANGELOG.md` retrace l'historique des décisions, passe par passe.

### Architecture des crates

```
holum → tickwork → tickwork-engine
                 → tickwork-shell  → tickwork-engine
                 → tickwork-store  → tickwork-engine
```

- `tickwork-engine` (TW-engine) — moteur headless : World, SaveState, simulation, sérialisation, HMAC, calcul hors-ligne. Zéro dépendance vers les autres crates TW.
- `tickwork-shell` (TW-shell) — coque egui : composants, thèmes, localisation (fluent-rs), audio (kira). Détient tout le texte destiné à l'utilisateur.
- `tickwork-store` (TW-store) — persistance des octets : IndexedDB / fichier / Supabase.
- `tickwork` (TW) — facade : boucle eframe, `tickwork::launch`, `EventQueue`. Réexporte les types déclaratifs.
- `holum` — premier jeu (bin).
- `tickwork-inspector` — outil d'analyse/édition de sauvegardes.
- `tickwork-macros` — proc-macros optionnelles (ergonomie de déclaration de contenu).

Principe directeur : **le jeu est une donnée, pas un comportement**. Le moteur ne connaît
aucun contenu ; il évalue des `GameDefinition` / `UiDefinition` purement déclaratives.

## Règles de travail (conception du cahier des charges)

Ces règles s'appliquent dès qu'on travaille sur le `cahier_des_charges.md` ou sur une
décision de conception. Elles privilégient une réflexion conjointe, pas l'exécution rapide.

- Soumets les sujets à approfondir **un par un**.
- Ne pose **qu'une seule question à la fois**.
- N'intègre **aucun nouveau concept** dans le document sans qu'on en ait discuté ensemble.
- **Rappelle-moi** si je m'éloigne d'une décision déjà prise.
- Pour **chaque décision**, vérifie ses conséquences sur le reste du cahier des charges et
  signale les sections impactées (**cohérence transverse**). Relis les sections concernées
  dans le document plutôt que de te fier à ta mémoire de la conversation.
- À chaque nouvelle version du cahier des charges, **mets à jour le `CHANGELOG.md`**.
- Si tu penses que ces règles doivent évoluer pour gagner en robustesse, dis-le.

> Note : Claude Code a un biais vers l'action (exécuter des tâches de code). Ces règles
> demandent l'inverse sur la conception : ralentir, questionner, valider avant d'écrire.
> Garde cette discipline conversationnelle pour tout ce qui touche au cahier des charges.

## Règles d'édition du cahier des charges

- Édite **toujours** le CDC de façon **ciblée** (un outil d'édition par remplacement de
  passage, type `str_replace`/`edit`), sur les seuls passages concernés.
  **Ne régénère jamais** le document entier.
- Le document est dense (~1900 lignes) et contient de nombreux blocs ```rust ```` :
  une régénération complète risque la troncature ou la corruption des blocs de code.
- Flux d'une passe : (1) appliquer les décisions une par une par édition ciblée ;
  (2) vérifier l'intégrité (nombre de lignes cohérent, blocs de code équilibrés, aucune
  référence obsolète) ; (3) mettre à jour le `CHANGELOG.md` (nouvelle entrée **en tête**).
- Vérifie systématiquement qu'aucune référence obsolète ne subsiste après un renommage
  (ex. anciens noms de types/traits) — sauf dans le `CHANGELOG.md` qui conserve l'historique.

Avec Claude Code, le fichier est sur disque dans le dépôt cloné : l'édition ciblée est le
mode naturel, et `git diff` montre exactement ce qui change à chaque passe.

## Travailler avec le code (à partir de la Phase 1)

Quand l'implémentation démarre, le CDC cesse d'être isolé : confronte chaque décision au
code réel.

- Avant un renommage de type/trait, vérifie **tous** ses usages dans les crates.
- Quand tu supprimes ou modifies un champ d'une struct du CDC, repère ses références dans
  le code et signale les ruptures.
- `cargo check` / `cargo clippy` / `cargo test` valident qu'une structure proposée tient
  debout. Tous les commentaires de code sont en **anglais** (convention projet, 5.8.2).
- Ordre d'implémentation des objets du moteur (CDC 5.10) : socle absolu d'abord
  (`BigNum`, `Expr`, `Condition`, `Resource`, `Plugin`/`Contributor`, `StateMachine`,
  `Transition`, `Contribution`, `World`, boucle, sauvegarde minimale), puis couche jouable
  (`TW-shell` minimal, `TW-store` local), puis couche avancée (`Graph`, `Features`,
  `Prestige`/`Resetable`, `LevelConfig`, `Automation`, statistiques/historiques).
