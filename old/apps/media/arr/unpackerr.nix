{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (lib) flip mapAttrs mkEnableOption mkIf pipe toList;
    subdomain = "unpackerr.${config.domain}";
    port = 5656;
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.unpackerr.enable = mkEnableOption "unpackerr";
    config = mkIf config.services.unpackerr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.unpackerr = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.unpackerr-api-key = {
        length = 21;
        upper = false;
        special = false;
      };
      kubenix.kubernetes.helm.releases.unpackerr = {
        namespace = "media";
        values = {
          controllers.unpackerr.annotations."reloader.stakater.com/auto" = "true";
          controllers.unpackerr.containers.unpackerr = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            envFrom = [
              {secret = "unpackerr";}
              {configMapRef.name = "unpackerr";}
            ];
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.unpackerr.controller = "unpackerr";
          service.unpackerr.ports.http.port = port;
          ingress.unpackerr.className = "internal";
          ingress.unpackerr.hosts = toList {
            host = subdomain;
            paths = toList {
              path = "/";
              service.identifier = "unpackerr";
              service.port = "http";
            };
          };
          secrets.unpackerr.data = mapAttrs (_: flip pipe [canivete.vals.sops.default canivete.toBase64]) {
            UN_RADARR_0_API_KEY = "passwords/radarr-api-key";
            UN_SONARR_0_API_KEY = "passwords/sonarr-api-key";
            UN_LIDARR_0_API_KEY = "passwords/lidarr-api-key";
          };
          configMaps.unpackerr.data = {
            UN_WEBSERVER_METRICS = "true";
            UN_WEBSERVER_LOG_FILE = "/logs/webserver.log";
            UN_ACTIVITY = "true";
            UN_RADARR_0_URL = "http://radarr.media.svc.cluster.local";
            UN_RADARR_0_PATHS_0 = "/arr/rtorrent/complete/radarr";
            UN_SONARR_0_URL = "http://sonarr.media.svc.cluster.local";
            UN_SONARR_0_PATHS_0 = "/arr/rtorrent/complete/sonarr";
            UN_LIDARR_0_URL = "http://lidarr.media.svc.cluster.local";
            UN_LIDARR_0_PATHS_0 = "/arr/rtorrent/complete/lidarr";
          };
        };
      };
    };
  };
}
