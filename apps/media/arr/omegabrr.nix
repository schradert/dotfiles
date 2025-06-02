{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    subdomain = "omegabrr.${config.domain}";
    port = 80;
    image = {
      imageName = "ghcr.io/autobrr/omegabrr";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.omegabrr.enable = lib.mkEnableOption "omegabrr";
    config = lib.mkIf config.services.omegabrr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.omegabrr = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.omegabrr-session-secret.length = 21;
      kubenix.dotfiles.postgres.omegabrr = {};
      kubenix.kubernetes.helm.releases.omegabrr = {
        namespace = "media";
        values = {
          controllers.omegabrr.annotations."reloader.stakater.com/auto" = "true";
          controllers.omegabrr.containers.omegabrr = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.omegabrr.controller = "omegabrr";
          service.omegabrr.ports.http.port = port;
          ingress.omegabrr.className = "internal";
          ingress.omegabrr.hosts = lib.toList {
            host = subdomain;
            paths = lib.toList {
              path = "/";
              service.identifier = "omegabrr";
              service.port = "http";
            };
          };
        };
      };
    };
  };
}
