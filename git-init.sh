#!/bin/bash
# sets up a pre-commit hook to ensure that vault.yaml is encrypted
#
# credit goes to nick busey from homelabos for this neat little trick
# https://gitlab.com/NickBusey/HomelabOS/-/issues/355

if [ -d .git/ ]; then
rm .git/hooks/pre-commit
cat <<EOT >> .git/hooks/pre-commit
#!/bin/sh
for file in vault/*.yaml; do
    if ( git show :"\$file" | grep -q "\$ANSIBLE_VAULT;" ); then
        echo "[38;5;108mVault Encrypted. Safe to commit.[0m"
    else
        echo "[38;5;208mVault not encrypted!Run 'ansible-vault encrypt **file**' and try again.[0m"
        exit 1
    fi
done
EOT

fi

chmod +x .git/hooks/pre-commit