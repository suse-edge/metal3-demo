# Intro

## RKE2 Workload Cluster Deployment on Metal<sup>3</sup>

This is a step-by-step guide on deploying RKE2 workload clusters on the SUSE Metal<sup>3</sup> Demo environment.

### Pre-requisites

- A fully functioning Metal<sup>3</sup> deployment
- Two available virtual bare metal hosts

## Deploying the Workload Cluster

- For simplicity, we will continue working in the `vbmc` directory created in the [VBMH Readme](./vbmh-setup.md).

```shell
cd ~/vbmc
```

1. Get the MAC address of the VBMH that will act as the control plane and save it as a variable

```shell
CONTROLPLANEMAC=$(virsh dumpxml node-1 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
```

2. Create an XML file with the following information:

```shell
cat << EOF > ~/vbmc/host.xml
<host mac='$CONTROLPLANEMAC' ip='192.168.125.200'/>
EOF
```

3. Perform a live update to the egress network to give a static IP to the VBMH

```shell
virsh net-update egress add-last ip-dhcp-host host.xml --live
```

4. SSH into the metal3-core VM
```shell
ssh metal@192.168.125.99
```

5. Download the example manifests

```shell
curl https://raw.githubusercontent.com/suse-edge/metal3-demo/main/docs/example-manifests/dhcp/rke2-control-plane.yaml > rke2-control-plane.yaml
curl https://raw.githubusercontent.com/suse-edge/metal3-demo/main/docs/example-manifests/dhcp/rke2-agent.yaml > rke2-agent.yaml
```

- This configuration is specific to the [Metal3](./metal3-setup.md) and [VBMH](./vbmh-setup.md) setup docs.
  If you have made your own changes or have differences in your setup, you may need to update the manifests.
- This configuration assumes DHCP-only network setup.

6. Deploy the control plane

```shell
kubectl apply -f rke2-control-plane.yaml
```

7. Verify that the control plane is properly provisioned

```shell
$ clusterctl describe cluster sample-cluster
  NAME                                                    READY  SEVERITY  REASON  SINCE  MESSAGE
  Cluster/sample-cluster                                  True                     22m
  ├─ClusterInfrastructure - Metal3Cluster/sample-cluster  True                     27m
  ├─ControlPlane - RKE2ControlPlane/sample-cluster        True                     22m
  │ └─Machine/sample-cluster-chflc                        True                     23m
```

8. Deploy the agent

```shell
kubectl apply -f rke2-agent.yaml
```

9. Verify that the agent is properly provisioned and has successfully joined the cluster

```shell
$ clusterctl describe cluster sample-cluster
  NAME                                                    READY  SEVERITY  REASON  SINCE  MESSAGE
  Cluster/sample-cluster                                  True                     25m
  ├─ClusterInfrastructure - Metal3Cluster/sample-cluster  True                     30m
  ├─ControlPlane - RKE2ControlPlane/sample-cluster        True                     25m
  │ └─Machine/sample-cluster-chflc                        True                     27m
  └─Workers
    └─MachineDeployment/sample-cluster                    True                     22m
      └─Machine/sample-cluster-56df5b4499-zfljj           True                     23m
```
