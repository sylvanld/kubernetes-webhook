PKI_FOLDER=pki
KUBECONFIG=~/.kube/config

COUNTRY_CODE=FR
COUNTRY=France
CITY=Rennes
COMPANY=Orange

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Commands used to generate certificates required in PKI

generate-company-root-ca:
	openssl req \
		-nodes \
		-subj "/C=$(COUNTRY_CODE)/ST=$(COUNTRY)/L=$(CITY)/O=$(COMPANY)/OU=Orange/CN=orange-ca" \
		-new -x509 \
		-days 9999 \
		-keyout $(PKI_FOLDER)/orange-ca.key \
		-out $(PKI_FOLDER)/orange-ca.crt

generate-kubernetes-certificate:
	# create kubernetes private key
	openssl genrsa -out $(PKI_FOLDER)/kubernetes-ca.key 4096
	# generate a signing request that must be signed using company root ca
	openssl req \
		-new \
		-nodes \
		-sha256 \
		-subj "/C=$(COUNTRY_CODE)/ST=$(COUNTRY)/L=$(CITY)/O=$(COMPANY)/OU=Orange France/CN=kubernetes-ca" \
		-key $(PKI_FOLDER)/kubernetes-ca.key \
		-out $(PKI_FOLDER)/kubernetes-ca.csr
	# sign kubernetes cluster root certificate using company CA.
	openssl x509 \
		-req \
		-days 9999 \
		-sha256 \
		-CA $(PKI_FOLDER)/orange-ca.crt \
		-CAkey $(PKI_FOLDER)/orange-ca.key \
		-set_serial 01 \
		-extensions req_ext \
		-in $(PKI_FOLDER)/kubernetes-ca.csr \
		-out $(PKI_FOLDER)/kubernetes-ca.crt

generate-apiserver-certificate:
	# create apiserver private key
	openssl genrsa -out $(PKI_FOLDER)/kube-apiserver.key 4096
	# generate a signing request that must be signed using company root ca
	openssl req \
		-new \
		-nodes \
		-sha256 \
		-subj "/C=$(COUNTRY_CODE)/ST=$(COUNTRY)/L=$(CITY)/O=$(COMPANY)/OU=Orange France/CN=kube-apiserver" \
		-key $(PKI_FOLDER)/kube-apiserver.key \
		-out $(PKI_FOLDER)/kube-apiserver.csr
	# sign kubernetes cluster root certificate using company CA.
	bash -c "openssl x509 \
		-req \
		-days 9999 \
		-extfile <(printf "subjectAltName=IP:192.168.56.116,DNS:localhost,DNS:kube-local") \
		-sha256 \
		-CA $(PKI_FOLDER)/kubernetes-ca.crt \
		-CAkey $(PKI_FOLDER)/kubernetes-ca.key \
		-set_serial 01  \
		-in $(PKI_FOLDER)/kube-apiserver.csr \
		-out $(PKI_FOLDER)/kube-apiserver.crt"

generate-admin-certificate:
	#
	openssl genrsa -out $(PKI_FOLDER)/admin.key 4096
	#
	openssl req \
		-new \
		-nodes \
		-sha256 \
		-subj "/C=$(COUNTRY_CODE)/ST=$(COUNTRY)/L=$(CITY)/O=$(COMPANY)/CN=kubernetes-admin"\
		-key $(PKI_FOLDER)/admin.key \
		-out $(PKI_FOLDER)/admin.csr
	#
	bash -c "openssl x509 \
		-req \
		-days 9999 \
		-sha256 \
		-extfile <(printf "subjectAltName=IP:192.168.56.116,DNS:localhost,DNS:kube-local") \
		-CA $(PKI_FOLDER)/kubernetes-ca.crt \
		-CAkey $(PKI_FOLDER)/kubernetes-ca.key \
		-set_serial 01 \
		-in $(PKI_FOLDER)/admin.csr \
		-out $(PKI_FOLDER)/admin.crt"

generate-moon-certificate:
	#
	openssl genrsa -out $(PKI_FOLDER)/moon-pdp.key 4096
	#
	openssl req \
		-new \
		-nodes \
		-sha256 \
		-subj "/C=$(COUNTRY_CODE)/ST=$(COUNTRY)/L=$(CITY)/O=$(COMPANY)/CN=moon-pdp"\
		-key $(PKI_FOLDER)/moon-pdp.key \
		-out $(PKI_FOLDER)/moon-pdp.csr
	#
	bash -c "openssl x509 \
		-req \
		-days 9999 \
		-sha256 \
		-extfile <(printf "subjectAltName=IP:192.168.56.116,DNS:localhost,DNS:kube-local") \
		-CA $(PKI_FOLDER)/kubernetes-ca.crt \
		-CAkey $(PKI_FOLDER)/kubernetes-ca.key \
		-set_serial 01 \
		-in $(PKI_FOLDER)/moon-pdp.csr \
		-out $(PKI_FOLDER)/moon-pdp.crt"

generate-pki: ## Create root CA for company, and signed Ca for kubernetes. Then generate signed certificate for moon, apiserver and kubectl
	rm -rf $(PKI_FOLDER) && mkdir $(PKI_FOLDER)
	make generate-company-root-ca
	make generate-kubernetes-certificate
	make generate-apiserver-certificate
	make generate-admin-certificate
	make generate-moon-certificate

generate-config: ## Generate kubectl config in ~/.kube/config
	kubectl config set-cluster kubernetes --server https://localhost:6443 --certificate-authority pki/kubernetes-ca.crt --embed-certs
	kubectl config set-credentials admin --client-key pki/admin.key --client-certificate pki/admin.crt --embed-certs
	kubectl config set-context admin-local --cluster kubernetes --user admin
	kubectl config use-context admin-local	

##@ Commands to check .pem files info

csr-info: ## Read data encoded in a .csr file. Usage: make csr-info file=pki/kubernetes-ca.csr
	openssl req -text -noout -verify -in $(file)

crt-info: ## Read data encoded in a .crt file. Usage: make csr-info file=pki/kubernetes-ca.crt
	openssl x509 -in $(file) -text -noout
