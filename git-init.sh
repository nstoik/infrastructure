#!/bin/bash
# sets up a pre-commit hook to ensure that vault.yaml is encrypted
#
# credit goes to nick busey from homelabos for this neat little trick
# https://gitlab.com/NickBusey/HomelabOS/-/issues/355

if [ -d .git/ ]; then
rm .git/hooks/pre-commit
cat <<'EOT' >> .git/hooks/pre-commit
#!/bin/sh
# Ensure any vault files are encrypted before allowing a commit.
# Checks both the legacy `vault/` directory and per-inventory vaults under `vaults/*/vault.yaml`.
for file in vault/*.yaml vaults/*/vault.yaml; do
    [ -e "$file" ] || continue
    if ( git show :"$file" | grep -q '^\$ANSIBLE_VAULT;' ); then
        echo "Vault Encrypted. Safe to commit."
    else
        echo "Vault not encrypted! Run 'ansible-vault encrypt \"$file\"' and try again."
        exit 1
    fi
done
EOT

fi

chmod +x .git/hooks/pre-commit