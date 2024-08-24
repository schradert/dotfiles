{config, nix, ...}: with nix; let
  port = 8080;
  subdomain = "sabnzbd.${config.dotfiles.domain}";
in {
  perSystem = {
    dotfiles.nix2container.sabnzbd = {};
    dotfiles.helm.sabnzbd = {
      namespace = "arr";
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
        ingress.sabnzbd.hosts = nix.toList {
          host = subdomain;
          paths = nix.toList {
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
          SABNZBD__HOST_WHITELIST_ENTRIES = concatStringsSep "," ["sabnzbd" "sabnzbd.arr" "sabnzbd.arr.svc" "sabnzbd.arr.svc.cluster" "sabnzbd.arr.svc.cluster.local" subdomain];
        };
      };
    };
  };
}
