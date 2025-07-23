{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "jellyfin.${config.domain}";
    image = {
      imageName = "ghcr.io/jellyfin/jellyfin";
      imageDigest = "sha256:e4d1dc5374344446a3a78e43dd211247f22afba84ea2e5a13cbe1a94e1ff2141";
      hash = "sha256-i0m2B9AiixkPOpCC2PdTwUjwBfvCUDMapiTk7cdwutg=";
      finalImageTag = "10.10.7";
    };
  in {
    options.services.jellyfin.enable = mkEnableOption "Jellyfin";
    config = mkIf config.services.jellyfin.enable {
      home-manager = {
        config,
        pkgs,
        ...
      }: {
        home.packages = mkIf (config.dotfiles.profiles.client.workstation.enable && pkgs.stdenv.hostPlatform.isLinux) [pkgs.jftui];
      };
      nixos = {pkgs, ...}: {canivete.kubernetes.images.jellyfin = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.jellyfin.url = "https" + "://${hostname}";
        applications.jellyfin = {
          namespace = "media";
          dotfiles.volsync.pvcs.jellyfin.title = "jellyfin";
          helm.releases.jellyfin = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.jellyfin.containers.jellyfin = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.jellyfin.ports.http.port = 8096;
                persistence = {
                  config = {
                    type = "persistentVolumeClaim";
                    accessMode = "ReadWriteOnce";
                    size = "1Gi";
                  };
                  cache = {
                    type = "persistentVolumeClaim";
                    accessMode = "ReadWriteOnce";
                    size = "1Gi";
                    globalMounts = [{path = "/config/metadata";}];
                  };
                  # TODO how should I actually store media?
                  # media = {
                  #   type = "nfs";
                  #   server = "nfs.internal";
                  #   path = "/mnt/...";
                  #   globalMounts = toList {
                  #     path = "/media";
                  #     readOnly = true;
                  #   };
                  # };
                  tmpfs = {
                    type = "emptyDir";
                    globalMounts = [
                      {
                        path = "/cache";
                        subPath = "cache";
                      }
                      {
                        path = "/config/log";
                        subPath = "log";
                      }
                      {
                        path = "/tmp";
                        subPath = "tmp";
                      }
                    ];
                  };
                };
              }
              (mkIf services.reloader.enable {
                controllers.jellyfin.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.jellyfin = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "external";
                    namespace = "kube-system";
                    sectionName = "https";
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
