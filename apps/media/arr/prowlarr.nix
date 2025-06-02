{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config.services) prowlarr external-secrets postgres;
    inherit (lib) mkEnableOption mkIf toList;
    subdomain = "prowlarr.${config.domain}";
    port = 9696;
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.prowlarr.enable = mkEnableOption "prowlarr";
    config = mkIf prowlarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.prowlarr = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.prowlarr-api-key = {
        length = 21;
        upper = false;
        special = false;
      };
      kubenix.dotfiles.postgres.prowlarr = {};
      kubenix.kubernetes.helm.releases.prowlarr = {
        namespace = "media";
        extraResources = mkIf (external-secrets.enable && postgres.enable) {
          externalsecrets.prowlarr-postgres.spec = {
            secretStoreRef.name = "kubernetes-default";
            secretStoreRef.kind = "ClusterSecretStore";
            dataFrom = [{extract.key = "prowlarr.main.credentials.postgresql.acid.zalan.do";}];
            target.template.data.PROWLARR__POSTGRES__PASSWORD = "{{ .password }}";
          };
        };
        values = {
          controllers.prowlarr.annotations."reloader.stakater.com/auto" = "true";
          controllers.prowlarr.containers.prowlarr = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            envFrom = [
              {secret = "prowlarr";}
              {secret = "prowlarr-postgres";}
              {configMapRef.name = "prowlarr";}
            ];
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.prowlarr.controller = "prowlarr";
          service.prowlarr.ports.http.port = port;
          ingress.prowlarr.className = "internal";
          ingress.prowlarr.hosts = toList {
            host = subdomain;
            paths = toList {
              path = "/";
              service.identifier = "prowlarr";
              service.port = "http";
            };
          };
          secrets.prowlarr.data.PROWLARR__AUTH__APIKEY = canivete.toBase64 (canivete.vals.sops.default "passwords/prowlarr-api-key");
          configMaps.prowlarr.data = {
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
  };
}
