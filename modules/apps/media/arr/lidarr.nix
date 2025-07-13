{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkForce mkIf mkMerge toList;
    hostname = "lidarr.${config.domain}";
    port = 80;
    image = {
      imageName = "ghcr.io/home-operations/lidarr";
      imageDigest = "sha256:b2dec31a6ff0a5c99703eea84caf1a9b285fe01c31bc1224641b2c78989b1008";
      hash = "sha256-+x3v392+pq+1mrg+9tIrV5x1Xe9RCq4/bvs5n9bibjw=";
      finalImageTag = "2.13.0.4664";
    };
  in {
    options.services.lidarr.enable = mkEnableOption "lidarr";
    config = mkIf services.lidarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.lidarr = pkgs.dockerTools.pullImage image;};
      opentofu = {
        passwords.lidarr = {
          length = 21;
          upper = false;
          special = false;
        };
        dotfiles.secrets.lidarr.value = "\${ random_password.lidarr.result }";
      };
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.lidarr.url = "https" + "://${hostname}";
        dotfiles.postgres.lidarr.databases = mkForce {
          lidarr-main = "lidarr";
          lidarr-log = "lidarr";
        };
        applications.lidarr = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs.lidarr.title = "lidarr";
          helm.releases.lidarr = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.lidarr.containers.lidarr = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  envFrom = [{secret = "lidarr";} {configMapRef.name = "lidarr";}];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.lidarr.ports.http.port = port;
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
                configMaps.lidarr.data = {
                  LIDARR__APP__INSTANCENAME = "lidarr";
                  LIDARR__AUTH__METHOD = "External";
                  LIDARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
                  LIDARR__LOG__DBENABLED = "False";
                  LIDARR__LOG__LEVEL = "info";
                  LIDARR__SERVER__PORT = builtins.toString port;
                  LIDARR__UPDATE__BRANCH = "develop";
                };
              }
              (mkIf services.reloader.enable {
                controllers.lidarr.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.lidarr = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.postgres.enable {
                configMaps.lidarr.data = {
                  LIDARR__POSTGRES__USER = "lidarr";
                  LIDARR__POSTGRES__HOST = "main.default.svc.cluster.local";
                };
              })
            ];
          };
          resources = mkMerge [
            (mkIf services.external-secrets.enable {
              externalSecrets.lidarr.spec.data = mkMerge [
                (toList {
                  secretKey = "LIDARR__AUTH__APIKEY";
                  remoteRef.key = "lidarr";
                  sourceRef.storeRef.name = "bitwarden";
                  sourceRef.storeRef.kind = "ClusterSecretStore";
                })
                (mkIf services.postgres.enable (toList {
                  secretKey = "LIDARR__POSTGRES__PASSWORD";
                  remoteRef.key = "lidarr.main.credentials.postgresql.acid.zalan.do";
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
