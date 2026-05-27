#!/usr/bin/env sh
# Set up Vale for a CI run (or a local CI simulation).
#
# Usage:
#   sh scripts/ci/setup-vale.sh          # generate config + copy vocab only
#   sh scripts/ci/setup-vale.sh --sync   # also run vale sync (on cache miss)
#
# What it does:
#   1. Generates .vale.ci.ini from .vale.ini: redirects StylesPath to the
#      writable .vale-styles/ dir and injects Packages into the global section
#      so vale sync knows what to download.
#   2. Copies committed vocab files from vale-config/vocabularies/ into the
#      CI StylesPath. See vale-config/README.md for the maintenance contract.
#   3. Runs vale sync only when --sync is passed (workflow passes it on a
#      cache miss; callers decide whether a sync is needed).
#
# Environment:
#   AI_TELLS_VERSION — ai-tells release tag to download (required; no default).
#   The workflow sets this from the AI_TELLS_VERSION env var.
#   For a local simulation: AI_TELLS_VERSION=1.11.0 sh scripts/ci/setup-vale.sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if [ -z "${AI_TELLS_VERSION:-}" ]; then
    printf 'setup-vale.sh: AI_TELLS_VERSION is not set.\n' >&2
    printf 'Set it inline: AI_TELLS_VERSION=1.11.0 sh scripts/ci/setup-vale.sh\n' >&2
    exit 1
fi

# Generate .vale.ci.ini.
# StylesPath is replaced with a local writable path (.vale-styles/).
# Packages must appear in the global section (before any [glob] header) so
# vale sync reads them; injecting on the same sed pass as StylesPath guarantees
# placement. GNU sed interprets \n in the replacement as a literal newline.
sed "s|StylesPath = .*|StylesPath = .vale-styles\nPackages = write-good, alex, https://github.com/tbhb/vale-ai-tells/releases/download/v${AI_TELLS_VERSION}/ai-tells.zip|" \
    "${REPO_ROOT}/.vale.ini" > "${REPO_ROOT}/.vale.ci.ini"

# Copy committed vocab into the CI StylesPath.
mkdir -p "${REPO_ROOT}/.vale-styles/config/vocabularies"
cp -r "${REPO_ROOT}/vale-config/vocabularies/." "${REPO_ROOT}/.vale-styles/config/vocabularies/"

# Sync style packages only when the caller requests it.
if [ "${1:-}" = "--sync" ]; then
    vale sync --config "${REPO_ROOT}/.vale.ci.ini"
fi
