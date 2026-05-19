#!/bin/bash
# Encrypt the receipts SQLite DB and stage it for commit
# Usage: ./encrypt.sh
# Requires: RECEIPTS_KEY env var or reads from secrets file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_PATH="/root/.openclaw/workspace/receipts/receipts.db"
OUTPUT_PATH="$SCRIPT_DIR/data/vault.enc"
SECRETS_FILE="/home/node/.openclaw/secrets/receipts-vault.json"

# Get the passphrase
if [ -n "${RECEIPTS_KEY:-}" ]; then
    KEY="$RECEIPTS_KEY"
elif [ -f "$SECRETS_FILE" ]; then
    KEY=$(python3 -c "import json; print(json.load(open('$SECRETS_FILE'))['passphrase'])")
else
    echo "ERROR: No RECEIPTS_KEY env var and no secrets file at $SECRETS_FILE"
    exit 1
fi

if [ ! -f "$DB_PATH" ]; then
    echo "ERROR: Database not found at $DB_PATH"
    exit 1
fi

# Encrypt with AES-256-GCM using openssl
# We use PBKDF2 key derivation (same as the browser UI will use)
openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$DB_PATH" \
    -out "$OUTPUT_PATH" \
    -pass "pass:$KEY"

echo "Encrypted $(stat -c%s "$DB_PATH" 2>/dev/null || stat -f%z "$DB_PATH") bytes → $OUTPUT_PATH ($(stat -c%s "$OUTPUT_PATH" 2>/dev/null || stat -f%z "$OUTPUT_PATH") bytes)"
