#!/bin/bash
set -euo pipefail

BASEDIR="$(dirname "$0")"
source ${BASEDIR}/basic-setup.sh

METAL3LOCKNAMESPACE="default"
METAL3LOCKCMNAME="metal3-lock"

trap 'catch $? $LINENO' EXIT

catch() {
  if [ "$1" != "0" ]; then
    echo "Error $1 occurred on $2"
    ${KUBECTL} delete configmap ${METAL3LOCKCMNAME} -n ${METAL3LOCKNAMESPACE}
  fi
}

# Get or create the lock to run all those steps just in a single node
# As the first node is created WAY before the others, this should be enough
# TODO: Investigate if leases is better
if [ $(${KUBECTL} get cm -n ${METAL3LOCKNAMESPACE} ${METAL3LOCKCMNAME} -o name | wc -l) -lt 1 ]; then
  ${KUBECTL} create configmap ${METAL3LOCKCMNAME} -n ${METAL3LOCKNAMESPACE} --from-literal foo=bar
else
  exit 0
fi

# Wait for metal3
while ! ${KUBECTL} wait --for condition=ready -n ${METAL3_CHART_TARGETNAMESPACE} $(${KUBECTL} get pods -n ${METAL3_CHART_TARGETNAMESPACE} -l app.kubernetes.io/name=metal3-ironic -o name) --timeout=10s; do sleep 2 ; done

# If rancher is deployed
if [ $(${KUBECTL} get pods -n ${RANCHER_CHART_TARGETNAMESPACE} -l app=rancher -o name | wc -l) -ge 1 ]; then
  cat <<-EOF | ${KUBECTL} apply -f -
  apiVersion: management.cattle.io/v3
  kind: Feature
  metadata:
    name: embedded-cluster-api
  spec:
    value: false
EOF

  # Disable Rancher webhooks for CAPI
  ${KUBECTL} delete mutatingwebhookconfiguration.admissionregistration.k8s.io mutating-webhook-configuration
  ${KUBECTL} delete validatingwebhookconfigurations.admissionregistration.k8s.io validating-webhook-configuration
  ${KUBECTL} wait --for=delete namespace/cattle-provisioning-capi-system --timeout=300s
fi

# Wait for capi-controller-manager
while ! ${KUBECTL} wait --for condition=ready -n ${METAL3_CAPISYSTEMNAMESPACE} $(${KUBECTL} get pods -n ${METAL3_CAPISYSTEMNAMESPACE} -l cluster.x-k8s.io/provider=cluster-api -o name) --timeout=10s; do sleep 2 ; done

# Wait for capm3-controller-manager, there are two pods, the ipam and the capm3 one, just wait for the first one
while ! ${KUBECTL} wait --for condition=ready -n ${METAL3_CAPM3NAMESPACE} $(${KUBECTL} get pods -n ${METAL3_CAPM3NAMESPACE} -l cluster.x-k8s.io/provider=infrastructure-metal3 -o name | head -n1 ) --timeout=10s; do sleep 2 ; done

# Wait for rke2-bootstrap-controller-manager
while ! ${KUBECTL} wait --for condition=ready -n ${METAL3_RKE2BOOTSTRAPNAMESPACE} $(${KUBECTL} get pods -n ${METAL3_RKE2BOOTSTRAPNAMESPACE} -l cluster.x-k8s.io/provider=bootstrap-rke2 -o name) --timeout=10s; do sleep 2 ; done

# Wait for rke2-control-plane-controller-manager
while ! ${KUBECTL} wait --for condition=ready -n ${METAL3_RKE2CONTROLPLANENAMESPACE} $(${KUBECTL} get pods -n ${METAL3_RKE2CONTROLPLANENAMESPACE} -l cluster.x-k8s.io/provider=control-plane-rke2 -o name) --timeout=10s; do sleep 2 ; done


# Clean up the lock cm

${KUBECTL} delete configmap ${METAL3LOCKCMNAME} -n ${METAL3LOCKNAMESPACE}
