#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_FILE="$SCRIPT_DIR/inventory.ini"

MASTER_IP=$(aws ssm get-parameter --name "/k3s/master_ip" --query "Parameter.Value" --output text)
WEB_IP=$(aws ssm get-parameter --name "/k3s/web_ip" --query "Parameter.Value" --output text)

# Cleanup vechile IP-uri dacă există
sed -i '/\[master\]/,/^\[.*\]/ {/^[^[]/d}' "$INVENTORY_FILE"
sed -i '/\[web\]/,/^\[.*\]/ {/^[^[]/d}' "$INVENTORY_FILE"

# Adaugă IP-urile curente
awk -v m="$MASTER_IP" -v w="$WEB_IP" '
  BEGIN { done_m=0; done_w=0 }
  {
    print
    if ($0 ~ /^\[master\]/ && done_m==0) {
      print m " ansible_user=ubuntu ansible_ssh_private_key_file=deployer-key.pem ansible_ssh_common_args='\''-o StrictHostKeyChecking=no'\''"
      done_m=1
    }
    if ($0 ~ /^\[web\]/ && done_w==0) {
      print w " ansible_user=ubuntu ansible_ssh_private_key_file=deployer-key.pem ansible_ssh_common_args='\''-o StrictHostKeyChecking=no'\''"
      done_w=1
    }
  }
' "$INVENTORY_FILE" > "$INVENTORY_FILE.tmp" && mv "$INVENTORY_FILE.tmp" "$INVENTORY_FILE"

echo "✅ Inventory updated:"
cat "$INVENTORY_FILE"
