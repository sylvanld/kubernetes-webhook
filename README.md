# Study implementation of a kubernetes webhook

- [Setup a kubernetes single-node cluster](#setup-a-kubernetes-single-node-cluster)
  - [Install and run kubernetes](#install-and-run-kubernetes)
  - [Configure kubectl to access the cluster](#configure-kubectl-to-access-the-cluster)
  - [Check kubelet status](#check-kubelet-status)
- [Configure WebHook](#configure-webhook)
  - [Generate certificates](#generate-certificates)
  - [Create mount point in apiserver](#create-mount-point-in-apiserver)
  - [Configure apiserver certificates](#configure-apiserver-certificates)
  - [Configure Authorization mode](#configure-authorization-mode)
  - [Setup a Load-Balancer](#setup-a-load-balancer)
- [Sources](#sources)

## Setup a kubernetes single-node cluster

### Install and run kubernetes

1. Disable the swap

For current session by running

```
sudo swapoff -a
```

Howerver it will not persist on reboot so your must also command the following line from `/etc/fstab`

```
/swapfile                                 none            swap    sw              0       0
```

2. Install kubernetes on top of docker

```
sudo scripts/install-kubernetes
```

### Configure kubectl to access the cluster

```
kubectl config set-cluster kubernetes --server https://localhost:6443 --certificate-authority pki/kubernetes-ca.crt --embed-certs
kubectl config set-credentials admin --client-key pki/admin.key --client-certificate pki/admin.crt --embed-certs
kubectl config set-context admin-local --cluster kubernetes --user admin
kubectl config use-context admin-local
```

### Check kubelet status

To ensure kubelet is properly working, you can issue the following command.

```
kubectl get pods -n kube-system
```

If all pods are ready and with status running, then everything is fine.

**Note**: coredns will remains in pending state until a network solution is deployed. (See: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/)

## Configure WebHook

### Generate certificates

Run the following command from project root.
```
scripts/generate-certificates
```

This will generate a few files in `pki/` folder. Interesting ones are

1. ca.crt : Root certificate for your kubernetes cluster
2. server.key : Private key of kube-apiserver
3. server.crt : Self signed certificate of kube-apiserver
4. moon-pdp.key : Private key for moon PDP
5. moon-pdp.crt : Self signed certificate for moon PDP


*PKI infrastructure*

![pki infrastructure in kubernetes](https://miro.medium.com/max/776/1*IPCF2B5vs2cyrCsP-sPOvQ.jpeg)

Source: https://medium.com/@oleg.pershin/kubernetes-from-scratch-certificates-53a1a16b5f03

### Create mount point in apiserver

Next we need to make the PKI (set of certificates) accessible in kube-apiserver.
The easiest way to do so, is by creating a volume pointing to local file system.

* First we will declare a new volume in kube-apiserver command container. In this example it will be available under `/etc/kube-settings/`.
Edit `/etc/kubernetes/manifest/kube-apiserver.yaml` and add the followings.

```yaml
spec:
  containers:
  - command:
    volumeMounts:
      # declare our volume that will be mounted in 'command' container
      - mountPath: /etc/kube-settings
        name: settings-volume
        readOnly: true
    volumes:
      # Bind this entire repo to our volume, so it will be available in container under /etc/kube-settings
      - hostPath:
          path: /path/to/this/project
          type: DirectoryOrCreate
        name: settings-volume
```

### Configure apiserver certificates

No we must tell kube-apiserver to use newly generated certificates instead of defaults ones.
Remember that certificates will be available for kube-apiserver at the mount point we defined previously.

```
--client-ca-file=/etc/kube-settings/pki/kubernetes-ca.crt
--tls-cert-file=/etc/kube-settings/pki/kube-apiserver.crt
--tls-private-key-file=/etc/kube-settings/pki/kube-apiserver.key
```

### Configure Authorization mode

Once done, we can enable webhook mode for authorization.
Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` and replace `--authorization-mode=...` with

```
--authorization-mode=Webhook
--authorization-webhook-config-file=/etc/kube-settings/authz.yaml
```

The file authz :

* defines address on which our authz service is available (for apiserver to know where authz requests must be sent)
* declare SSL certificates used by our authz service so kube-apiserver can trust it.

Edit this file and add replace `<AUTHZ_SERVER_ADDRESS>` by host address and port on which your authorization server is listening.

### Setup a Load-Balancer

We are going to [install MetalLB](https://metallb.universe.tf/installation/) as a LoadBalancer for our local cluster.

* You have to enable strict ARP mode. 

You can achieve this by editing kube-proxy config in current cluster:

```bash
kubectl edit configmap -n kube-system kube-proxy
```

and set:

```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true
```

* To install MetalLB, apply the manifest:

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
```

* Finally, defines MetalLB configuration. In this example feel free to configure the pool of assignable addresses.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses: # pool of addresses that might be assigned to services
      - 192.168.56.130-192.168.56.150
```

## Sources

* [generate pki for your kubernetes cluster](https://medium.com/@oleg.pershin/kubernetes-from-scratch-certificates-53a1a16b5f03)
* [document how to mount a volume in apiserver pod](https://kubernetes.io/fr/docs/concepts/storage/volumes/)
* [enable webhook mode for authorizations](https://kubernetes.io/docs/reference/access-authn-authz/webhook/)
* [configure load balancer for non-cloud kubernetes instance](https://metallb.universe.tf/installation/)
