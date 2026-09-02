#!/usr/bin/env bash
# sync-upstream.sh — podmienia vendorowany subset skilli na najnowszy emilkowalski/skills.
# Pliki w skills/ są kopią 1:1 — nie edytuj ich ręcznie (patrz UPSTREAM.md).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUBSET=(animate review-animations improve-animations find-animation-opportunities animation-vocabulary apple-design)
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 -q https://github.com/emilkowalski/skills.git "$TMP/src"
SHA="$(git -C "$TMP/src" rev-parse HEAD)"
for s in "${SUBSET[@]}"; do
  rm -rf "$ROOT/skills/$s"
  cp -R "$TMP/src/skills/$s" "$ROOT/skills/$s"
done
cp "$TMP/src/LICENSE" "$ROOT/LICENSE.upstream"
echo "upstream HEAD: $SHA"
echo "— zaktualizuj SHA w UPSTREAM.md i zbumpuj wersję w .claude-plugin/plugin.json"
git -C "$ROOT" status --short -- . || true
