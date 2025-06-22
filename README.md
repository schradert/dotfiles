# Dotfiles

Fair warning this repository does not follow more traditional patterns for infrastructure management and desktop dotfiles configuration seen in the Nix community. It is very much a work in progress, highly unstable, and obviously purpose built for myself. It is the most complete test of the functionality exposed by [canivete](https://github.com/schradert/canivete), a library for managing all kinds of infrastructure. The general idea of this work is to consolidate configuration for development workstations, server nodes, cluster deployments, Nix packaging, container builds, and more under a single umbrella with unlimited flexibility when modularizing and refactoring. Everything in this repo is ultimately deployable under a single `nix run`.

## TODO

- [ ] nix and cluster image garbage collector
- [ ] write tailscaled service config and install
- [ ] why do I have to `rm -rf /var/lib/rancher/k3s/agent/images && systemd-tmpfiles --create --remove` when a new image with same name is pushed?! (only applies to `buildImage` because symlink name is the same)
- [ ] is input.self causing every node to redeploy even on unrelated changes?
- [ ] set up essential services on Kubernetes before deploying the other nodes to the cluster
