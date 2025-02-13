.PHONY: build-image
build-image:
	@cd ../image-builder/images/capi && make deps-proxmox && make build-proxmox-ubuntu-2404

.PHONY: init-capmox-proxmox-provider
init-proxmox-capi-provider:
	@clusterctl init \
		--config ./clusterctl.yaml \
		--infrastructure proxmox \
		--ipam in-cluster

.PHONY: delete-proxmox-capi-provider
delete-proxmox-capi-provider:
	@kubectl config use-context capmox
	@clusterctl delete \
		--config ./clusterctl.yaml \
		--infrastructure proxmox \
		--ipam in-cluster \
		--core cluster-api:v1.6.1 \
		--include-namespace \
		--include-crd

.PHONY: delete-capi
delete-capi:
	@kubectl config use-context capmox
	@clusterctl delete \
		--config ./clusterctl.yaml \
		--all \
		--include-namespace
	@clusterctl delete \
		--config ./clusterctl.yaml \
		--all \
		--include-namespace \
		--include-crd

.PHONY: generate-homelab-cluster
generate-homelab-cluster:
	@curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/calico.yaml > ./templates/calico.yaml
	@kubectl create cm calico \
		--from-file=./templates/calico.yaml \
		--dry-run=client \
		--output yaml > capi/homelab/calico-crs.yaml
	@rm ./templates/calico.yaml
	@curl -L -o ./templates/sealed-secrets-v0-28-0.yaml -H "User-Agent: curl" https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.28.0/controller.yaml
	@kubectl create cm sealed-secrets \
		--from-file=./templates/sealed-secrets-v0-28-0.yaml \
		--dry-run=client \
		--output yaml > capi/homelab/sealed-secrets-crs.yaml
	@rm ./templates/sealed-secrets-v0-28-0.yaml
	@clusterctl generate cluster homelab \
		--target-namespace homelab \
		--config ./clusterctl.yaml \
		--from ./templates/proxmox-cluster-template.yaml > capi/homelab/proxmox-cluster.yaml

.PHONY: apply-homelab-cluster-dry-run
apply-homelab-cluster-dry-run:
	@kubectl config use-context capmox
	@kubectl apply --dry-run=client --output=yaml -k ./capi/homelab

.PHONY: apply-homelab-cluster
apply-homelab-cluster:
	@kubectl config use-context capmox
	@kubectl apply --server-side -k ./capi/homelab

.PHONY: apply-homelab-cluster-dry-run
diff-homelab-cluster:
	@kubectl config use-context capmox
	@kubectl diff -k ./capi/homelab || true

.PHONY: delete-homelab-cluster
delete-homelab-cluster:
	@kubectl config use-context capmox
	@kubectl delete -k ./capi/homelab

.PHONY: get-homelab-kubeconfig
get-homelab-kubeconfig:
	@kubectl config use-context capmox
	@kubectl get -n homelab secret/homelab-kubeconfig -o jsonpath="{.data.value}" | base64 --decode > ./homelab-kubeconfig
	@KUBECONFIG="./homelab-kubeconfig:/home/${USER}/.kube/config" kubectl config view --flatten > merged
	@mv /home/${USER}/.kube/config /home/${USER}/.kube/config.bak
	@mv ./merged /home/${USER}/.kube/config
	@rm ./homelab-kubeconfig

.PHONY: delete-homelab-kubeconfig
delete-homelab-kubeconfig:
	@kubectl config delete-context homelab-admin@homelab
	@kubectl config delete-user homelab-admin
	@kubectl config delete-cluster homelab

.PHONY: get-capmox-kube-dashboard-token
get-capmox-kube-dashboard-token:
	@kubectl config use-context capmox
	@kubectl describe secret -n kube-system microk8s-dashboard-token

.PHONY: bootstrap-homelab-cluster
bootstrap-homelab-cluster:
	@kubectl config use-context homelab-admin@homelab
	@kubectl apply -k infrastructure/flux/base
	@kubectl wait --for=condition=established crd/gitrepositories.source.toolkit.fluxcd.io crd/kustomizations.kustomize.toolkit.fluxcd.io
	@kubectl apply -k infrastructure/flux/overlays/homelab
