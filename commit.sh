#!/bin/bash
# Encrypt and commit the receipts database
# Usage: ./commit.sh [commit message]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Regenerate prices.db from latest receipts data
python3 /root/.openclaw/workspace/receipts/generate-prices-db.py

# Encrypt both DBs
bash encrypt.sh

# Stage and commit
git add data/vault.enc data/prices.enc
git add -A docs/

# Fun commit messages that reveal nothing
FUN_MSGS=(
  "fed the hamsters"
  "another day another thunder"
  "velvet goes brrr"
  "the void stares back"
  "midnight snack"
  "shook the magic 8-ball"
  "the plot thickens"
  "added more cowbell"
  "recalibrated the flux capacitor"
  "the vibes have shifted"
  "whispers in the dark"
  "shuffled the deck"
  "one more for the road"
  "entropy increases"
  "the thunder rolls"
)
if [ -z "${1:-}" ]; then
  MSG="${FUN_MSGS[$((RANDOM % ${#FUN_MSGS[@]}))]}"
else
  MSG="$1"
fi
git commit -m "$MSG" || { echo "Nothing to commit"; exit 0; }
git push origin main

echo "✅ Committed and pushed: $MSG"
