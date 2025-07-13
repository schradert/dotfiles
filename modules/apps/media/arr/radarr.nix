{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkForce mkIf mkMerge toList;
    hostname = "radarr.${config.domain}";
    port = 80;
    image = {
      imageName = "ghcr.io/home-operations/radarr";
      imageDigest = "sha256:f1a47717f5792d82becbe278c9502d756b898d63b2c637da131172c4adf1ffc7";
      hash = "sha256-hMov5Dg3mp0C22akn6MhuoV79sx2/77vd36z5L1X2Os=";
      finalImageTag = "5.27.0.10101";
    };
  in {
    options.services.radarr.enable = mkEnableOption "radarr";
    config = mkIf services.radarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.radarr = pkgs.dockerTools.pullImage image;};
      opentofu = {
        passwords.radarr = {
          length = 21;
          upper = false;
          special = false;
        };
        dotfiles.secrets.radarr.value = "\${ random_password.radarr.result }";
      };
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.radarr.url = "https" + "://${hostname}";
        dotfiles.postgres.radarr.databases = mkForce {
          radarr-main = "radarr";
          radarr-log = "radarr";
        };
        applications.radarr = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs.radarr.title = "radarr";
          helm.releases.radarr = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.radarr.containers.radarr = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  envFrom = [{secret = "radarr";} {configMapRef.name = "radarr";}];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.radarr.ports.http.port = port;
                persistence = {
                  config = {
                    type = "persistentVolumeClaim";
                    accessMode = "ReadWriteOnce";
                    size = "1Gi";
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
                    globalMounts = toList {
                      path = "/tmp";
                      subPath = "tmp";
                    };
                  };
                };
                configMaps.radarr.data = {
                  RADARR__APP__INSTANCENAME = "Radarr";
                  RADARR__AUTH__METHOD = "External";
                  RADARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
                  RADARR__LOG__DBENABLED = "False";
                  RADARR__LOG__LEVEL = "info";
                  RADARR__SERVER__PORT = builtins.toString port;
                  RADARR__UPDATE__BRANCH = "develop";
                };
              }
              (mkIf services.reloader.enable {
                controllers.radarr.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.radarr = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.postgres.enable {
                configMaps.radarr.data = {
                  RADARR__POSTGRES__USER = "radarr";
                  RADARR__POSTGRES__HOST = "main.default.svc.cluster.local";
                };
              })
            ];
          };
          resources = mkMerge [
            (mkIf services.external-secrets.enable {
              externalSecrets.radarr.spec.data = mkMerge [
                (toList {
                  secretKey = "RADARR__AUTH__APIKEY";
                  remoteRef.key = "radarr";
                  sourceRef.storeRef.name = "bitwarden";
                  sourceRef.storeRef.kind = "ClusterSecretStore";
                })
                (mkIf services.postgres.enable (toList {
                  secretKey = "RADARR__POSTGRES__PASSWORD";
                  remoteRef.key = "radarr.main.credentials.postgresql.acid.zalan.do";
                  remoteRef.property = "password";
                  sourceRef.storeRef.name = "kubernetes-default";
                  sourceRef.storeRef.kind = "ClusterSecretStore";
                }))
              ];
            })
          ];
        };
      };
    };
  };
}
