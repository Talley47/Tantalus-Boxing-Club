#!/usr/bin/env bash
# Runs once when the Codespace is first created.
set -euo pipefail

echo "=== Tantalus Boxing Club: Codespaces post-create ==="

cd "$(dirname "$0")/.."

echo "--> Installing npm dependencies…"
npm install --no-audit --no-fund

echo "--> Configuring git…"
git config --global pull.rebase false
git config --global --add safe.directory "$(pwd)"

# Codespaces injects a GITHUB_TOKEN automatically; git is already authenticated
# via the credential helper, so pushes from inside the Codespace just work.

cat <<'EOF'

=====================================================================
Codespace ready.

To start the auto-commit-on-save watcher:

    npm run watch:commit

Every file change you save will be debounced (5s) and then
git add -A && git commit && git push origin main  automatically.

Tweak behavior with env vars:
    AUTO_COMMIT_DEBOUNCE_MS=2000 npm run watch:commit
    AUTO_COMMIT_PUSH=false       npm run watch:commit   # local-only
=====================================================================
EOF
