{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    subdomain = "lidarr.${config.domain}";
    port = 7878;
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.lidarr.enable = lib.mkEnableOption "lidarr";
    config = lib.mkIf config.services.lidarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.lidarr = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.lidarr-api-key = {
        length = 21;
        upper = false;
        special = false;
      };
      kubenix.kubernetes.helm.releases.lidarr = {
        namespace = "media";
        values = {
          controllers.lidarr.annotations."reloader.stakater.com/auto" = "true";
          controllers.lidarr.containers.lidarr = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            envFrom = [{secret = "lidarr";}];
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.lidarr.controller = "lidarr";
          service.lidarr.ports.http.port = port;
          ingress.lidarr.className = "internal";
          ingress.lidarr.hosts = lib.toList {
            host = subdomain;
            paths = lib.toList {
              path = "/";
              service.identifier = "lidarr";
              service.port = "http";
            };
          };
          secrets.lidarr.data.LIDARR__AUTH__APIKEY = canivete.toBase64 (canivete.vals.sops.default "passwords/lidarr-api-key");
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
        };
      };
    };
  };
}
