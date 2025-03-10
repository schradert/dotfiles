{
  config,
  lib,
  ...
}: let
  port = 7878;
  subdomain = "sonarr.${config.canivete.meta.domain}";
in {
  perSystem.canivete.opentofu.workspaces.deploy.modules.sonarr.canivete.passwords.sonarr-api-key = {
    length = 21;
    upper = false;
    special = false;
  };
  perSystem.canivete.nix2container.sonarr = {};
  perSystem.canivete.kubenix.helm.sonarr.namespace = "media";
  perSystem.canivete.kubenix.helm.sonarr.values = {
    secrets.sonarr.enabled = true;
    secrets.sonarr.stringData.SONARR__AUTH__APIKEY = "ref+envsubst://SONARR_API_KEY";
    configMaps.sonarr.enabled = true;
    configMaps.sonarr.data = {
      # TODO Figure out what all of these settings do!
      SONARR__APP__INSTANCENAME = "Sonarr";
      SONARR__APP__THEME = "Auto";
      SONARR__APP__LAUNCHBROWSER = "false";
      SONARR__AUTH__ENABLED = "";
      SONARR__AUTH__METHOD = "External";
      SONARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
      SONARR__SERVER__URLBASE = "https://${subdomain}";
      SONARR__SERVER__BINDADDRESS = "*";
      SONARR__SERVER__PORT = toString port;
      SONARR__SERVER__ENABLESSL = "";
      SONARR__SERVER__SSLPORT = "";
      SONARR__SERVER__SSLCERTPATH = "";
      SONARR__SERVER__SSLCERTPASSWORD = "";
      SONARR__LOG__LEVEL = "info";
      SONARR__LOG__FILTERSENTRYEVENTS = "";
      SONARR__LOG__ROTATE = "";
      SONARR__LOG__SQL = "";
      SONARR__LOG__CONSOLELEVEL = "";
      SONARR__LOG__ANALYTICSENABLED = "true";
      SONARR__LOG__SYSLOGSERVER = "";
      SONARR__LOG__SYSLOGPORT = "";
      SONARR__LOG__SYSLOGLEVEL = "";
      SONARR__UPDATE__MECHANISM = "";
      SONARR__UPDATE__AUTOMATICALLY = "";
      SONARR__UPDATE__SCRIPTPATH = "";
      SONARR__UPDATE__BRANCH = "";
    };
    controllers.sonarr.containers.sonarr = {
      image.repository = "ref+envsubst://SONARR_IMAGE_FULLREPOSITORY+";
      image.tag = "ref+envsubst://SONARR_IMAGE_TAG";
      envFrom = [
        {secret = "sonarr";}
        {configMapRef.name = "sonarr";}
      ];
      probes.liveness.enabled = true;
      probes.readiness.enabled = true;
      probes.startup.enabled = true;
    };
    service.sonarr.controller = "sonarr";
    service.sonarr.ports.http.port = port;
    ingress.sonarr.className = "internal";
    ingress.sonarr.hosts = lib.toList {
      host = subdomain;
      paths = lib.toList {
        path = "/";
        service.identifier = "sonarr";
        service.port = "http";
      };
    };
    # TODO figure out persistence needs
  };
}
