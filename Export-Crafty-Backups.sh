#!/usr/bin/env bash
set -euo pipefail

# Usage: ./mc-backup-export.sh <destination-directory> <crafty-host> <crafty-admin-user> <crafty-admin-pass>
DEST_DIR="$1"
CRAFTY_HOST="$2"    # e.g., "https://your.crafty.server:8443"
CRAFTY_USER="$3"
CRAFTY_PASS="$4"
DATESTAMP=$(date +"%Y-%m-%d")
BACKUP_ROOT="/var/opt/minecraft/crafty/crafty-4/backups"

# 1. Log in and get token
TOKEN=$(curl -s -X POST "${CRAFTY_HOST}/api/v2/auth/login" \
     -H "Content-Type: application/json" \
     -d "{\"username\":\"${CRAFTY_USER}\",\"password\":\"${CRAFTY_PASS}\"}" \
     | jq -r '.data.token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "Failed to authenticate with Crafty API"
    exit 1
fi

# 2. Fetch servers list (UUID + name)
SERVERS_JSON=$(curl -s -X GET "${CRAFTY_HOST}/api/v2/servers" \
     -H "Authorization: Bearer ${TOKEN}")

# Use jq to parse UUID and name arrays
mapfile -t SERVER_UUIDS < <(echo "$SERVERS_JSON" | jq -r '.data[].server_id')
mapfile -t SERVER_NAMES < <(echo "$SERVERS_JSON" | jq -r '.data[].server_name')

mkdir -p "$DEST_DIR"

# 3. Loop through servers and copy latest backup
for i in "${!SERVER_UUIDS[@]}"; do
    uuid="${SERVER_UUIDS[i]}"
    name="${SERVER_NAMES[i]}"
    server_backup_dir="${BACKUP_ROOT}/${uuid}"

    latest=$(find "$server_backup_dir" -type f -name '*.zip' -printf '%T@ %p\n' \
              | sort -n | tail -1 | awk '{print $2}')

    if [[ -z "$latest" ]]; then
        echo "  [!]  No backup found for '${name}' (UUID: ${uuid})"
        continue
    fi

    dest_file="${DEST_DIR}/${name}_${DATESTAMP}.zip"
    cp "$latest" "$dest_file"
    echo "  [+]  '${name}' → '${dest_file}'"
done
