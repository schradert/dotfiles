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
      kubenix = {helm, ...}: {
        kubernetes.helm.releases.node-feature-discovery = {
          namespace = "kube-system";
          chart = helm.fetch {
            repo = "https://kubernetes-sigs.github.io/node-feature-discovery/charts";
            chart = "node-feature-discovery";
            version = "0.16.4";
            sha256 = "vUXTzMMWUOeYqbkglYOw9ylrXpvlDPHsc+tXDnxCqow=";
          };
          values.prometheus.enable = true;
        };
      };
    };
  };
}
