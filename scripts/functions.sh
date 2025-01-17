#!/bin/bash

function sealSecret() {

  for arg in \"$@\"
    do
    case $1 in
      --secret-name)
        secretName=$2
      ;;
      --namespace)
        namespace=$2
      ;;
      --output)
        outputDir=$2
      ;;
    esac
    shift
  done

  envFile="./secrets/$secretName.env"
  b64SecretYaml="unsafe-secret.yaml"
  sealedSecretYaml="$outputDir/$secretName-sealed-secret.yaml"
  certFile="./public-cert.pem"

  kubeseal \
      --fetch-cert \
      --controller-name=sealed-secrets-controller \
      --controller-namespace=kube-system > $certFile

  kubectl create secret generic $secretName \
    --from-env-file=$envFile \
    --dry-run=client \
    --output yaml > $b64SecretYaml

  kubeseal \
    --cert $certFile \
    --secret-file $b64SecretYaml \
    --sealed-secret-file $sealedSecretYaml \
    --namespace $namespace \
    --scope namespace-wide

  rm $b64SecretYaml
  rm $certFile

}