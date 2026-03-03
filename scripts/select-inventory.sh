#!/usr/bin/env bash
# Helper to set ANSIBLE_INVENTORY and ANSIBLE_VAULT_IDENTITY_LIST for a named inventory
# Usage: source scripts/select-inventory.sh <inventory-name>

if [ "$#" -ne 1 ]; then
    echo "Usage: source scripts/select-inventory.sh <inventory-name>"
    return 1 2>/dev/null || exit 1
fi

INV_NAME="$1"

case "$INV_NAME" in
  home)
    export ANSIBLE_INVENTORY="./inventories/home"
    export ANSIBLE_VAULT_IDENTITY_LIST="home@./vault_pass.txt"
    echo "Selected inventory: home (./inventories/home)"
    ;;
  client_welca)
    export ANSIBLE_INVENTORY="./inventories/client_welca"
    export ANSIBLE_VAULT_IDENTITY_LIST="client_welca@./vault_pass_client_welca.txt"
    echo "Selected inventory: client_welca (./inventories/client_welca)"
    ;;
  *)
    echo "Unknown inventory: $INV_NAME"
    return 1 2>/dev/null || exit 1
    ;;
esac

echo "Exported ANSIBLE_INVENTORY=$ANSIBLE_INVENTORY"
echo "Exported ANSIBLE_VAULT_IDENTITY_LIST=$ANSIBLE_VAULT_IDENTITY_LIST"
