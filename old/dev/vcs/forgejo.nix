{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    subdomain = "forgejo.${config.domain}";
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
      kubenix = {helm, ...}: {
        kubernetes.helm.releases.forgejo = {
          namespace = "storage";
          chart = helm.fetch {
            chartUrl = "oci://code.forgejo.org/forgejo-helm/forgejo";
            chart = "forgejo";
            version = "8.1.2";
            sha256 = "gpkBBdHtC5uaynOPRjgai5CTfZhOCeCCtsal9tJXgPY=";
          };
          values.gitea.config.server.DOMAIN = subdomain;
        };
      };
    };
  };
}
