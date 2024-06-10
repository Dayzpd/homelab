
.PHONY: apply-cluster
apply-cluster:
	@kubectl apply -k ./cluster

.PHONY: delete-cluster
delete-cluster:
	@kubectl delete -k ./cluster

.PHONY: diff-cluster
diff-cluster:
	-@kubectl diff -k ./cluster

.PHONY: generate-cluster
generate-cluster:
	./scripts/generate-cluster.sh

.PHONY: get-kubeconfig
get-kubeconfig:
	@cp $(HOME)/.kube/config $(HOME)/.kube/config.bak
	@clusterctl get kubeconfig homelab > ./homelab-config
	@KUBECONFIG="./homelab-config:$(HOME)/.kube/config" kubectl config view --flatten > ./merged-config
	@mv ./merged-config $(HOME)/.kube/config
	@rm ./homelab-config