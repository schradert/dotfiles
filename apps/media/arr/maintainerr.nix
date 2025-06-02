{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    subdomain = "maintainerr.${config.domain}";
    port = 6246;
    image = {
      imageName = "ghcr.io/jorenn92/maintainerr";
      imageDigest = "sha256:c590387b72e74852cfe83ed2f512f6582653d458c54ee9cfb71210d5f587eaad";
      hash = "";
      finalImageTag = "2.0.4";
    };
  in {
    options.services.maintainerr.enable = lib.mkEnableOption "maintainerr";
    config = lib.mkIf config.services.maintainerr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.maintainerr = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.maintainerr-session-secret.length = 21;
      kubenix.dotfiles.postgres.maintainerr = {};
      kubenix.kubernetes.helm.releases.maintainerr = {
        namespace = "media";
        values = {
          controllers.maintainerr.annotations."reloader.stakater.com/auto" = "true";
          controllers.maintainerr.containers.maintainerr = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.maintainerr.controller = "maintainerr";
          service.maintainerr.ports.http.port = port;
          ingress.maintainerr.className = "internal";
          ingress.maintainerr.hosts = lib.toList {
            host = subdomain;
            paths = lib.toList {
              path = "/";
              service.identifier = "maintainerr";
              service.port = "http";
            };
          };
        };
      };
    };
  };
}
