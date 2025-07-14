{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkForce mkIf mkMerge toList;
    hostname = "prowlarr.${config.domain}";
    port = 80;
    image = {
      imageName = "ghcr.io/home-operations/prowlarr";
      imageDigest = "sha256:e9e0cf64a1ab90ca61688de85bb732d7c3e5142d40a2d9af6172551252cb31c3";
      hash = "sha256-UnU9XpzF5TE2VMB82k2da4tFhxWxzLoh9NuSYHpbBDE=";
      finalImageTag = "2.0.1.5101";
    };
  in {
    options.services.prowlarr.enable = mkEnableOption "prowlarr";
    config = mkIf services.prowlarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.prowlarr = pkgs.dockerTools.pullImage image;};
      opentofu = {
        passwords.prowlarr = {
          length = 21;
          upper = false;
          special = false;
        };
        dotfiles.secrets.prowlarr.value = "\${ random_password.prowlarr.result }";
      };
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.prowlarr.url = "https" + "://${hostname}";
        dotfiles.postgres.prowlarr.databases = mkForce {
          prowlarr-main = "prowlarr";
          prowlarr-log = "prowlarr";
        };
        applications.prowlarr = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs.prowlarr.title = "prowlarr";
          helm.releases.prowlarr = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.prowlarr.containers.prowlarr = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  envFrom = [{secret = "prowlarr";} {configMapRef.name = "prowlarr";}];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.prowlarr.ports.http.port = port;
                persistence = {
                  config = {
                    type = "persistentVolumeClaim";
                    accessMode = "ReadWriteOnce";
                    size = "1Gi";
                  };
                  tmpfs.type = "emptyDir";
                };
                configMaps.prowlarr.data = {
                  PROWLARR__APP__INSTANCENAME = "prowlarr";
                  PROWLARR__AUTH__METHOD = "External";
                  PROWLARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
                  PROWLARR__LOG__DBENABLED = "False";
                  PROWLARR__LOG__LEVEL = "info";
                  PROWLARR__SERVER__PORT = builtins.toString port;
                  PROWLARR__UPDATE__BRANCH = "develop";
                };
              }
              (mkIf services.reloader.enable {
                controllers.prowlarr.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.prowlarr = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.postgres.enable {
                configMaps.prowlarr.data = {
                  PROWLARR__POSTGRES__USER = "prowlarr";
                  PROWLARR__POSTGRES__HOST = "main.default.svc.cluster.local";
                };
              })
            ];
          };
          resources = mkMerge [
            (mkIf services.external-secrets.enable {
              externalSecrets.prowlarr.spec.data = mkMerge [
                (toList {
                  secretKey = "PROWLARR__AUTH__APIKEY";
                  remoteRef.key = "prowlarr";
                  sourceRef.storeRef.name = "bitwarden";
                  sourceRef.storeRef.kind = "ClusterSecretStore";
                })
                (mkIf services.postgres.enable (toList {
                  secretKey = "PROWLARR__POSTGRES__PASSWORD";
                  remoteRef.key = "prowlarr.main.credentials.postgresql.acid.zalan.do";
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
