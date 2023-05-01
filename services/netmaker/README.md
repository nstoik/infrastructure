# Netmaker
Ansible playbook for setting up a [Netmaker](https://www.netmaker.io/) server on a DigitalOcean droplet.

## Configuration
The configuration is in the [vars/netmaker.yaml](vars/netmaker.yaml) file.

There are two different configurations that can be installed. The community version and the enterprise version. Which vervion is installed is controlled by the `netmaker_ee` boolean variable in the [vars/netmaker.yaml](vars/netmaker.yaml) file.

The setup runs through the steps as outlined in the [Netmaker documentation](https://netmaker.readthedocs.io/en/master/quick-start.html) but makes the following changes.

 * The configuration files (including the docker compose file) are stored in the `~/netmaker` directory on the host.

## Usage
1. The [netmaker.yaml](netmaker.yaml) playbook sets up a digitalocean droplet with all the prequesite software and then installs the Netmaker server. To run the playbook, run the following command:

    ```bash
    ansible-playbook services/netmaker/netmaker.yaml
    ```

2. The [netmaker_config.yaml](netmaker_config.yaml) playbook configures the Netmaker server. To run the playbook, run the following command:

    ```bash
    ansible-playbook services/netmaker/netmaker_config.yaml
    ```

    The following items are configured:
    * Creates an admin user
    * Sets up and configures the nmctl cli app (see the [nmctl.yaml](tasks/nmctl.yaml) playbook) on the local machine
    * Creates the following networks:
        * monitoring - for monitoring devices and nodes using prometheus and grafana
        * personal - for my personal devices. To connect back to my home network, or to route traffic through my home network.
        * farm network - for network connectivity to devices for the farm monitoring system
    * Creates enrollment keys for the networks

3. After the playbook has run, the Netmaker server is ready to use. From a web browser, go to the [netmaker dashboard](https://dashboard.netmaker.stechsolutions.ca)
    * Login credentials are stored in Bitwarden.

4. After logging in create networks and access keys, add nodes and assign them to networks, then create external clients (eg. phones).

4. The following networks should be created:


### EE Usage
If the EE version is installed, there is a [grafana dashboard](https://grafana.netmaker.stechsolutions.ca/) and a [prometheus instance](https://prometheus.netmaker.stechsolutions.ca/) that can be used to monitor the Netmaker server.

TODO: Modify the docker compose files to point to the external prometheus and grafana instances. Then remove the prometheus and grafana containers from the Netmaker server.

The login for the grafana dashboard is `admin` and the password is stored in Bitwarden. The login for the prometheus instance is `Netmaker-Prometheus` and the password is the `secret_nm_license_key` (see the Ansbile vault).

## NMCTL
The [nmctl.yaml](tasks/nmctl.yaml) playbook installs the [nmctl command line tool](https://netmaker.readthedocs.io/en/master/nmctl.html). This tool can be used to interact with the Netmaker server from the command line.
