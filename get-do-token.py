# script to read an ansible-vault file and return the
# 'secret_do_token' value. The vault file can be encrypted
# or not. If encrypted, the file will be re-encrypted after.
# The script relies on the presence of the 'vault_pass.txt'
# file to decrypt the vault file as needed.

# Usage: get-do-token.py

import yaml
import subprocess

ANSIBLE_VAULT_FILE = 'vars/vault.yaml'
FILE_DECRYPYTED_FLAG = False

# check if the ansible-vault file is encrypted by reading the first line
# of the file and comparing it to the ansible-vault header
with open(ANSIBLE_VAULT_FILE, 'r') as f:
    if f.readline().strip() == '$ANSIBLE_VAULT;1.1;AES256':
        # the file is encrypted, so decrypt it and suppress the output
        subprocess.call(['ansible-vault', 'decrypt', ANSIBLE_VAULT_FILE],stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
        FILE_DECRYPYTED_FLAG = True

with open(ANSIBLE_VAULT_FILE, 'r') as f:
    data = yaml.load(f, Loader=yaml.FullLoader)
    print(data['secret_do_token'])

# if the file was decrypted, then re-encrypt it and suppress the output
if FILE_DECRYPYTED_FLAG:
    subprocess.call(['ansible-vault', 'encrypt', ANSIBLE_VAULT_FILE],stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
