# Table Of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [How To Setup Metal3 Demo Environment](#how_to_setup_metal3_demo)

# Overview <a name="overview" />

This is test/demo environment for
[Metal Kubed - Bare Metal Host Provisioning for Kubernetes][metal3]
The purpose of this environment is demonstrate the capabilities
of [Kubernetes Cluster API][CAPI], for Kubernetes workload cluster
life cycle management.

The demo environment consists of a single "management cluster" VM
and automation to enable arbitrary numbers of VM hosts to be created
to emulate baremetal downstream cluster hosts (by default a single
controlplane and worker host will be created)

![Metal3 Demo Overview](images/Metal3-Demo-Overview.png)

# Prerequisites <a name="prerequisites" />

* Requires host with at least 32GB RAM & 200GB free disk space.
* [openSUSE Leap 15.6](https://get.opensuse.org/leap/15.6/), [openSUSE Tumbleweed](https://get.opensuse.org/tumbleweed/) or Ubuntu 22.04
* Should be run on baremetal, nested virt may also work but is not tested/supported.

# How To Setup Metal3 Demo Environment <a name="how_to_setup_metal3_demo" />
- Refer to the [Metal3 Setup Doc](./docs/setup/metal3-setup.md) for a walkthrough of the Metal3 Demo environment setup.
- The [RKE2 Setup Doc](./docs/setup/rke2-cluster.md) is a walkthrough of the deployment of a sample RKE2 cluster on the virtual bare metal hosts.

[CAPI]: https://cluster-api.sigs.k8s.io/introduction.html
[metal3]: https://github.com/metal3-io
