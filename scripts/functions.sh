#!/bin/bash

function sealEnvFile() {

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
      --*)
        echo "Unknown option: $1"
        exit 1
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

  echo "SealedSecret created at: $sealedSecretYaml"

}


function sealYamlFile() {

  dataKey=""

  for arg in \"$@\"
    do
    case $1 in
      --secret-name)
        secretName=$2
      ;;
      --key)
        secretDataKey=$2
      ;;
      --namespace)
        namespace=$2
      ;;
      --output)
        outputDir=$2
      ;;
      --*)
        echo "Unknown option: $1"
        exit 1
      ;;
    esac
    shift
  done
  
  yamlFile="./secrets/$secretName.yaml"
  b64SecretYaml="unsafe-secret.yaml"
  sealedSecretYaml="$outputDir/$secretName-sealed-secret.yaml"
  certFile="./public-cert.pem"

  if [[ -n "$secretDataKey" ]]; then
    originalYamlFile=$yamlFile
    yamlFile="./secrets/$secretDataKey"
    cp $originalYamlFile $yamlFile
  fi

  kubeseal \
    --fetch-cert \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system > $certFile

  kubectl create secret generic $secretName \
    --dry-run=client \
    --namespace $namespace \
    --from-file=$yamlFile \
    --output yaml > $b64SecretYaml
  
  kubeseal \
    --cert $certFile \
    --secret-file $b64SecretYaml \
    --sealed-secret-file $sealedSecretYaml \
    --namespace $namespace \
    --scope namespace-wide

  rm $b64SecretYaml
  rm $certFile

  if [[ -n "$secretDataKey" ]]; then
    rm $yamlFile
  fi

  echo "SealedSecret created at: $sealedSecretYaml"
}