#!/usr/bin/env bash
set -euo pipefail

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
git pull origin "$BRANCH"
git submodule update --init --recursive
echo "Branche $BRANCH et submodules mis à jour."
