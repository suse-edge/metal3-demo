# Intro

## Metal<sup>3</sup>

Metal<sup>3</sup> (Metal-Kubed) is an open source tool that provides components for bare metal host management utilizing
the Kubernetes native API. (see https://metal3.io/)

### Pre-requisite Dependencies

Please check [README.md](../../README.md) for supported operating systems. If you use openSUSE, please
ensure you have "kernel-default" (not kernel-default-base) installed as kernel-default-base does not provide
the modules necessary for starting virtual machines.

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

## Configure the host environment

1. (optional) customize extra_vars.yml

If desired the defaults from `extra_vars.yml` can be customized, copy the file and export `EXTRA_VARS_FILE` to reference the copied file location:

For example to test a dual-stack deployment with static-ips:

```
cp extra_vars.yml ~
echo "libvirt_network_dhcp: false" >> ~/extra_vars.yml
echo "libvirt_network_ipv6: true" >> ~/extra_vars.yml
export EXTRA_VARS_FILE="~/extra_vars.yml"
```

2. Configure the host

- In the main directory of the repository, execute the script to configure the host:

  ```shell
  ./02_configure_host.sh
  ```

## Build images

  ```shell
  ./03_build_images.sh
  ```

Note this configures the environment to deploy management and downstream clusters with [openSUSE Leap Micro 6.0](https://get.opensuse.org/leapmicro/6.0/),
for [SLMicro 6.0](https://documentation.suse.com/sle-micro/6.0/) follow the additional steps below.

### Enable deploying with SLEMicro

If you want to use SLEMicro then a few additional steps are required:

1. Download the SLE Micro image from the [SUSE Customer Center](https://www.suse.com/download/sle-micro/). The version must be 6.0 in raw format.

**Note** The file downloaded is a xz compressed file. It must be uncompressed before using it as a valid image.

2. Move the image downloaded into the local directory which will be defined in the environment variable `OS_LOCAL_IMAGE`.

3. Generate a registration code so we can install additional packages when customizing the downloaded image, this is defined in the environment variable `EIB_REGISTRATION_CODE`.

4. Execute the script to configure the host using the local image:

  ```shell
  export OS_LOCAL_IMAGE=/path/to/image.raw
  export EIB_REGISTRATION_CODE=<generated registration code>
  ./03_build_images.sh
  ```

## Deploy the management cluster and prepare hosts

1. Create management cluster

  ```shell
  ./04_launch_mgmt_cluster.sh
  ```

2. Apply the BareMetalHost manifests

```shell
kubectl apply -f ~/metal3-demo-files/baremetalhosts
```

The host will now be registered and inspected, which will take several minutes,
you can monitor progress via `kubectl get bmh` until the host reaches `available` state

```shell
kubectl get bmh
```

The expected output should resemble the following:

```
NAME             STATE       CONSUMER   ONLINE   ERROR   AGE
controlplane-0   available              true             9m44s
worker-0         available              true             9m44s
```

## Testing with Static IPs

It is possible to disable the libvirt DHCP server via the `libvirt_network_dhcp` ansible variable, as mentioned earlier in the `EXTRA_VARS_FILE` example.

This disables the `<dhcp>` stanza in the `external` network (check with `virsh net-dumpxml external`), and configures the BareMetalHost resources with a static IP via a secret containing nmstate syntax, e.g:

```yaml
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: controlplane-0
  labels:
    cluster-role: control-plane
spec:
  online: true
  bootMACAddress: "00:bc:1f:c3:8f:f0"
  bmc:
    address: redfish-virtualmedia://192.168.125.1:8000/redfish/v1/Systems/112815c5-b60f-4753-86d9-b25063c7bfc3
    disableCertificateVerification: true
    credentialsName: controlplane-0-credentials
  preprovisioningNetworkDataName: controlplane-0-networkdata
---
apiVersion: v1
kind: Secret
metadata:
  name: controlplane-0-networkdata
type: Opaque
stringData:
  networkData: |
    interfaces:
    - name: enp1s0
      type: ethernet
      state: up
      mac-address: "00:bc:1f:c3:8f:f0"
      ipv4:
        address:
        - ip:  "192.168.125.200"
          prefix-length: "24"
        enabled: true
        dhcp: false
    dns-resolver:
      config:
        server:
        - "192.168.125.1"
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: "192.168.125.1"
        next-hop-interface: enp1s0
```

This networkData is consumed by [nm-configurator](https://github.com/suse-edge/nm-configurator) at two stages during deployment:

- During inspection the IPA ramdisk image runs nmc to configure networking so it can connect back to the ironic/inspector APIs
- During first-boot the EIB-prepared image contains a script which runs nmc via combustion during the prepare phase

## Development Notes

- You may pass `-vvv` at the end of the scripts to see more verbose output, or to pass arbitrary additional arguments to ansible-playbook
- You can interact with Ironic directly on the management-cluster VM for debugging e.g `ssh metal@192.168.125.99 baremetal node list`
- For more information about the BareMetalHost resource states refer to the [Metal3 documentation](https://github.com/metal3-io/baremetal-operator/blob/main/docs/BaremetalHost_ProvisioningState.png)
- If a BareMetalHost resource is stuck in the inspecting state, `virsh console` can be useful to view the inspection ramdisk output
- Note that you may need to `export LIBVIRT_DEFAULT_URI="qemu:///system"` to access the VMs via `virsh` as a non-root user

## Testing with ipv6/dual-stack

It is possible to ipv4/ipv6 networks via the `libvirt_network_ipv4` and `libvirt_network_ipv6` ansible variables, as mentioned earlier in the `EXTRA_VARS_FILE` example.

This enables/disables the relevant libvirt network, and also where appropriate configures networking for the deployed cluster and hosts manifests.
