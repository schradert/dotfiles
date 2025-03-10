{
  config,
  lib,
  ...
}: {
  # TODO plex token?
  # TODO should I use subcleaner https://github.com/KBlixt/subcleaner
  perSystem.canivete.nix2container.bazarr = {};
  perSystem.canivete.kubenix.helm.bazarr = {
    namespace = "media";
    values = {
      controllers.bazarr.containers.bazarr = {
        image.repository = "ref+envsubst://BAZARR_IMAGE_FULLREPOSITORY+";
        image.tag = "ref+envsubst://BAZARR_IMAGE_TAG";
        envFrom = lib.toList {secret = "bazarr";};
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
      };
      service.bazarr.controller = "bazarr";
      service.bazarr.ports.http.port = 6767;
      ingress.bazarr.className = "internal";
      ingress.bazarr.hosts = lib.toList {
        host = "bazarr.${config.canivete.meta.domain}";
        paths = lib.toList {
          path = "/";
          service.identifier = "bazarr";
          service.port = "http";
        };
      };
      secrets.bazarr.enabled = true;
      secrets.bazarr.stringData.PLEX_TOKEN = "";
    };
  };
}
