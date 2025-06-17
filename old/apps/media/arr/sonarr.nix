{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    subdomain = "sonarr.${config.domain}";
    port = 7878;
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.sonarr.enable = lib.mkEnableOption "sonarr";
    config = lib.mkIf config.services.sonarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.sonarr = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.sonarr-api-key = {
        length = 21;
        upper = false;
        special = false;
      };
      kubenix.kubernetes.helm.releases.sonarr = {
        namespace = "media";
        values = {
          controllers.sonarr.annotations."reloader.stakater.com/auto" = "true";
          controllers.sonarr.containers.sonarr = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            envFrom = [{secret = "sonarr";}];
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
          secrets.sonarr.data.SONARR__AUTH__APIKEY = canivete.toBase64 (canivete.vals.sops.default "passwords/sonarr-api-key");
          configMaps.sonarr.data = {
            SONARR__APP__INSTANCENAME = "Radarr";
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
        };
      };
    };
  };
}
