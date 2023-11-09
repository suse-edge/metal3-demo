# Intro

## Metal<sup>3</sup>

Metal<sup>3</sup> (Metal-Kubed) is an open source tool that provides components for bare metal host management utilizing
the Kubernetes native API. (see https://metal3.io/)

### Pre-requisite Dependencies

Currently requires an Ubuntu (22.04 LTS) host to enable testing on Equinix.

1. Create a non-root user with sudo access

If one does not already exist e.g:

```
sudo useradd auser -m -s /bin/bash
sudo echo "auser ALL=NOPASSWD: ALL" > /etc/sudoers.d/auser
sudo su - auser
```

2. Clone this metal3-demo repo

```shell
git clone https://github.com/suse-edge/metal3-demo.git
```

3. Install pre-requisite packages

```shell
cd metal3-demo
./01_prepare_host.sh
```

## Deploying the SUSE Edge Metal<sup>3</sup> Demo

1. (optional) customize extra_vars.yml

If desired the defaults from `extra_vars.yml` can be customized, copy the file and export `EXTRA_VARS_FILE` to reference the copied file location.

2. Define virsh egress network (This configuration is specific to step 4)
    - CD into the libvirt directory within the metal3-demo that was cloned earlier
    - Define and start the network
   ```shell
   virsh net-define egress.xml; virsh net-start egress
   ```
    - If you plan not to use the virsh networks, you will need to set up your own network bridges.

3. Configure the host

- In the main directory of the repository, execute the script to configure the host:

  ```shell
  ./02_configure_host.sh
  ```

4. Create management cluster

  ```shell
  ./03_launch_mgmt_cluster.sh
  ```

5. Assuming you are using the default configuration you can ssh into the management cluster VM as follows:

- Core VM Running Metal3: `ssh metal@192.168.125.99` or `virsh console metal3-core`

## Development Notes

- You may pass `-vvv` at the end of the scripts to see more verbose output, or to pass arbitrary additional arguments to ansible-playbook
