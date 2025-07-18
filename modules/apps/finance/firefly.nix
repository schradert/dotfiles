{
  # TODO https://docs.firefly-iii.org/how-to/data-importer/how-to-configure/
  # TODO https://github.com/dvankley/firefly-plaid-connector-2
  # TODO create access token at firefly/token
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge recursiveUpdate toList;
    hostname = "firefly.${config.domain}";
    images = {
      firefly-iii = {
        imageName = "fireflyiii/core";
        imageDigest = "sha256:b7b0fca5430446c1c90a0918e28f5816ea9d58b9f65f43c866ad983c96b223b9";
        hash = "sha256-awrJwQLBsQpqWilxhR6aRssXkS/MDAKcL+AYYoYVpVc=";
        finalImageTag = "version-6.2.21";
      };
      firefly-iii-data-importer = {
        imageName = "fireflyiii/data-importer";
        imageDigest = "sha256:f84136f79053acde544a0d75389522c48830692117068537231169216a55de1d";
        hash = "sha256-G3kqtLjjULmwkskE0+aDL60lAbiI6q2s5tQtqPN3QNo=";
        finalImageTag = "version-1.7.7-cli";
      };
    };
    probe = recursiveUpdate {
      enabled = true;
      custom = true;
      spec.httpGet.path = "/health";
      spec.httpGet.port = "http";
    };
  in {
    options.services.firefly.enable = mkEnableOption "firefly-iii";
    config = mkIf services.firefly.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      opentofu = {
        dotfiles.secrets."firefly/key".value = "\${ random_password.firefly.result }";
        passwords.firefly = {
          length = 32;
          special = false;
        };
      };
      nixidy = {charts, ...}: {
        dotfiles.postgres.firefly = {};
        applications.firefly = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs.firefly = "firefly";
          helm.releases.firefly = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.firefly.containers.firefly = {
                  image.repository = images.firefly-iii.imageName;
                  image.tag = images.firefly-iii.finalImageTag;
                  probes.liveness = probe {};
                  probes.readiness = probe {
                    spec.initialDelaySeconds = 15;
                    spec.timeoutSeconds = 1;
                  };
                  probes.startup = probe {
                    spec.failureThreshold = 30;
                    spec.periodSeconds = 10;
                  };
                };
                service.firefly.ports.http.port = 8080;
                persistence.secrets = {
                  type = "secret";
                  name = "firefly";
                };
                persistence.upload = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "1Gi";
                  globalMounts = [{path = "/var/www/html/storage/upload";}];
                };
                persistence.config = {
                  type = "configMap";
                  name = "firefly";
                  globalMounts = toList {
                    path = "/.env";
                    readOnly = true;
                  };
                };
                configMaps.firefly.data = {
                  AUTHENTICATION_GUARD = "remote_user_guard";
                  AUTHENTICATION_GUARD_HEADER = "HTTP_X_AUTH_REQUEST_PREFERRED_USERNAME";
                  AUTHENTICATION_GUARD_EMAIL = "HTTP_X_AUTH_REQUEST_EMAIL";
                  APP_KEY_FILE = "/secrets/app_key.txt";
                };
              }
              (mkIf services.reloader.enable {
                controllers.firefly.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.firefly = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.postgres.enable {
                configMaps.firefly.data = {
                  DB_PASSWORD_FILE = "/secrets/db_password.txt";
                  DB_HOST = "main.storage.svc.cluster.local";
                };
              })
            ];
          };
          helm.releases.firefly-importer = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.firefly-importer.containers.firefly-importer = {
                  image.repository = images.firefly-iii-data-importer.imageName;
                  image.tag = images.firefly-iii-data-importer.finalImageTag;
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.firefly-importer.ports.http.port = 8080;
                persistence.secrets = {
                  type = "secret";
                  name = "firefly-importer";
                };
                persistence.config = {
                  type = "configMap";
                  name = "firefly-importer";
                  globalMounts = toList {
                    path = "/.env";
                    readOnly = true;
                  };
                };
                configMaps.firefly-importer.data = {
                  IGNORE_DUPLICATE_ERRORS = "false";
                  FIREFLY_III_URL = "http" + "://firefly.dotfiles.svc.cluster.local";
                  VANITY_URL = "https" + "://${hostname}";
                };
              }
              (mkIf services.reloader.enable {
                controllers.firefly-importer.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.firefly-importer = {
                  hostnames = ["firefly-importer-${config.me}.${config.domain}"];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
            ];
          };
          resources = mkMerge [
            (mkIf services.external-secrets.enable {
              externalSecrets.firefly.spec.data = mkMerge [
                (toList {
                  secretKey = "app_key.txt";
                  remoteRef.key = "firefly/key";
                  sourceRef.storeRef.name = "bitwarden";
                  sourceRef.storeRef.kind = "ClusterSecretStore";
                })
                (mkIf services.postgres.enable (toList {
                  secretKey = "db_password.txt";
                  remoteRef.key = "firefly.main.credentials.postgresql.acid.zalan.do";
                  remoteRef.property = "password";
                  sourceRef.storeRef.name = "kubernetes-default";
                  sourceRef.storeRef.kind = "ClusterSecretStore";
                }))
              ];
              externalSecrets.firefly-importer.spec.data = toList {
                secretKey = "app_token.txt";
                remoteRef.key = "firefly/token";
                sourceRef.storeRef.name = "bitwarden";
                sourceRef.storeRef.kind = "ClusterSecretStore";
              };
            })
          ];
        };
      };
    };
  };
}
