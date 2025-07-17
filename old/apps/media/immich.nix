{
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
    options.services.immich.enable = lib.mkEnableOption "Immich";
    config = lib.mkIf config.services.immich.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.immich = pkgs.dockerTools.pullImage image;};
      nixidy = {lib, ...}: {
        dotfiles.postgres.immich = {};
        applications.immich = {
          namespace = "dotfiles";
          helm.releases.immich = {
            chart = lib.helm.downloadHelmChart {
              chart = "immich";
              version = "0.9.3";
              repo = "https://immich-app.github.io/immich-charts";
              chartHash = "";
            };
            values.redis.enabled = true;
          };
        };
      };
    };
  };
}
