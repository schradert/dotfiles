# Dotfiles

## Order

1. prometheus-crds
2. cilium
3. coredns
## TODOs

[ ] Why doesn't cilium agent run on axolotl?

[ ] persistence
[ ] annotations
[ ] resources
[ ] securityContext

[ ] bootstrap images on k3s agents for traefik and forgejo
[ ] VLANs
[ ] instructions for setting up new nodes
[ ] Create a repair command for nix after macOS update per [this working solution](https://discourse.nixos.org/t/nix-commands-missing-after-macos-12-1-version-upgrade/16679/5)

[ ] [rke2](https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=alpha_asc&type=packages&query=rke2)
[ ] network bonding

## Bugs

[ ] Why does nix.mkIf create infinite recursion?
[ ] Why does moduleWithSystem lib.mkIf create infinite recursion?
[ ] Why does mkDomainOption give "deprecationMessage missing"
