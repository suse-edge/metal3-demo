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

2. Configure the host

- In the main directory of the repository, execute the script to configure the host:

  ```shell
  ./02_configure_host.sh
  ```

3. Create management cluster

  ```shell
  ./03_launch_mgmt_cluster.sh
  ```

4. Copy the BareMetalHost manifest files to the metal3-core VM

```shell
scp ~/metal3-demo-hosts/*.yaml metal@192.168.125.99:/home/metal
```

SSH Into the metal3-core VM

```shell
ssh metal@192.168.125.99
```

Apply the bare metal node YAML files

```shell
kubectl apply -f controlplane_0.yaml
kubectl apply -f worker_0.yaml
```

- You can monitor the progress of the provisioning using the following commands:
    - `watch -n 2 kubectl get bmh`
    - `watch -n 2 baremetal node list`
- A `manageable` or `available` state (respective to which command is used) is the desired state.
  It may take a few minutes for provisioning to complete.
- Using `baremetal node list` may show `manageable` immediately after creating the nodes,
  but this is only temporary, we want to wait for it to say `manageable` after it has been inspected.
- If there is an issue during the provisioning process. Take the UUID of the baremetal node
  and run `baremetal node show UUID` for a detailed output on what might have gone wrong.

## Development Notes

- You may pass `-vvv` at the end of the scripts to see more verbose output, or to pass arbitrary additional arguments to ansible-playbook
