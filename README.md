# Table Of Contents

- [Overview](#overview)
  - [Networking](#networking)
- [Prerequisites](#prerequisites)
- [How To Setup Metal3 Demo Environment](#how_to_setup_metal3_demo)

# Overview <a name="overview" />

This is the demo environment for
[Metal Kubed - Bare Metal Host Provisioning for Kubernetes][metal3]
The purpose of this environment is demonstrate the capabilities
of [Kubernetes Cluster API][CAPI], for Kubernetes workload cluster
life cycle management. The demo environment consist of two VMs,
Metal3 Network Infra and Metal3 Core respectively.
![Metal3 Demo Overview](images/Metal3-Demo-Overview.png)
As depicted by the diagram above, the Metal3 Network Infra VM is designed
to emulate the infrastructure pieces, namely DNS, DHCP, and media server,
which are required by Metal3 and typically expected to be deployed outside
of the management cluster in a production environment. Metal3 Core VM has
all the pieces, namely CAPI (Cluster API) controller, RKE2 bootstrap provider
(CABPR), RKE2 control plane provider (CACPPR),
Metal3 infrastructure provider (CAPM3), Baremetal Operator, and
OpenStack Ironic, in a typical production Metal3 management cluster.
The external-dns controller on the Metal3 Core VM (management cluster)
is configured to use the PowerDNS running on the Metal3 Network Infra VM,
which illustrates what a production environment should look like.

## Networking <a name="networking" />

For security purposes, network segmentation is expected in production
environment, which usually consist of an internal provisioning network
for bare metal provisioning, and public network which is routable to
the internet. Therefore, the demo environment is designed to closely
align with a typically production use case. As such, the host where
the VMs are running is expected to have to networking bridges,
one for the provisioning network (BMC) and the other for the
public network (i.e. tagged VLAN).

# Prerequisites <a name="prerequisites" />

* Ansible >= 2.9.17. The environments were tested with ansible-core 2.11.12.
* KVM (i.e. qemu-kvm), preferably the latest and greatest. The environments
  were tested with qemu-kvm 2.11.
* Host is expected to have two network bridges, one for the provisioning
  network (BMC) and the other for the public network (i.e. tagged VLAN).
* Host with at least 32GB RAM & 200GB free disk space.
* Github credential (i.e. username/personal access token), for cloning repos
* genisoimage >= 1.1.11. You can install it from vendor repo. For example:

  ```console
  sudo zypper install genisoimage
  ```

* Install the required Ansible modules in `requirements.yml`, after
  installing Ansible from above.

  Either run this command line if using the system Ansible:
  ```console
  ansible-galaxy collection install -r requirements.yml
  ```

  Or run this command line if using the venv Ansible
  ```console
  bin/ansible-galaxy collection install -r requirements.yml
  ```

# How To Setup Metal3 Demo Environment <a name="how_to_setup_metal3_demo" />

1. Copy `extra_vars.yml.example` to `extra_vars.yml`.
2. Edit `extra_vars.yml` to make sure the values matches your
   networking infrastructure.
3. Run `setup_metal3_network_infra.sh` to create the Metal3 Network Infra VM.
4. Run `setup_metal3_core.sh` to create the Metal3 Core VM.
   NOTE: Metal3 Network Infra VM must be successfully created prior to creating
   the Metal3 Core VM.

# How To Use Metal3 Demo Environment <a name="how_to_use_metal3_demo" />

To login to the Metal3 Network Infra VM:

```console
ssh <vm_user>@<metal3_network_infra_public_ip>
```

You can alos use `virsh` to login the VM from serial console:

```console
virsh console metal3-network-infra
```

To login to the Metal3 Core VM:

```console
ssh <vm_user>@<metal3_core_public_ip>
```

You can alos use `virsh` to login the VM from serial console:

```console
virsh console metal3-core
```

To create a workload cluster, see https://github.com/rancher-sandbox/baremetal/tree/reorganize-tree/demo/clusterctl-examples.

[CAPI]: https://cluster-api.sigs.k8s.io/introduction.html
[cloud_init_network_config]: https://cloudinit.readthedocs.io/en/latest/reference/network-config.html
[metal3]: https://github.com/metal3-io
