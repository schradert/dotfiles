{
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://kubernetes-sigs.github.io/node-feature-discovery/charts"];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.node-feature-discovery.enable = lib.mkEnableOption "node-feature-discovery";
    config = lib.mkIf config.services.node-feature-discovery.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.node-feature-discovery = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        applications.node-feature-discovery = {
          namespace = "kube-system";
          helm.releases.node-feature-discovery = {
            chart = charts.kubernetes-sigs.node-feature-discovery;
            values.prometheus.enable = config.services.prometheus.enable;
          };
        };
      };
    };
  };
}
