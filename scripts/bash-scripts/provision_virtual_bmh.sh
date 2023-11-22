#!/bin/bash

set -e

set -o pipefail

printf "This script assumes you've already ran the SUSE Edge M3 demo script.\n"

echo "Please enter your server's IP Address:"
read IP_ADDR

echo $IP_ADDR

cd ~
HOMEDIR=$(pwd)
VBMCDIR="$HOMEDIR/metal3-demo/vbmc"

if [ ! -d $VBMCDIR ]; then
  mkdir $VBMCDIR
fi

cd $VBMCDIR

qemu-img create -f qcow2 /var/lib/libvirt/images/node1.qcow2 30G
qemu-img create -f qcow2 /var/lib/libvirt/images/node2.qcow2 30G
qemu-img create -f qcow2 /var/lib/libvirt/images/node3.qcow2 30G

# We create 3 VMs that act as bare metal hosts

echo "Creating 3 virtual nodes"

virt-install --name node-1 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/node1.qcow2 --network bridge=m3-egress,model=virtio --osinfo detect=on --console pty,target_type=virtio --noautoconsole --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1

virt-install --name node-2 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/node2.qcow2 --network bridge=m3-egress,model=virtio --osinfo detect=on --console pty,target_type=virtio --noautoconsole --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1

virt-install --name node-3 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/node3.qcow2 --network bridge=m3-egress,model=virtio --osinfo detect=on --console pty,target_type=virtio --noautoconsole --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1


echo "Finished creating 3 virtual nodes"

# We automatically grab the mac address of each vm and the sushy-tools id of each vm

NODE1ID=$(curl -L https://$IP_ADDR:8000/redfish/v1/Systems/node-1 -k -u "foo:foo" | jq -r '.UUID')
NODE2ID=$(curl -L https://$IP_ADDR:8000/redfish/v1/Systems/node-2 -k -u "foo:foo" | jq -r '.UUID')
NODE3ID=$(curl -L https://$IP_ADDR:8000/redfish/v1/Systems/node-3 -k -u "foo:foo" | jq -r '.UUID')

echo Node 1 ID: $NODE1ID
echo Node 2 ID: $NODE2ID
echo Node 3 ID: $NODE3ID

NODE1MAC=$(virsh dumpxml node-1 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
NODE2MAC=$(virsh dumpxml node-2 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
NODE3MAC=$(virsh dumpxml node-3 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")

echo Node 1 Mac: $NODE1MAC
echo Node 2 Mac: $NODE2MAC
echo Node 3 Mac: $NODE3MAC

# We create custom BMH yamls using the data we collected earlier

cat << EOF > $VBMCDIR/node1.yaml
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

cat << EOF > $VBMCDIR/node2.yaml
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

cat << EOF > $VBMCDIR/node3.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bmc-3-credentials
  namespace: default
type: Opaque
data:
  username: Zm9vCg==
  password: Zm9vCg==
---
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: bmc-3
  namespace: default
  labels:
    cluster-role: worker
spec:
  online: true
  bootMACAddress: $NODE3MAC
  bmc:
    address: redfish-virtualmedia://$IP_ADDR:8000/redfish/v1/Systems/$NODE3ID
    disableCertificateVerification: true
    credentialsName: bmc-3-credentials
EOF


# We run an ansible playbook that completes setting up the VBMC BMHs
cd $HOMEDIR/metal3-demo/scripts/playbooks
ansible-playbook vm-playbook.yaml -e "VBMCDIR=$VBMCDIR" -vvv
