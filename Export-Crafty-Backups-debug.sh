#!/usr/bin/env bash
set -euo pipefail

# Debug mode (uncomment if you want full command tracing)
# set -x

if [[ $# -lt 4 ]]; then
    echo "Usage: $0 <destination-dir> <crafty-host> <username> <password>"
    exit 1
fi

DEST_DIR="$1"
CRAFTY_HOST="$2"   # e.g. https://yourcrafty:8443
CRAFTY_USER="$3"
CRAFTY_PASS="$4"
DATESTAMP=$(date +"%Y-%m-%d")
BACKUP_ROOT="/var/opt/minecraft/crafty/crafty-4/backups"

mkdir -p "$DEST_DIR"

echo "[*] Logging into Crafty at $CRAFTY_HOST as $CRAFTY_USER..."

TOKEN=$(curl -sk -X POST "${CRAFTY_HOST}/api/v2/auth/login" \
     -H "Content-Type: application/json" \
     -d "{\"username\":\"${CRAFTY_USER}\",\"password\":\"${CRAFTY_PASS}\"}" \
     | jq -r '.data.token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "[!] Failed to authenticate – check host/credentials"
    exit 1
fi
echo "[+] Got API token"

echo "[*] Fetching server list..."
SERVERS_JSON=$(curl -sk -X GET "${CRAFTY_HOST}/api/v2/servers" \
     -H "Authorization: Bearer ${TOKEN}")

# Show raw JSON (debug)
echo "[DEBUG] Server JSON response:"
echo "$SERVERS_JSON" | jq '.'

# Extract values
mapfile -t SERVER_UUIDS < <(echo "$SERVERS_JSON" | jq -r '.data[].server_id')
mapfile -t SERVER_NAMES < <(echo "$SERVERS_JSON" | jq -r '.data[].server_name')

if [[ ${#SERVER_UUIDS[@]} -eq 0 ]]; then
    echo "[!] No servers found from API"
    exit 1
fi

echo "[+] Found ${#SERVER_UUIDS[@]} servers"

# Loop through servers
for i in "${!SERVER_UUIDS[@]}"; do
    uuid="${SERVER_UUIDS[i]}"
    name="${SERVER_NAMES[i]}"
    server_backup_dir="${BACKUP_ROOT}/${uuid}"

    echo "[*] Checking backups for '${name}' (UUID: ${uuid}) in ${server_backup_dir}"

    if [[ ! -d "$server_backup_dir" ]]; then
        echo "[!] Backup directory not found: $server_backup_dir"
        continue
    fi

    latest=$(find "$server_backup_dir" -type f -name '*.zip' -printf '%T@ %p\n' \
              | sort -n | tail -1 | awk '{print $2}')

    if [[ -z "$latest" ]]; then
        echo "[!] No .zip backups found for $name"
        continue
    fi

    dest_file="${DEST_DIR}/${name}_${DATESTAMP}.zip"
    cp "$latest" "$dest_file"
    echo "[+] Copied latest backup for $name → $dest_file"
done
