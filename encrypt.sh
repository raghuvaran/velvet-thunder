#!/bin/bash
# Encrypt the receipts SQLite DBs for vault storage
# Usage: ./encrypt.sh
# Requires: RECEIPTS_KEY env var or VAULT_SECRETS_FILE pointing to JSON with 'passphrase'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
TOOLS_DIR="${RECEIPTS_TOOLS_DIR:-$(dirname "$SCRIPT_DIR")/receipts}"

DB_PATH="${VAULT_DB_PATH:-$TOOLS_DIR/receipts.db}"
PRICES_DB_PATH="${VAULT_PRICES_DB_PATH:-$TOOLS_DIR/prices.db}"
SECRETS_FILE="${VAULT_SECRETS_FILE:-}"

# Get the passphrase
if [ -n "${RECEIPTS_KEY:-}" ]; then
    KEY="$RECEIPTS_KEY"
elif [ -n "$SECRETS_FILE" ] && [ -f "$SECRETS_FILE" ]; then
    KEY=$(python3 -c "import json; print(json.load(open('$SECRETS_FILE'))['passphrase'])")
else
    echo "ERROR: Set RECEIPTS_KEY env var or VAULT_SECRETS_FILE path"
    exit 1
fi

if [ ! -f "$DB_PATH" ]; then
    echo "ERROR: Database not found at $DB_PATH"
    exit 1
fi

mkdir -p "$DATA_DIR"

# Encrypt with AES-256-CBC using PBKDF2 key derivation
openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$DB_PATH" \
    -out "$DATA_DIR/vault.enc" \
    -pass "pass:$KEY"

echo "Encrypted $(stat -c%s "$DB_PATH" 2>/dev/null || stat -f%z "$DB_PATH") bytes → $DATA_DIR/vault.enc ($(stat -c%s "$DATA_DIR/vault.enc" 2>/dev/null || stat -f%z "$DATA_DIR/vault.enc") bytes)"

# Encrypt prices.db if it exists
if [ -f "$PRICES_DB_PATH" ]; then
    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
        -in "$PRICES_DB_PATH" \
        -out "$DATA_DIR/prices.enc" \
        -pass "pass:$KEY"
    echo "Encrypted $(stat -c%s "$PRICES_DB_PATH" 2>/dev/null || stat -f%z "$PRICES_DB_PATH") bytes → $DATA_DIR/prices.enc ($(stat -c%s "$DATA_DIR/prices.enc" 2>/dev/null || stat -f%z "$DATA_DIR/prices.enc") bytes)"
else
    echo "WARN: prices.db not found — run generate-prices-db.py first"
fi
