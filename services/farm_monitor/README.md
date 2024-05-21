# Farm_monitor

Ansible tasks to do functions for farm_monitor and farm_device.

- Build docker images from the farm_monitor and farm_device repositories.
- Configure device (eg. Raspberry Pi) to run farm_monitor and farm_device.

## Build Docker Images
The `fd_container_builder.yaml` playbook will build the docker images for the farm_device repository.

The `fm_container_builder.yaml` playbook will build the docker images for the farm_monitor repository.

These playbooks will build the docker images on the local machine and either push them to the docker hub or load them locally

The playbooks will prompt for the following information:
- The versions to tag the docker images with.
- The branch or tag to build the docker images from.
- Whether to push the docker images to the docker hub or load them locally.

The playbooks will prompt for the user to enter this information. Optionally, these options can be passed as an extra variable.


### Example Specifying the Tag as an Extra Variable
```bash
> ansible-playbook services/farm_monitor/fm_container_builder.yaml --extra-vars "tag=v0.3,v0.3.4"
```

```bash
> ansible-playbook services/farm_monitor/fd_container_builder.yaml --extra-vars "tag=v0.3,v0.3.4"
```
### Example Specifying the Tag at the Prompt
```bash
> ansible-playbook services/farm_monitor/fm_container_builder.yaml
Enter the version to tag the fm container images with [latest]: v0.3,v0.3.4
```

```bash
> ansible-playbook services/farm_monitor/fd_container_builder.yaml
Enter the version to tag the fd container images with [latest]: v0.3,v0.3.4
```