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
    options.services.forgejo.enable = lib.mkEnableOption "forgejo";
    config = lib.mkIf config.services.forgejo.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.forgejo = pkgs.dockerTools.pullImage image;};
      nixidy = {lib, ...}: {
        applications.foregejo = {
          namespace = "dotfiles";
          helm.releases.forgejo.chart = lib.helm.downloadHelmChart {
            chart = "forgejo";
            version = "12.5.3";
            repo = "oci://code.forgejo.org/forgejo-helm";
            chartHash = "";
          };
        };
      };
    };
  };
}
