{config, inputs, ...}: {
  perSystem.canivete.kubenix.clusters.deploy = config.dotfiles.kubenix;
  dotfiles = {canivete, config, ...}: let
    inherit (config) domain;
  in {
    options.kubenix = canivete.mkModuleOption {description = "Common kubenix configuration";};
    config.nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      _module.args = {inherit (inputs.nix2container.packages.${pkgs.system}) nix2container;};
      canivete.kubernetes.images.airgap = config.services.k3s.package.airgapImages;
      canivete.kubernetes.k3s.tls-san = lib.mkForce [domain];
    };
    config.opentofu.kubernetes.cluster = "deploy";
    config.kubenix = {lib, pkgs, ...}: {
      # nothing currently defined upstream and I don't know what features I'm even using
      options.kubernetes.api.resources."kapp.k14s.io".v1alpha1.Config = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {freeformType = (pkgs.formats.yaml {}).type;});
      };
      # Cannot be split into multiple lines because it's injected into a script
      config.canivete.deploy.fetchKubeconfig = "ssh ${config.root} sudo k3s kubectl config view --raw | sed 's/127\.0\.0\.1/${config.domain}/'";
    };
  };
}
