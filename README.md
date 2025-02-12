# Dotfiles

Fair warning this repository does not follow more traditional patterns for infrastructure management and desktop dotfiles configuration seen in the Nix community. It is very much a work in progress, highly unstable, and obviously purpose built for myself. It is the most complete test of the functionality exposed by [canivete](https://github.com/schradert/canivete), a library for managing all kinds of infrastructure. The general idea of this work is to consolidate configuration for development workstations, server nodes, cluster deployments, Nix packaging, container builds, and more under a single umbrella with unlimited flexibility when modularizing and refactoring. Everything in this repo is ultimately deployable under a single `nix run`.

## TODO

- [ ] essential configuration in emacs
- [ ] zellij layouts for projects and default
- [ ] zellij command for tri-split window fixer
- [ ] zellij command to search and navigate to a pane
