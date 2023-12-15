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

- If you want to use your custom image (for instance the SLE Micro 5.5), you can export the variable `OS_LOCAL_IMAGE` with the path to your image:

1. Download the SLE Micro image from the [SUSE Customer Center](https://www.suse.com/download/sle-micro/). The current version supported is the 5.5 in raw format. 

**Note** The file downloaded is a xz compressed file. It must be uncompressed before using it as a valid image. 

2. Move the image downloaded into the local directory which will be defined in the environment var `OS_LOCAL_IMAGE`.

3. Execute the script to configure the host using the local image: 

  ```shell
  export OS_LOCAL_IMAGE=/path/to/image.raw
  ./02_configure_host.sh
  ```

4. Create management cluster

  ```shell
  ./03_launch_mgmt_cluster.sh
  ```

5. Apply the BareMetalHost manifests

```shell
kubectl apply -f ~/metal3-demo-files/baremetalhosts
```

The host will now be registered and inspected, which will take several minutes,
you can monitor progress via `kubectl get bmh` until the host reaches `available` state

```shell
 kubectl get bmh
NAME             STATE       CONSUMER   ONLINE   ERROR   AGE
controlplane-0   available              true             9m44s
worker-0         available              true             9m44s
```

## Development Notes

- You may pass `-vvv` at the end of the scripts to see more verbose output, or to pass arbitrary additional arguments to ansible-playbook
- You can interact with Ironic directly on the metal3-core VM for debugging e.g `ssh metal@192.168.125.99 baremetal node list`
- For more information about the BareMetalHost resource states refer to the [Metal3 documentation](https://github.com/metal3-io/baremetal-operator/blob/main/docs/BaremetalHost_ProvisioningState.png)
- If a BareMetalHost resource is stuck in the inspecting state, `virsh console` can be useful to view the inspection ramdisk output
