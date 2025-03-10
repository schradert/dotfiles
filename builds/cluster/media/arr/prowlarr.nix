{
  config,
  lib,
  ...
}: let
  port = 9696;
  subdomain = "prowlarr.${config.canivete.meta.domain}";
in {
  # TODO how useful is https://github.com/sergiotapia/magnetissimo
  perSystem.canivete = {
    opentofu.workspaces.deploy.modules.prowlarr.canivete.passwords = {
      prowlarr-api-key = {
        length = 21;
        upper = false;
        special = false;
      };
      prowlarr-postgres-password.length = 21;
    };
    nix2container.prowlarr = {};
    # kubenix.helm.postgres.resources.postgresqls.main.spec = {
    #   users.prowlarr = ["superuser" "createdb"];
    #   databases.prowlarr = "prowlarr";
    # };
    kubenix.helm.prowlarr = {
      namespace = "media";
      values = {
        controllers.prowlarr.containers.prowlarr = {
          image.repository = "ref+envsubst://PROWLARR_IMAGE_FULLREPOSITORY+";
          image.tag = "ref+envsubst://PROWLARR_IMAGE_TAG";
          envFrom = [
            {secret = "prowlarr";}
            {configMapRef.name = "prowlarr";}
          ];
          probes.liveness.enabled = true;
          probes.readiness.enabled = true;
          probes.startup.enabled = true;
        };
        service.prowlarr.controller = "prowlarr";
        service.prowlarr.ports.http.port = port;
        ingress.prowlarr.className = "internal";
        ingress.prowlarr.hosts = lib.toList {
          host = subdomain;
          paths = lib.toList {
            path = "/";
            service.identifier = "prowlarr";
            service.port = "http";
          };
        };
        secrets.prowlarr.enabled = true;
        secrets.prowlarr.stringData = {
          PROWLARR__AUTH__APIKEY = "ref+envsubst://PROWLARR_API_KEY";
          PROWLARR__POSTGRES__PASSWORD = "ref+envsubst://PROWLARR_POSTGRES_PASSWORD";
        };
        configMaps.prowlarr.enabled = true;
        configMaps.prowlarr.data = {
          # TODO Figure out what all of these settings do!
          PROWLARR__APP__INSTANCENAME = "Prowlarr";
          PROWLARR__APP__THEME = "Auto";
          PROWLARR__APP__LAUNCHBROWSER = "false";
          PROWLARR__AUTH__ENABLED = "";
          PROWLARR__AUTH__METHOD = "External";
          PROWLARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
          PROWLARR__SERVER__URLBASE = "https://${subdomain}";
          PROWLARR__SERVER__BINDADDRESS = "*";
          PROWLARR__SERVER__PORT = toString port;
          PROWLARR__SERVER__ENABLESSL = "";
          PROWLARR__SERVER__SSLPORT = "";
          PROWLARR__SERVER__SSLCERTPATH = "";
          PROWLARR__SERVER__SSLCERTPASSWORD = "";
          PROWLARR__LOG__LEVEL = "info";
          PROWLARR__LOG__FILTERSENTRYEVENTS = "";
          PROWLARR__LOG__ROTATE = "";
          PROWLARR__LOG__SQL = "";
          PROWLARR__LOG__CONSOLELEVEL = "";
          PROWLARR__LOG__ANALYTICSENABLED = "true";
          PROWLARR__LOG__SYSLOGSERVER = "";
          PROWLARR__LOG__SYSLOGPORT = "";
          PROWLARR__LOG__SYSLOGLEVEL = "";
          PROWLARR__UPDATE__MECHANISM = "";
          PROWLARR__UPDATE__AUTOMATICALLY = "";
          PROWLARR__UPDATE__SCRIPTPATH = "";
          PROWLARR__UPDATE__BRANCH = "";
          PROWLARR__POSTGRES__HOST = "postgres-main.data.svc.cluster.local";
          PROWLARR__POSTGRES__PORT = "5432";
          PROWLARR__POSTGRES__USER = "prowlarr";
          PROWLARR__POSTGRES__MAINDB = "prowlarr";
        };
      };
    };
  };
}
