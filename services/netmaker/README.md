# Netmaker
Ansible playbook for setting up a [Netmaker](https://www.netmaker.io/) server on a DigitalOcean droplet.

## Configuration
The configuration is in the [vars/netmaker.yaml](vars/netmaker.yaml) file.

The [community_install.yaml](tasks/community_install.yaml) playbook installs the community version of Netmaker. The [ee_install.yaml](tasks/ee_install.yaml) playbook installs the enterprise version of Netmaker.

## Usage
From a web browser, go to the [netmaker dashboard](https://dashboard.netmaker.stechsolutions.ca) and login with the credentials stored in Bitwarden.