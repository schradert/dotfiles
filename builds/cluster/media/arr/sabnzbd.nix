{
  config,
  lib,
  ...
}: let
  port = 8080;
  subdomain = "sabnzbd.${config.canivete.meta.domain}";
in {
  # Sabnzbd only supports unrar currently, but unar is a better alternative to keep track of
  # NOTE https://github.com/sabnzbd/sabnzbd/issues/1120
  canivete.pkgs.allowUnfree = ["unrar"];
  perSystem = {
    canivete.nix2container.sabnzbd = {};
    canivete.kubenix.helm.sabnzbd = {
      namespace = "media";
      values = {
        controllers.sabnzbd.containers.sabnzbd = {
          image.repository = "ref+envsubst://SABNZBD_IMAGE_FULLREPOSITORY+";
          image.tag = "ref+envsubst://SABNZBD_IMAGE_TAG";
          envFrom = [
            {secret = "sabnzbd";}
            {configMapRef.name = "sabnzbd";}
          ];
          probes.liveness.enabled = true;
          probes.readiness.enabled = true;
          probes.startup.enabled = true;
        };
        service.sabnzbd.controller = "sabnzbd";
        service.sabnzbd.ports.http.port = port;
        ingress.sabnzbd.className = "internal";
        ingress.sabnzbd.hosts = lib.toList {
          host = subdomain;
          paths = lib.toList {
            path = "/";
            service.identifier = "sabnzbd";
            service.port = "http";
          };
        };
        secrets.sabnzbd.enabled = true;
        secrets.sabnzbd.stringData = {
          SABNZBD__API_KEY = "";
          SABNZBD__NZB_KEY = "";
        };
        configMaps.sabnzbd.enabled = true;
        configMaps.sabnzbd.data = {
          SABNZBD__PORT = toString port;
          SABNZBD__HOST_WHITELIST_ENTRIES = lib.concatStringsSep "," ["sabnzbd" "sabnzbd.arr" "sabnzbd.arr.svc" "sabnzbd.arr.svc.cluster" "sabnzbd.arr.svc.cluster.local" subdomain];
        };
      };
    };
  };
}
