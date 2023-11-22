# Intro

## Virtual Bare Metal Host Deployment On Metal<sup>3</sup>

This is a step-by-step guide on deploying Virtual Machines that act as Bare Metal Hosts
on the SUSE Metal<sup>3</sup> Demo environment using Sushy-Tools Virtual Redfish BMC.

### Pre-requisites

- A fully functioning Metal<sup>3</sup> deployment

## Deploying the Virtual Machines

Create storage for virtual machines

```shell
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/node1.qcow2 30G
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/node2.qcow2 30G
```

- This is so that one virtual machine acts as a control plane and another as a worker node.
  You can add as many worker nodes as you wish.

Create the Virtual Machines

```shell
virt-install --name node-1 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/node1.qcow2 --network bridge=m3-egress,model=virtio --osinfo detect=on --console pty,target_type=virtio --noautoconsole --graphics vnc --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1
virt-install --name node-2 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/node2.qcow2 --network bridge=m3-egress,model=virtio --osinfo detect=on --console pty,target_type=virtio --noautoconsole --graphics vnc --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1
```

- This assumes you will be running 1 control plane and 1 worker node.

- This grep command is specific to the network configuration typically found on an Equinix server,
  on other environments you will need to manually add your ip address to the `IP_ADDR` variable for future commands.

Grab the mac addresses and Sushy-Tools IDs of the virtual machines and save in variables

```shell
NODE1ID=$(curl -L https://$IP_ADDR:8000/redfish/v1/Systems/node-1 -k -u "foo:foo" | jq -r '.UUID')
NODE2ID=$(curl -L https://$IP_ADDR:8000/redfish/v1/Systems/node-2 -k -u "foo:foo" | jq -r '.UUID')

NODE1MAC=$(virsh dumpxml node-1 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
NODE2MAC=$(virsh dumpxml node-2 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
```

- The first 2 commands grab the UUID's from Sushy-Tools, the second two commands grab the MAC addresses from virsh.

### Create the BMH manifests using the virtual machine information

#### Control plane Node

```shell
cat << EOF > ~/vbmc/node1.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bmc-1-credentials
  namespace: default
type: Opaque
data:
  username: Zm9vCg==
  password: Zm9vCg==
---
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: bmc-1
  namespace: default
  labels:
    cluster-role: control-plane
spec:
  online: true
  bootMACAddress: $NODE1MAC
  bmc:
    address: redfish-virtualmedia://$IP_ADDR:8000/redfish/v1/Systems/$NODE1ID
    disableCertificateVerification: true
    credentialsName: bmc-1-credentials
EOF
```

#### Worker Node

```shell
cat << EOF > ~/vbmc/node2.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bmc-2-credentials
  namespace: default
type: Opaque
data:
  username: Zm9vCg==
  password: Zm9vCg==
---
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: bmc-2
  namespace: default
  labels:
    cluster-role: worker
spec:
  online: true
  bootMACAddress: $NODE2MAC
  bmc:
    address: redfish-virtualmedia://$IP_ADDR:8000/redfish/v1/Systems/$NODE2ID
    disableCertificateVerification: true
    credentialsName: bmc-2-credentials
EOF
```

Copy the baremetal node YAMLs to the metal3-core VM

```shell
scp node*.yaml metal@192.168.125.99:
```

SSH Into the metal3-core VM

```shell
ssh metal@192.168.125.99
```

Apply the bare metal node YAML files

```shell
kubectl apply -f node1.yaml
kubectl apply -f node2.yaml
```

- You can monitor the progress of the provisioning using the following commands:
    - `watch -n 2 baremetal node list`
    - `watch -n 2 kubectl get bmh`
- A `manageable` or `available` state (respective to which command is used) is the desired state.
  It may take a few minutes for provisioning to complete.
- Using `baremetal node list` may show `manageable` immediately after creating the nodes,
  but this is only temporary, we want to wait for it to say `manageable` after it has been inspected.
- If there is an issue during the provisioning process. Take the UUID of the baremetal node
  and run `baremetal node show UUID` for a detailed output on what might have gone wrong.  
