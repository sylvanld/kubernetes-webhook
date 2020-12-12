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

You must copy cluster configuration to `~/.kube/config` as follow.
Make sure you are the only one with read/write access to this file.

```
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chmod 600 ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
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

### Create mount point in apiserver

Next we need to make the PKI (set of certificates) accessible in kube-apiserver.
The easiest way to do so, is by creating a volume pointing to local file system.

* First we will declare a new volume in kube-apiserver command container. In this example it will be available under `/etc/kube-webhook`.
Edit `/etc/kubernetes/manifest/kube-apiserver.yaml` and add the followings.

```yaml
spec:
  containers:
  - command:
    volumeMounts:
      # declare our volume that will be mounted in 'command' container
      - mountPath: /etc/kube-webhook
        name: webhook-volume
        readOnly: true
    volumes:
      # Bind this entire repo to our volume, so it will be available in container under /etc/kube-webhook
      - hostPath:
          path: /path/to/this/project/kube-admin
          type: DirectoryOrCreate
        name: webhook-volume
```

### Configure apiserver certificates

No we must tell kube-apiserver to use newly generated certificates instead of defaults ones.
Remember that certificates will be available for kube-apiserver at the mount point we defined previously.

```
--client-ca-file=/etc/kube-webhook/pki/ca.crt
--tls-cert-file=/etc/kube-webhook/pki/server.crt
--tls-private-key-file=/etc/kube-webhook/pki/server.key
```

### Configure Authorization mode

Once done, we can enable webhook mode for authorization.
Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` and replace `--authorization-mode=...` with

```
--authorization-mode=Webhook
--authorization-webhook-config-file=/etc/kube-webhook/authz.yaml
```

The file authz :

* defines address on which our authz service is available (for apiserver to know where authz requests must be sent)
* declare SSL certificates used by our authz service so kube-apiserver can trust it.

# TODO

* document how to create a signed certificate for client

cf https://wiki.archlinux.org/index.php/Easy-RSA

* document how to mount a volume in apiserver pod

(required to use --webhook-config-file... and access certificate declared in webhook config)

https://kubernetes.io/fr/docs/concepts/storage/volumes/
