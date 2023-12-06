# Intro

## RKE2 Workload Cluster Deployment on Metal<sup>3</sup>

This is a step-by-step guide on deploying RKE2 workload clusters on the SUSE Metal<sup>3</sup> Demo environment.

### Pre-requisites

- A fully functioning Metal<sup>3</sup> deployment
- Available virtual bare metal hosts

## Deploying the Workload Cluster

1. Deploy the control plane

```shell
cd docs/example-manifests/dhcp/
kubectl apply -f rke2-control-plane.yaml
```

2. Verify that the control plane is properly provisioned

```shell
$ clusterctl describe cluster sample-cluster
  NAME                                                    READY  SEVERITY  REASON  SINCE  MESSAGE
  Cluster/sample-cluster                                  True                     22m
  ├─ClusterInfrastructure - Metal3Cluster/sample-cluster  True                     27m
  ├─ControlPlane - RKE2ControlPlane/sample-cluster        True                     22m
  │ └─Machine/sample-cluster-chflc                        True                     23m
```

3. Deploy the agent

```shell
kubectl apply -f rke2-agent.yaml
```

4. Verify that the agent is properly provisioned and has successfully joined the cluster

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
