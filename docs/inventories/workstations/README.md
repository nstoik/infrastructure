# Workstations Inventory

Documentation for the `workstations` inventory, which manages personal desktops and laptops.

## Hosts

| Hostname | Type | Description |
|---|---|---|
| `DESKTOP-SJ8NAUC` | WSL | Nelson's desktop |
| `DESKTOP-3PU4LF6` | WSL | Nelson's laptop |

## Ansible Setup

### Prerequisites

Create a vault password file and encrypt your secrets:

```bash
# Create the vault password file (gitignored)
echo 'your-vault-password' > vault_pass_workstations.txt

# Copy the example vault and fill in real values
cp inventories/workstations/group_vars/all/vault.yaml.example \
   inventories/workstations/group_vars/all/vault.yaml

# Edit vault.yaml with real values, then encrypt
ansible-vault encrypt inventories/workstations/group_vars/all/vault.yaml \
  --vault-id workstations@./vault_pass_workstations.txt \
  --encrypt-vault-id workstations
```

### Running the Playbook

```bash
source scripts/setenv.sh
source scripts/select-inventory.sh workstations
ansible-playbook playbooks/workstations.yaml
```

To limit to a single host:

```bash
ansible-playbook playbooks/workstations.yaml --limit=DESKTOP-SJ8NAUC
```

### What the Playbook Does

- Installs base packages (`git`, `jq`, `inxi`, `qrencode`, etc.)
- Installs GitHub-released binaries: `gping`, `trippy`
- Sets up the user and dotfiles (workstation profile)
- Sets timezone

## Manual Installs — Windows

These applications are installed manually on Windows and are not managed by Ansible.

### Applications

| App | Source | Notes |
|---|---|---|
| **Bitwarden** | [bitwarden.com](https://bitwarden.com/download/) | Password manager — install before anything else |
| **Claude** | [claude.ai/download](https://claude.ai/download) | Desktop AI assistant |
| **VSCode** | [code.visualstudio.com](https://code.visualstudio.com/) | Editor — also available via `winget install Microsoft.VisualStudioCode` |
| **GitHub Desktop** | [desktop.github.com](https://desktop.github.com/) | GUI Git client |
| **Tailscale** | [tailscale.com/download/windows](https://tailscale.com/download/windows) | VPN — WSL automatically routes through the Windows client |
| **WiFiMan** | Microsoft Store | Wi-Fi analyzer by Ubiquiti |
| **OrcaSlicer** | [GitHub releases](https://github.com/SoftFever/OrcaSlicer/releases) | 3D printer slicer |
| **Auto Dark Mode** | [GitHub releases](https://github.com/AutoDarkMode/Windows-Auto-Night-Mode/releases) | Automatic Windows dark/light mode switching |

## WSL Setup

Shell environment, dotfiles, and SSH configuration are managed via the [dotfiles repo](https://github.com/nstoik/dotfiles). See that repo for WSL-specific setup steps.
