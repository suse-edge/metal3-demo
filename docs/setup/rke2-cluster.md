# Intro

## RKE2 Workload Cluster Deployment on Metal<sup>3</sup>

This is a step-by-step guide on deploying RKE2 workload clusters on the SUSE Metal<sup>3</sup> Demo environment.

### Pre-requisites

- A fully functioning Metal<sup>3</sup> deployment
- Available BareMetalHost resources (check with `kubectl get bmh`)

## Deploying the Workload Cluster

1. Deploy the control plane

```shell
cd ~/metal3-demo-files/example-manifests
kubectl apply -f rke2-control-plane.yaml
```

2. Verify that the control plane is properly provisioned

```shell
clusterctl describe cluster sample-cluster
```

The expected output should resemble the following:

```
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
clusterctl describe cluster sample-cluster
```

The expected output should resemble the following:

```
NAME                                                    READY  SEVERITY  REASON  SINCE  MESSAGE
Cluster/sample-cluster                                  True                     25m
├─ClusterInfrastructure - Metal3Cluster/sample-cluster  True                     30m
├─ControlPlane - RKE2ControlPlane/sample-cluster        True                     25m
│ └─Machine/sample-cluster-chflc                        True                     27m
└─Workers
  └─MachineDeployment/sample-cluster                    True                     22m
    └─Machine/sample-cluster-56df5b4499-zfljj           True                     23m
```

## Workload Cluster Deprovisioning

The workload cluster may be deprovisioned by deleting the resources applied in the creation steps above, e.g:

```shell
cd ~/metal3-demo-files/example-manifests
kubectl delete -f rke2-agent.yaml
kubectl delete -f rke2-control-plane.yaml
```

This triggers deprovisioning of the BareMetalHost resources, which may take several minutes, after which they should be in available state again:


```shell
> kubectl get bmh
NAME             STATE            CONSUMER                            ONLINE   ERROR   AGE
controlplane-0   deprovisioning   sample-cluster-controlplane-vlrt6   false            10m
worker-0         deprovisioning   sample-cluster-workers-785x5        false            10m

...

> kubectl get bmh
NAME             STATE       CONSUMER   ONLINE   ERROR   AGE
controlplane-0   available              false            15m
worker-0         available              false            15m
```

