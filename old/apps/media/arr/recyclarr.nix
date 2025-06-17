{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mapAttrs flip pipe;
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.recyclarr.enable = lib.mkEnableOption "recyclarr";
    config = lib.mkIf config.services.recyclarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.recyclarr = pkgs.dockerTools.pullImage image;};
      kubenix.kubernetes.helm.releases.recyclarr = {
        namespace = "media";
        values = {
          controllers.recyclarr = {
            type = "cronjob";
            cronjob.schedule = "@daily";
            containers.recyclarr = {
              image.repository = image.imageName;
              image.tag = image.finalImageTag;
              args = ["sync"];
              envFrom = [{secret = "recyclarr";}];
            };
          };
          secrets.recyclarr.data = mapAttrs (_: flip pipe [canivete.vals.sops.default canivete.toBase64]) {
            RADARR_API_KEY = "passwords/radarr-api-key";
            SONARR_API_KEY = "passwords/sonarr-api-key";
          };
        };
      };
    };
  };
}
