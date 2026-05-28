#!/usr/bin/env sh
# Prepare Vale's repo-local StylesPath for local runs and CI.
#
# Usage:
#   sh scripts/setup-vale.sh          # sync packages only if config has changed
#   sh scripts/setup-vale.sh --sync   # force vale sync regardless
#
# The package list lives in .vale.ini. The accepted-term vocabulary lives in
# styles/config/vocabularies/ and is tracked directly in the repo — no copying needed.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STYLES_DIR="${REPO_ROOT}/styles"

config_hash="$(git -C "$REPO_ROOT" hash-object .vale.ini)"
hash_marker="${STYLES_DIR}/.vale-config-hash"

needs_sync=0
if [ "${1:-}" = "--sync" ]; then
    needs_sync=1
fi

# A stale marker alone is not enough: a partial CI cache restore can deliver the
# marker without the package dirs if the cache was written before a package was added.
if [ ! -f "$hash_marker" ] || [ "$(cat "$hash_marker")" != "$config_hash" ] \
    || [ ! -d "${STYLES_DIR}/ai-tells" ] \
    || [ ! -d "${STYLES_DIR}/write-good" ] \
    || [ ! -d "${STYLES_DIR}/alex" ]; then
    needs_sync=1
fi

if [ "$needs_sync" -eq 1 ]; then
    vale sync --config "${REPO_ROOT}/.vale.ini"
    mkdir -p "${STYLES_DIR}"
    printf '%s\n' "$config_hash" > "$hash_marker"
fi
