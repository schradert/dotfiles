# Dotfiles

Fair warning this repository does not follow more traditional patterns for infrastructure management and desktop dotfiles configuration seen in the Nix community. It is very much a work in progress, highly unstable, and obviously purpose built for myself. It is the most complete test of the functionality exposed by [canivete](https://github.com/schradert/canivete), a library for managing all kinds of infrastructure. The general idea of this work is to consolidate configuration for development workstations, server nodes, cluster deployments, Nix packaging, container builds, and more under a single umbrella with unlimited flexibility when modularizing and refactoring. Everything in this repo is ultimately deployable under a single `nix run`.

## NOTE

1. don't add other nodes into the cluster until cilium + coredns + spegel exist

- I should bootstrap this!
- does the cilium image also need to be propagated to all nodes ahead of time?

## TODO

- [ ] only evaluate packages for opentofu config (it's currently building kubenix config every time...)
- [ ] is input.self causing every node to redeploy even on unrelated changes? (sops-install-service has to be restarted EVERY time)
- [ ] nix and cluster image garbage collector
- [ ] why do I have to `rm -rf /var/lib/rancher/k3s/agent/images && systemd-tmpfiles --create --remove` when a new image with same name is pushed?! (only applies to `buildImage` because symlink name is the same) (could be with systemd-tmpfiles-resetup)
- [ ] set up essential services on Kubernetes before deploying the other nodes to the cluster
- [ ] kubernetes namespaces
- [ ] repo folder organization
- [ ] replace nginx with cilium
- [ ] is spegel not working? (kubectl run doesn't work if pod is scheduled on a node without it..., but deploying with kapp clearly does)
- [ ] non hostNetwork pods can't seem to connect to remote servers...
- [ ] why do Ihave to wipe k3s like this?

```bash
sudo systemctl stop k3s
sudo pkill -9 -f k3s
sudo findmnt -rn -o TARGET |
  grep -E '^(/var/lib/kubelet/|/run/k3s/|/run/netns/|/run/cilium/)' |
  sort -r |
  xargs -r -n1 sudo umount -l
sudo rm -rf /var/lib/rancher /var/lib/kubelet /var/lib/cni /run/cilium /run/k3s /run/netns
```

- [ ] what is missing from this to cause old container IDs to not be found
- [ ] is there a better way to deploy containers that doesn't cause k3s startup to take so damn long?
- [ ] what is causing the cilium crd conflict?
- [ ] pin every single container (pullPolicy = Never, useDigest = true, repo +tag +digest)
- [ ] why `experimental-features "dynamic-derivations"` with `eval "$(nix eval --raw .#...null_resource.kubernetes.provisioner.local-exec.command)"`
- [ ] avoid hardcoding IPs!
