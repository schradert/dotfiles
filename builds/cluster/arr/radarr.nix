{config, nix, ...}: let
  port = 7878;
  subdomain = "radarr.${config.dotfiles.domain}";
in {
  perSystem.dotfiles = {
    opentofu.passwords.radarr-api-key = {
      length = 21;
      upper = false;
      special = false;
    };
    nix2container.radarr = {};
    helm.radarr.namespace = "arr";
    helm.radarr.values = {
      secrets.radarr.enabled = true;
      secrets.radarr.stringData.RADARR__AUTH__APIKEY = "ref+envsubst://RADARR_API_KEY";
      configMaps.radarr.enabled = true;
      configMaps.radarr.data = {
        # TODO Figure out what all of these settings do!
        RADARR__APP__INSTANCENAME = "Radarr";
        RADARR__APP__THEME = "Auto";
        RADARR__APP__LAUNCHBROWSER = "false";
        RADARR__AUTH__ENABLED = "";
        RADARR__AUTH__METHOD = "External";
        RADARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
        RADARR__SERVER__URLBASE = "https://${subdomain}";
        RADARR__SERVER__BINDADDRESS = "*";
        RADARR__SERVER__PORT = toString port;
        RADARR__SERVER__ENABLESSL = "";
        RADARR__SERVER__SSLPORT = "";
        RADARR__SERVER__SSLCERTPATH = "";
        RADARR__SERVER__SSLCERTPASSWORD = "";
        RADARR__LOG__LEVEL = "info";
        RADARR__LOG__FILTERSENTRYEVENTS = "";
        RADARR__LOG__ROTATE = "";
        RADARR__LOG__SQL = "";
        RADARR__LOG__CONSOLELEVEL = "";
        RADARR__LOG__ANALYTICSENABLED = "true";
        RADARR__LOG__SYSLOGSERVER = "";
        RADARR__LOG__SYSLOGPORT = "";
        RADARR__LOG__SYSLOGLEVEL = "";
        RADARR__UPDATE__MECHANISM = "";
        RADARR__UPDATE__AUTOMATICALLY = "";
        RADARR__UPDATE__SCRIPTPATH = "";
        RADARR__UPDATE__BRANCH = "";
      };
      controllers.radarr.containers.radarr = {
        image.repository = "ref+envsubst://RADARR_IMAGE_FULLREPOSITORY+";
        image.tag = "ref+envsubst://RADARR_IMAGE_TAG";
        envFrom = [
          {secret = "radarr";}
          {configMapRef.name = "radarr";}
        ];
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
      };
      service.radarr.controller = "radarr";
      service.radarr.ports.http.port = port;
      ingress.radarr.className = "internal";
      ingress.radarr.hosts = nix.toList {
        host = subdomain;
        paths = nix.toList {
          path = "/";
          service.identifier = "radarr";
          service.port = "http";
        };
      };
      # TODO figure out persistence needs
    };
  };
}
