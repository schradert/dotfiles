{
  config,
  nix,
  ...
}:
with nix; {
  perSystem.canivete.kubenix.clusters.prod = {
    deploy.fetchKubeconfig = "ssh ${config.canivete.root} sudo k3s kubectl config view --raw | sed 's/127\.0\.0\.1/${config.dotfiles.domain}/'";
    modules.namespaces.kubernetes.resources.namespaces = pipe ./. [
      filesets.dirs
      (map baseNameOf)
      (flip genAttrs (_: {}))
      (flip removeAttrs ["kube-system"])
    ];
  };
}
