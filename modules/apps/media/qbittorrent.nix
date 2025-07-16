{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "qbittorrent.${config.domain}";
    port = 8080;
    torrentPort = 6881;
    image = {
      imageName = "ghcr.io/home-operations/qbittorrent";
      imageDigest = "sha256:a724f86a39fa637fc4ff81165585d7273dc9dcd9ca59818a34e9fa9c467dd26c";
      hash = "sha256-sJJ3Lfw7RTwcaPoEY3s4JI/NQ3uqCJ9rHz9Hi2krcR4=";
      finalImageTag = "5.1.2";
    };
  in {
    options.services.qbittorrent.enable = mkEnableOption "qbittorrent";
    config = mkIf config.services.qbittorrent.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.qbittorrent = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.qbittorrent.url = "https" + "://${hostname}";
        applications.qbittorrent = {
          namespace = "media";
          dotfiles.volsync.pvcs.qbittorrent.title = "qbittorrent";
          helm.releases.qbittorrent = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.qbittorrent.containers.qbittorrent = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.qbittorrent = {
                  primary = true;
                  ports.http.port = port;
                };
                service.torrent = {
                  type = "LoadBalancer";
                  ports.torrent.port = torrentPort;
                  ports.torrent.protocol = "TCP";
                };
                persistence.config = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "1Gi";
                };
                persistence.tmp.type = "emptyDir";
                # TODO how should I actually store media?
                # persistence.media = {
                #   type = "nfs";
                #   server = "nfs.internal";
                #   path = "/mnt/...";
                #   globalMounts = toList {
                #     path = "/media/Downloads/qbittorrent";
                #     subPath = "Downloads/qbittorrent";
                #   };
                # };
              }
              (mkIf services.reloader.enable {
                controllers.qbittorrent.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                service.torrent.annotations."lbipam.cilium.io/ips" = "192.168.50.253";
                route.qbittorrent = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                  rules = toList {
                    backendRefs = toList {
                      identifier = "qbittorrent";
                      inherit port;
                    };
                  };
                };
              })
            ];
          };
        };
      };
    };
  };
}
