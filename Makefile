

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' ${MAKEFILE_LIST}


generate-config: ## Generate kubectl config in ~/.kube/config
	kubectl config set-cluster kubernetes --server https://localhost:6443 --certificate-authority pki/kubernetes-ca.crt --embed-certs
	kubectl config set-credentials admin --client-key pki/admin.key --client-certificate pki/admin.crt --embed-certs
	kubectl config set-context admin-local --cluster kubernetes --user admin
	kubectl config use-context admin-local	

##@ Commands to check .pem files info

csr-info: ## Read data encoded in a .csr file. Usage: make csr-info file=pki/kubernetes-ca.csr
	openssl req -text -noout -verify -in ${file}

crt-info: ## Read data encoded in a .crt file. Usage: make csr-info file=pki/kubernetes-ca.crt
	openssl x509 -in ${file} -text -noout
