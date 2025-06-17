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
    options.services.harbor.enable = lib.mkEnableOption "harbor";
    config = lib.mkIf config.services.harbor.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.harbor = pkgs.dockerTools.pullImage image;};
      kubenix = {helm, ...}: {
        kubernetes.helm.releases.harbor = {
          namespace = "storage";
          chart = helm.fetch {
            repo = "https://helm.goharbor.io";
            chart = "harbor";
            version = "1.15.0";
            sha256 = "gj3Z00+ZwznFZP84ezl6lgEeAfBso/2+M/OfCYWlC0Y=";
          };
          values.trivy.resources.limits.cpu = "1";
        };
      };
    };
  };
}
