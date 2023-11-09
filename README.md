# Table Of Contents

- [Overview](#overview)
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
Metal3 Core VM has
all the pieces, namely CAPI (Cluster API) controller, RKE2 bootstrap provider
(CABPR), RKE2 control plane provider (CACPPR),
Metal3 infrastructure provider (CAPM3), Baremetal Operator, and
OpenStack Ironic, in a typical production Metal3 management cluster.

# Prerequisites <a name="prerequisites" />

* Host is expected to have one network bridge for the public network (i.e. tagged VLAN).
* Host with at least 32GB RAM & 200GB free disk space.
* Github credential (i.e. username/personal access token), for cloning repos

# How To Setup Metal3 Demo Environment <a name="how_to_setup_metal3_demo" />
- Refer to the [Metal3 Setup Doc](./docs/setup/metal3-setup.md) for a walkthrough of the Metal3 Demo environment setup.
- The [VBMH Setup Doc](./docs/setup/vbmh-setup.md) is a walkthrough of the setup of virtual machines to act as bare metal hosts.
- The [RKE2 Setup Doc](./docs/setup/rke2-cluster.md) is a walkthrough of the deployment of a sample RKE2 cluster on the virtual bare metal hosts.
- Example RKE2 deployment manifest exists [here](./docs/example-manifests/).
- For the automation of this deployment, [click here.](./scripts/README.md)

[CAPI]: https://cluster-api.sigs.k8s.io/introduction.html
[metal3]: https://github.com/metal3-io
