#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
if [[ "$TARGET" != "main" && "$TARGET" != "dev" ]]; then
  echo "Usage: $0 <main|dev>" >&2
  exit 1
fi

# Guard: refuse if working tree is dirty
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Erreur : modifications non commitées. Commitez ou stashez avant de basculer." >&2
  exit 1
fi

CURRENT=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
if [[ "$CURRENT" == "$TARGET" ]]; then
  echo "Déjà sur la branche $TARGET."
  exit 0
fi

git checkout "$TARGET"
git pull origin "$TARGET"
git submodule update --init --recursive
echo "Basculé sur $TARGET."
