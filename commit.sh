#!/bin/bash
# Encrypt and commit the receipts database
# Usage: ./commit.sh [commit message]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Encrypt first
bash encrypt.sh

# Stage and commit
git add data/vault.enc
git add -A docs/

MSG="${1:-Update vault $(date -u +%Y-%m-%d_%H:%M:%S)}"
git commit -m "$MSG" || { echo "Nothing to commit"; exit 0; }
git push origin main

echo "✅ Committed and pushed: $MSG"
