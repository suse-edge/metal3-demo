# Intro

## Virtual Bare Metal Host Deployment On Metal<sup>3</sup>

This is a step-by-step guide on deploying Virtual Machines that act as Bare Metal Hosts
on the SUSE Metal<sup>3</sup> Demo environment using Sushy-Tools Virtual Redfish BMC.

### Pre-requisites

- A fully functioning Metal<sup>3</sup> deployment

## Deploying Sushy-Tools and the Virtual Machines

Define and start a default storage pool

```shell
sudo virsh pool-define-as default dir - - - - "/default"
sudo virsh pool-build default
sudo virsh pool-start default
sudo virsh pool-autostart default
```

Create storage for virtual machines

```shell
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/node1.qcow2 30G
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/node2.qcow2 30G
```

- This is so that one virtual machine acts as a control plane and another as a worker node.
  You can add as many worker nodes as you wish.

Install Dependencies

```shell
sudo DEBIAN_FRONTEND=noninteractive apt install apache2-utils -y
sudo pip install sushy-tools
sudo DEBIAN_FRONTEND=noninteractive apt install podman -y
```

- apache2-utils is so that we can use `htpasswd`, podman is so that we can run Sushy-Tools in a container

Create the Virtual Machines

```shell
virt-install --name node-1 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/node1.qcow2 --network bridge=m3-egress,model=virtio --osinfo detect=on --console pty,target_type=virtio --noautoconsole --graphics vnc --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1
virt-install --name node-2 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/node2.qcow2 --network bridge=m3-egress,model=virtio --osinfo detect=on --console pty,target_type=virtio --noautoconsole --graphics vnc --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1
```

- This assumes you will be running 1 control plane and 1 worker node.

Create a directory to store sushy-tools related files and navigate into it

```shell
mkdir ~/vbmc; cd ~/vbmc
```

Create the sushy.config file

```shell
cat << EOF > ~/vbmc/sushy.config
SUSHY_EMULATOR_AUTH_FILE = '/root/vbmc/auth.conf'
SUSHY_EMULATOR_SSL_CERT = '/root/vbmc/cert.pem'
SUSHY_EMULATOR_SSL_KEY = '/root/vbmc/key.pem'
SUSHY_EMULATOR_LISTEN_IP = '0.0.0.0'
SUSHY_EMULATOR_VMEDIA_DEVICES = {
    "Cd": {
        "Name": "Virtual CD",
        "MediaTypes": [
            "CD",
            "DVD"
        ]
    },
    "Floppy": {
        "Name": "Virtual Removable Media",
        "MediaTypes": [
            "Floppy",
            "USBStick"
        ]
    }
}
EOF
```

Add this line to /etc/hosts

```text
192.168.125.100 media.suse.baremetal
```

- This is necessary for DNS resolutions for Metal3 in the metal3-demo environment.

## The following steps take place within the `~/vbmc` directory.

Create Password Configuration

```shell
htpasswd -b -B -c auth.conf foo foo
```

- Defaults are for simplicity, feel free to change.
- This is the authentication into Redfish running on Sushy tools.

Create SSL Certificates

```shell
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 365 --noenc -subj "/C=/ST=/L=/O=/OU=/CN="
```

- Metal3 requires SSL when accessing the nodes.

Start the sushy-tools container

```shell
sudo podman run -d --rm --privileged --name sushy-tools -v ${HOME}/vbmc:/root/vbmc:Z -v /var/run/libvirt:/var/run/libvirt:Z -e SUSHY_EMULATOR_CONFIG=/root/vbmc/sushy.config -p 8000:8000 quay.io/metal3-io/sushy-tools:latest sushy-emulator
```

- Depending on your environment/directories, you may need to edit the paths within the command.

Save the IP Address of the machine in a variable

```shell
IP_ADDR=$(ifconfig | grep "bond0: " -A 1 | awk '/inet / {print $2}')
```

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