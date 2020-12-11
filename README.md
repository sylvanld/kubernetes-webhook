
## Setup a kubernetes single-node cluster

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

## If coredns fail to boot

1. probably this will fix

* kubectl edit cm coredns -n kube-system
* delete `loop`, save and exit
* reboot!


2. or maybe this...

Edit `/var/lib/kubelet/kubeadm-flags.env` and remove the flag `--network-plugin=cni`.
Then reboot!
