#!/bin/bash
# Pre-requisites. Cluster already running
export KUBECTL="/var/lib/rancher/rke2/bin/kubectl"
export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"

##################
# METAL3 DETAILS #
##################
export METAL3_CHART_TARGETNAMESPACE="metal3-system"
export METAL3_CAPISYSTEMNAMESPACE="capi-system"
export METAL3_RKE2BOOTSTRAPNAMESPACE="rke2-bootstrap-system"
export METAL3_CAPM3NAMESPACE="capm3-system"
export METAL3_RKE2CONTROLPLANENAMESPACE="rke2-control-plane-system"

###########
# RANCHER #
###########
export RANCHER_CHART_TARGETNAMESPACE="cattle-system"
export RANCHER_FINALPASSWORD="adminadminadmin"

die(){
  echo ${1} 1>&2
  exit ${2}
}