# Dotfiles

## Order

1. cilium (crds have to go first in bootstrap)
2. prometheus
3. coredns
4. kubelet-csr-approver
5. spegel
6. cert-manager (nginx must wait)
7. external-dns
23. cloudflared
8. nginx-internal
9. nginx-external
10. snapshot-controller
11. volsync
12. reloader
13. descheduler
14. node-feature-discovery
15. k8tz
16. openebs
18. grafana
19. rook-ceph + rook-ceph-cluster
20. loki
21. external-secrets
22. postgres
23. postgres-ui
23. keycloak
24. gatus

## TODOs

[ ] Why doesn't cilium agent run on axolotl?

[ ] persistence
[ ] annotations
[ ] resources
[ ] securityContext
[ ] separate default.yaml and kubernetes.yaml SOPS (track static vs dynamic)
[ ] bootstrap images on k3s agents for traefik and forgejo
[ ] VLANs
[ ] instructions for setting up new nodes
[ ] Create a repair command for nix after macOS update per [this working solution](https://discourse.nixos.org/t/nix-commands-missing-after-macos-12-1-version-upgrade/16679/5)

[ ] [rke2](https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=alpha_asc&type=packages&query=rke2)
[ ] network bonding
[ ] Pushover
[ ] add tristanschrader.com redirect and email obfuscation deactivation to opentofu
[ ] add keycloak client creation to opentofu
[ ] add firefly multi-user configuration to terraform
[ ] remove extra fields from external-secrets

[ ] fix rook-ceph OSDs to be correctly distributed

## Bugs

[ ] Why does nix.mkIf create infinite recursion?
[ ] Why does moduleWithSystem lib.mkIf create infinite recursion?
[ ] Why does mkDomainOption give "deprecationMessage missing"

## Tips

Apply these annotations to services that need the oauth2-proxy
```
annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_groups=/family";
annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
```
