
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
