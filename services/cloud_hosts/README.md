# Cloud Hosts
This directory contains playbooks to create/destroy cloud hosts on DigitalOcean.


## Configuration
The configuration for the cloud hosts is stored in the [droplet.yaml](vars/droplet.yaml) file.

## Usage
To create the cloud hosts as specified in the configuration file, run the following command:
```bash
ansible-playbook services/cloud_hosts/create_hosts.yaml
```

This calls the create_droplet file for each droplet specified. It also creates any block storage volumes specified in the configuration file.

The second half of the [create_hosts.yaml](create_hosts.yaml) runs against all DigitalOcean droplets to create the user if neeeded. Since root login is disabled afterwards, this skips the user creation if the host is unreachable via the root user. If the play is run 5 times within 10 minutes, fail2ban will ban the IP address (probably the local machine). You can unban the IP by logging in through the web console and running `fail2ban-client set sshd unbanip <ip>`.