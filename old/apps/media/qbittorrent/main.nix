{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (lib) mapAttrs mkEnableOption toList mkIf;
    subdomain = "qbittorrent.${domain}";
    port = 8080;
    probe.enabled = true;
    probe.custom = true;
    probe.spec = {
      httpGet.path = "/api/v2/app/version";
      httpGet.port = port;
      initialDelaySeconds = 30;
      periodSeconds = 30;
      timeoutSeconds = 10;
      failureThreshold = 6;
    };
    images = {
      qbittorrent = {
        imageName = "ghcr.io/onedr0p/qbittorrent";
        imageDigest = "";
        hash = "";
        finalImageTag = "";
      };
      dnsdist = {
        imageName = "powerdns/dnsdist-19";
        imageDigest = "";
        hash = "";
        finalImageTag = "";
      };
      gluetun = {
        imageName = "qmcgaw/gluetun";
        imageDigest = "";
        hash = "";
        finalImageTag = "";
      };
      gluetun-qb-port-sync = {
        imageName = "ghcr.io/bjw-s-labs/gluetun-qb-port-sync";
        imageDigest = "";
        hash = "";
        finalImageTag = "";
      };
    };
  in {
    options.services.qbittorrent.enable = mkEnableOption "qbittorrent";
    config = mkIf config.services.qbittorrent.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      kubenix.dotfiles.gatus.qbittorrent.url = "https://${subdomain}";
      kubenix.kubernetes.helm.releases.qbittorrent = {
        namespace = "media";
        values = {
          controllers.qbittorrent.annotations."reloader.stakater.com/auto" = "true";
          controllers.qbittorrent.containers = {
            qbittorrent = {
              image.repository = images.qbittorrent.imageName;
              image.tag = images.qbittorrent.finalImageTag;
              envFrom = [
                {configMapRef.name = "qbittorrent-configmap";}
                {secret = "qbittorrent-secret";}
              ];
              probes.liveness = probe;
              probes.readiness = probe;
              probes.startup = {
                enabled = true;
                spec.failureThreshold = 30;
                spec.periodSeconds = 10;
              };
              resources.requests.cpu = "100m";
              resources.requests.memory = "1Gi";
              resources.limits.memory = "8Gi";
            };
            dnsdist.image.repository = images.dnsdist.imageName;
            dnsdist.image.tag = images.dnsdist.finalImageTag;
            gluetun = {
              image.repository = images.gluetun.imageName;
              image.tag = images.gluetun.finalImageTag;
              envFrom = [
                {configMapRef.name = "qbittorrent-gluetun";}
                {secret = "qbittorrent-secret";}
              ];
              resources.limits."squat.ai/tun" = "1";
            };
            sync.image.repository = images.gluetun-qb-port-sync.imageName;
            sync.image.tag = images.gluetun-qb-port-sync.finalImageTag;
            sync.envFrom = [{configMapRef.name = "qbittorrent-sync";}];
          };
          service.qbittorrent.controller = "qbittorrent";
          service.qbittorrent.ports.http.port = port;
          ingress.qbittorrent = {
            annotations."external-dns.alpha.kubernetes.io/target" = "internal.${domain}";
            className = "internal";
            hosts = toList {
              host = subdomain;
              paths = toList {
                path = "/";
                service.identifier = "qbittorrent";
                service.port = "http";
              };
            };
          };
          persistence = {
            config.existingClaim = "qbittorrent-config";
            config.advancedMounts.qbittorrent.qbittorrent = [{path = "/config";}];
            dnsdist.type = "configMap";
            dnsdist.name = "qbittorrent-files";
            dnsdist.advancedMounts.qbittorrent.dnsdist = toList {
              path = "/etc/dnsdist/dnsdist.conf";
              subPath = "dnsdist.conf";
              readOnly = true;
            };
            media.existingClaim = "qbittorrent-media";
            media.advancedMounts.qbittorrent.qbittorrent = [{path = "/downloads";}];
            sync.type = "emptyDir";
            sync.advancedMounts.qbittorrent.sync = [{path = "/config";}];
          };
          configMaps = {
            qbittorrent-configmap.data = {
              QBITTORRENT__PORT = toString port;
              QBT_Preferences__WebUI__AlternativeUIEnabled = "false";
              QBT_Preferences__WebUI__AuthSubnetWhitelistEnabled = "true";
              QBT_Preferences__WebUI__AuthSubnetWhitelist = "10.42.0.0/16,192.168.50.0/24";
            };
            qbittorrent-gluetun.data = {
              DOT = "off";
              DNS_ADDRESS = "127.0.0.2";
              VPN_SERVICE_PROVIDER = "custom";
              VPN_TYPE = "wireguard";
              VPN_INTERFACE = "wg0";
              WIREGUARD_ENDPOINT_PORT = "51820";
              VPN_PORT_FORWARDING = "on";
              VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
              FIREWALL_INPUT_PORTS = toString port;
              FIREWALL_OUTBOUND_SUBNETS = "10.43.0.0/16,192.168.50.0/24";
            };
            qbittorrent-sync.data = {
              CRON_ENABLED = "true";
              QBITTORRENT_WEBUI_PORT = toString port;
              LOG_TIMESTAMP = "false";
            };
            qbittorrent-files.data."dnsdist.conf" = builtins.readFile ./dnsdist.conf;
          };
        };
      };
    };
  };
}
