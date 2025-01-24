#!/bin/bash

helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update

function inflateChart() {

  for arg in \"$@\"
    do
    case $1 in
      --context)
        contextName=$2
        kubectl config use-context $contextName
      ;;
      --release)
        releaseName=$2
      ;;
      --*)
        echo "Unknown option: $1"
        exit 1
      ;;
    esac
    shift
  done

  clusterName=$( kubectl config view --minify -o jsonpath='{.clusters[0].name}' )
  valuesFile="overlays/$clusterName/$releaseName-values.yaml"
  outputFile="overlays/$clusterName/$releaseName/$releaseName-csi.yaml"

  helm template $releaseName democratic-csi/democratic-csi \
    --namespace democratic-csi \
    --values $valuesFile \
    --version "0.14.7" > $outputFile

}

inflateChart --release "nfs-hdd-media" --context "homelab-admin@homelab"
inflateChart --release "nfs-hdd-nvr" --context "homelab-admin@homelab"
inflateChart --release "nfs-nvme" --context "homelab-admin@homelab"