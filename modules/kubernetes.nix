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
      config = lib.mkMerge [
        {
          _module.args = {inherit (inputs.nix2container.packages.${pkgs.system}) nix2container;};
          canivete.kubernetes.images.airgap = config.services.k3s.package.airgapImages;
          dotfiles.services.headscale.policy = {
            acls = [
              {
                action = "accept";
                src = ["*"];
                dst = ["*:*"];
              }
              # {
              #   action = "accept";
              #   src = ["tag:k3s", "10.42.0.0/16"];
              #   dst = ["tag:k3s:*", "10.42.0.0/16:*"];
              # }
            ];
            # autoApprovers.routes."10.42.0.0/16" = ["main"];
          };
        }
        (lib.mkIf config.dotfiles.profiles.server.enable {
          dotfiles.tailscale.routes = ["10.42.0.0/16"];
          networking.firewall.allowedTCPPorts = [6443];
          services.tailscale.extraSetFlags = [
            # "--snat-subnet-routes=false"
            # TODO why isn't this valid? how to assign tags?
            # "--advertise-tags"
            # "tag:k3s"
          ];
          systemd.services.k3s.serviceConfig.TimeoutStartSec = 600;
        })
      ];
    };
    config.opentofu.kubernetes.cluster = "deploy";
    config.kubenix = {config, lib, pkgs, ...}: {
      # nothing currently defined upstream and I don't know what features I'm even using
      options.kubernetes.api.resources."kapp.k14s.io".v1alpha1.Config = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {freeformType = (pkgs.formats.yaml {}).type;});
      };
      # Cannot be split into multiple lines because it's injected into a script
      # TODO might not make sense to have this be a hostname that requires tailscale on dev machine
      config.canivete.deploy.fetchKubeconfig = "ssh 192.168.50.185 sudo k3s kubectl config view --raw | sed 's/127\.0\.0\.1/192.168.50.185/'";
    };
  };
}
