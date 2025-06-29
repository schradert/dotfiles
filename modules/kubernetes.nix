{
  canivete,
  config,
  inputs,
  ...
}: {
  perSystem.canivete.kubenix.clusters.deploy = config.dotfiles.kubenix;
  dotfiles = _: {
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
        }
        (lib.mkIf config.dotfiles.profiles.server.enable {
          networking.firewall.allowedTCPPorts = [6443];
          systemd.services.k3s.serviceConfig.TimeoutStartSec = 600;
        })
      ];
    };
    config.opentofu.kubernetes.cluster = "deploy";
    config.kubenix = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # nothing currently defined upstream and I don't know what features I'm even using
      options.kubernetes.api.resources."kapp.k14s.io".v1alpha1.Config = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {freeformType = (pkgs.formats.yaml {}).type;});
      };
      # Cannot be split into multiple lines because it's injected into a script
      # TODO fix these hardcoded values
      config.canivete.deploy.fetchKubeconfig = "ssh 192.168.50.58 sudo k3s kubectl config view --raw | sed 's/127\.0\.0\.1/192.168.50.58/'";
    };
  };
}
