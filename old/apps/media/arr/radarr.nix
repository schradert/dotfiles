{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    subdomain = "radarr.${config.domain}";
    port = 7878;
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.radarr.enable = lib.mkEnableOption "radarr";
    config = lib.mkIf config.services.radarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.radarr = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.radarr-api-key = {
        length = 21;
        upper = false;
        special = false;
      };
      kubenix.kubernetes.helm.releases.radarr = {
        namespace = "media";
        values = {
          controllers.radarr.annotations."reloader.stakater.com/auto" = "true";
          controllers.radarr.containers.radarr = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            envFrom = [{secret = "radarr";}];
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.radarr.controller = "radarr";
          service.radarr.ports.http.port = port;
          ingress.radarr.className = "internal";
          ingress.radarr.hosts = lib.toList {
            host = subdomain;
            paths = lib.toList {
              path = "/";
              service.identifier = "radarr";
              service.port = "http";
            };
          };
          secrets.radarr.data.RADARR__AUTH__APIKEY = canivete.toBase64 (canivete.vals.sops.default "passwords/radarr-api-key");
          configMaps.radarr.data = {
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
        };
      };
    };
  };
}
