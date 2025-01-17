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

sealSecret \
  --secret-name "cloudflare-token" \
  --namespace "cert-manager" \
  --output "./infrastructure/cert-manager/overlays/$clusterName"

sealSecret \
  --secret-name "github-token" \
  --namespace "flux-system" \
  --output "./infrastructure/flux/overlays/$clusterName"