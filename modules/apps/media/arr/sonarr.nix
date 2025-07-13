{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkForce mkIf mkMerge toList;
    hostname = "sonarr.${config.domain}";
    port = 80;
    image = {
      imageName = "ghcr.io/home-operations/sonarr";
      imageDigest = "sha256:ca6c735014bdfb04ce043bf1323a068ab1d1228eea5bab8305ca0722df7baf78";
      hash = "sha256-Fsv3xLeCioiDIVGR7qYcUy1J1afsSuH2o4HqZiTXFxU=";
      finalImageTag = "4.0.15.2940";
    };
  in {
    options.services.sonarr.enable = mkEnableOption "sonarr";
    config = mkIf services.sonarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.sonarr = pkgs.dockerTools.pullImage image;};
      opentofu = {
        passwords.sonarr = {
          length = 21;
          upper = false;
          special = false;
        };
        dotfiles.secrets.sonarr.value = "\${ random_password.sonarr.result }";
      };
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.sonarr.url = "https" + "://${hostname}";
        dotfiles.postgres.sonarr.databases = mkForce {
          sonarr-main = "sonarr";
          sonarr-log = "sonarr";
        };
        applications.sonarr = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs.sonarr.title = "sonarr";
          helm.releases.sonarr = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.sonarr.containers.sonarr = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  envFrom = [{secret = "sonarr";} {configMapRef.name = "sonarr";}];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.sonarr.ports.http.port = port;
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
                configMaps.sonarr.data = {
                  SONARR__APP__INSTANCENAME = "sonarr";
                  SONARR__AUTH__METHOD = "External";
                  SONARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
                  SONARR__LOG__DBENABLED = "False";
                  SONARR__LOG__LEVEL = "info";
                  SONARR__SERVER__PORT = builtins.toString port;
                  SONARR__UPDATE__BRANCH = "develop";
                };
              }
              (mkIf services.reloader.enable {
                controllers.sonarr.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.sonarr = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.postgres.enable {
                configMaps.sonarr.data = {
                  SONARR__POSTGRES__USER = "sonarr";
                  SONARR__POSTGRES__HOST = "main.default.svc.cluster.local";
                };
              })
            ];
          };
          resources = mkMerge [
            (mkIf services.external-secrets.enable {
              externalSecrets.sonarr.spec.data = mkMerge [
                (toList {
                  secretKey = "SONARR__AUTH__APIKEY";
                  remoteRef.key = "sonarr";
                  sourceRef.storeRef.name = "bitwarden";
                  sourceRef.storeRef.kind = "ClusterSecretStore";
                })
                (mkIf services.postgres.enable (toList {
                  secretKey = "SONARR__POSTGRES__PASSWORD";
                  remoteRef.key = "sonarr.main.credentials.postgresql.acid.zalan.do";
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
