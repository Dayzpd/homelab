#!/bin/bash

set -e

contextName=$( kubectl config view --minify -o jsonpath='{.contexts[0].name}' )

for arg in \"$@\"
  do
  case $1 in
    --context)
      contextName=$2
      kubectl config use-context $contextName
    ;;
  esac
  shift
done

. ./scripts/functions.sh

clusterName=$( kubectl config view --minify -o jsonpath='{.clusters[0].name}' )

sealEnvFile \
  --secret-name "cloudflare-token" \
  --namespace "cert-manager" \
  --output "./infrastructure/cert-manager/overlays/$clusterName"

sealEnvFile \
  --secret-name "github-token" \
  --namespace "flux-system" \
  --output "./infrastructure/flux/overlays/$clusterName"

sealYamlFile \
  --secret-name "nfs-nvme-driver-config" \
  --key "driver-config-file.yaml" \
  --namespace "democratic-csi" \
  --output "./infrastructure/democratic-csi/overlays/$clusterName/nfs-nvme"

sealYamlFile \
  --secret-name "nfs-hdd-media-driver-config" \
  --key "driver-config-file.yaml" \
  --namespace "democratic-csi" \
  --output "./infrastructure/democratic-csi/overlays/$clusterName/nfs-hdd-media"

sealYamlFile \
  --secret-name "nfs-hdd-nvr-driver-config" \
  --key "driver-config-file.yaml" \
  --namespace "democratic-csi" \
  --output "./infrastructure/democratic-csi/overlays/$clusterName/nfs-hdd-nvr"

sealEnvFile \
  --secret-name "openvpn-credentials" \
  --namespace "media-server" \
  --output "./apps/media-server/overlays/$clusterName"