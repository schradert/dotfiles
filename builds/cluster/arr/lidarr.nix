{config, nix, ...}: with nix; let
  port = 7878;
  subdomain = "lidarr.${config.dotfiles.domain}";
in {
  perSystem.dotfiles = {
    opentofu.passwords.lidarr-api-key = {
      length = 21;
      upper = false;
      special = false;
    };
    nix2container.lidarr = {};
    helm.lidarr.namespace = "arr";
    helm.lidarr.values = {
      secrets.lidarr.enabled = true;
      secrets.lidarr.stringData.LIDARR__AUTH__APIKEY = "ref+envsubst://LIDARR_API_KEY";
      configMaps.lidarr.enabled = true;
      configMaps.lidarr.data = {
        # TODO Figure out what all of these settings do!
        LIDARR__APP__INSTANCENAME = "Lidarr";
        LIDARR__APP__THEME = "Auto";
        LIDARR__APP__LAUNCHBROWSER = "false";
        LIDARR__AUTH__ENABLED = "";
        LIDARR__AUTH__METHOD = "External";
        LIDARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
        LIDARR__SERVER__URLBASE = "https://${subdomain}";
        LIDARR__SERVER__BINDADDRESS = "*";
        LIDARR__SERVER__PORT = toString port;
        LIDARR__SERVER__ENABLESSL = "";
        LIDARR__SERVER__SSLPORT = "";
        LIDARR__SERVER__SSLCERTPATH = "";
        LIDARR__SERVER__SSLCERTPASSWORD = "";
        LIDARR__LOG__LEVEL = "info";
        LIDARR__LOG__FILTERSENTRYEVENTS = "";
        LIDARR__LOG__ROTATE = "";
        LIDARR__LOG__SQL = "";
        LIDARR__LOG__CONSOLELEVEL = "";
        LIDARR__LOG__ANALYTICSENABLED = "true";
        LIDARR__LOG__SYSLOGSERVER = "";
        LIDARR__LOG__SYSLOGPORT = "";
        LIDARR__LOG__SYSLOGLEVEL = "";
        LIDARR__UPDATE__MECHANISM = "";
        LIDARR__UPDATE__AUTOMATICALLY = "";
        LIDARR__UPDATE__SCRIPTPATH = "";
        LIDARR__UPDATE__BRANCH = "";
      };
      controllers.lidarr.containers.lidarr = {
        image.repository = "ref+envsubst://LIDARR_IMAGE_FULLREPOSITORY+";
        image.tag = "ref+envsubst://LIDARR_IMAGE_TAG";
        envFrom = [
          {secret = "lidarr";}
          {configMapRef.name = "lidarr";}
        ];
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
      };
      service.lidarr.controller = "lidarr";
      service.lidarr.ports.http.port = port;
      ingress.lidarr.className = "internal";
      ingress.lidarr.hosts = toList {
        host = subdomain;
        paths = toList {
          path = "/";
          service.identifier = "lidarr";
          service.port = "http";
        };
      };
      # TODO figure out persistence needs
    };
  };
}
