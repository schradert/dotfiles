{
  config,
  lib,
  ...
}: {
  perSystem.dotfiles = {
    opentofu.passwords.unpackerr-api-key = {
      length = 21;
      upper = false;
      special = false;
    };
    nix2container.unpackerr = {};
    helm.unpackerr.namespace = "media";
    helm.unpackerr.values = {
      secrets.unpackerr.enabled = true;
      secrets.unpackerr.stringData = {
        UN_RADARR_0_API_KEY = "ref+envsubst://RADARR_API_KEY";
        UN_SONARR_0_API_KEY = "ref+envsubst://SONARR_API_KEY";
        UN_LIDARR_0_API_KEY = "ref+envsubst://LIDARR_API_KEY";
      };
      configMaps.unpackerr.enabled = true;
      configMaps.unpackerr.data = {
        UN_WEBSERVER_METRICS = "true";
        UN_WEBSERVER_LOG_FILE = "/logs/webserver.log";
        UN_ACTIVITY = "true";
        UN_RADARR_0_URL = "http://radarr.arr.svc.cluster.local";
        UN_RADARR_0_PATHS_0 = "/arr/rtorrent/complete/radarr";
        UN_SONARR_0_URL = "http://sonarr.arr.svc.cluster.local";
        UN_SONARR_0_PATHS_0 = "/arr/rtorrent/complete/sonarr";
        UN_LIDARR_0_URL = "http://lidarr.arr.svc.cluster.local";
        UN_LIDARR_0_PATHS_0 = "/arr/rtorrent/complete/lidarr";
      };
      controllers.unpackerr.containers.unpackerr = {
        image.repository = "ref+envsubst://UNPACKERR_IMAGE_FULLREPOSITORY+";
        image.tag = "ref+envsubst://UNPACKERR_IMAGE_TAG";
        envFrom = [
          {secret = "unpackerr";}
          {configMapRef.name = "unpackerr";}
        ];
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
      };
      service.unpackerr.controller = "unpackerr";
      service.unpackerr.ports.http.port = 5656;
      ingress.unpackerr.className = "internal";
      ingress.unpackerr.hosts = lib.toList {
        host = "unpackerr.${config.dotfiles.domain}";
        paths = lib.toList {
          path = "/";
          service.identifier = "unpackerr";
          service.port = "http";
        };
      };
      # TODO figure out persistence needs
    };
  };
}
