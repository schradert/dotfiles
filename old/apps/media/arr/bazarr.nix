{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    subdomain = "bazarr.${config.domain}";
    port = 6767;
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.bazarr.enable = lib.mkEnableOption "bazarr";
    config = lib.mkIf config.services.bazarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.bazarr = pkgs.dockerTools.pullImage image;};
      kubenix.kubernetes.helm.releases.bazarr = {
        namespace = "media";
        values = {
          controllers.bazarr.annotations."reloader.stakater.com/auto" = "true";
          controllers.bazarr.containers.bazarr = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            envFrom = [{secret = "bazarr";}];
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.bazarr.controller = "bazarr";
          service.bazarr.ports.http.port = port;
          ingress.bazarr.className = "internal";
          ingress.bazarr.hosts = lib.toList {
            host = subdomain;
            paths = lib.toList {
              path = "/";
              service.identifier = "bazarr";
              service.port = "http";
            };
          };
          # TODO plex token
          secrets.bazarr.data.PLEX_TOKEN = canivete.toBase64 "";
        };
      };
    };
  };
}
