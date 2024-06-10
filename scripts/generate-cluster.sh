#!/bin/bash

set -e

capmoxTokenSecret=$( keyring get "proxmox" "capmox" )

export PROXMOX_URL="https://homex10.local.zachary.day:8006"
export PROXMOX_TOKEN="capmox@pve!capi"
export PROXMOX_SECRET=$capmoxTokenSecret

kubectl create cm calico \
  --from-file=./templates/calico.yaml \
  --dry-run=client \
  --output yaml > cluster/calico-config.yaml

clusterctl generate cluster homelab \
  --kubernetes-version v1.28.9 \
  --config ./clusterctl.yaml \
  --from ./templates/cluster-template-calico.yaml > ./cluster/proxmox-cluster.yaml