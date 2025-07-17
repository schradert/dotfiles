{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge recursiveUpdate toList;
    hostname = "immich.${config.domain}";
    images.immich-server = {
      imageName = "ghcr.io/immich-app/immich-server";
      imageDigest = "sha256:24df1172544370826349159692d177ba22ca773c81857d36996a254c08422b95";
      hash = "sha256-WjZlN9o3QqucB9EK7LOe8AvoiOqjZDw9OS6tiCYsL8A=";
      finalImageTag = "v1.135.3";
    };
    images.immich-machine-learning = {
      imageName = "ghcr.io/immich-app/immich-machine-learning";
      imageDigest = "sha256:9f2f61d86af82d04926f9b896c995c502303052905517c5485dd26bf1e42a44e";
      hash = "sha256-+AIF5uTO8MRuHvUIuY6geXwsVn6KfBr5KH7fzr+B0qI=";
      inherit (images.immich-server) finalImageTag;
    };
    probe = recursiveUpdate {
      enabled = true;
      custom = true;
      spec = {
        httpGet.path = "/api/server/ping";
        httpGet.port = "http";
        initialDelaySeconds = 0;
        periodSeconds = 10;
        timeoutSeconds = 1;
        failureThreshold = 3;
      };
    };
    serverProbe = recursiveUpdate (probe {spec.httpGet.path = "/api/server/ping";});
    mlProbe = recursiveUpdate (probe {spec.httpGet.path = "/ping";});
  in {
    options.services.immich.enable = mkEnableOption "Immich";
    config = mkIf config.services.immich.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      nixidy = {charts, ...}: {
        dotfiles.postgres.immich.preparedDatabases.immich.extensions = {
          vectors = "public";
          cube = "public";
          earthdistance = "public";
        };
        applications.immich = {
          namespace = "dotfiles";
          helm.releases.immich-server = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                configMaps.immich-server.data = {
                  IMMICH_CONFIG_FILE = "/config/immich.json";
                  DB_HOSTNAME = "main.default.svc.cluster.local";
                  DB_USERNAME = "immich";
                  DB_PASSWORD_FILE = "/secrets/db_password.txt";
                  # TODO redis configuration
                };
                # TODO configure UI
                configMaps.immich-server-files.data."immich.json" = builtins.toJSON {};
                controllers.immich-server.strategy = "RollingUpdate";
                controllers.immich-server.containers.immich-server = {
                  image.repository = images.immich-server.imageName;
                  image.tag = images.immich-server.finalImageTag;
                  envFrom = [{configMapRef.name = "immich-server";}];
                  probes.liveness = serverProbe {};
                  probes.readiness = serverProbe {};
                  probes.startup = serverProbe {spec.failureThreshold = 30;};
                };
                persistence.config = {
                  type = "configMap";
                  name = "immich-server-files";
                };
                persistence.secrets = {
                  type = "secret";
                  name = "immich-server";
                };
                persistence.library = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "1Gi";
                  advancedMounts.immich-server.immich-server = [{path = "/usr/src/app/upload";}];
                };
                service.immich-server.ports.http = {
                  primary = true;
                  port = 2283;
                };
              }
              (mkIf services.reloader.enable {
                controllers.immich-server.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.immich-server = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.prometheus.enable {
                configMaps.immich-server.data.IMMICH_TELEMETRY_INCLUDE = "all";
                service.immich-server.ports = {
                  metrics-api.port = 8081;
                  metrics-ms.port = 8082;
                };
                serviceMonitor.immich-server.endpoints = [
                  {port = "metrics-api";}
                  {port = "metrics-ms";}
                ];
              })
            ];
          };
          helm.releases.immich-machine-learning = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.immich-machine-learning.strategy = "RollingUpdate";
                controllers.immich-machine-learning.containers.immich-machine-learning = {
                  image.repository = images.immich-machine-learning.imageName;
                  image.tag = images.immich-machine-learning.finalImageTag;
                  probes.liveness = mlProbe {};
                  probes.readiness = mlProbe {};
                  probes.startup = mlProbe {spec.failureThreshold = 60;};
                };
                persistence.cache = {
                  type = "persistentVolumeClaim";
                  # TODO convert to ReadWriteMany?
                  accessMode = "ReadWriteOnce";
                  size = "10Gi";
                };
                service.immich-machine-learning.ports.http.port = 3003;
              }
              (mkIf services.reloader.enable {
                controllers.immich-machine-learning.annotations."reloader.stakater.com/auto" = "true";
              })
            ];
          };
          resources = mkMerge [
            (mkIf services.external-secrets.enable {
              externalSecrets.immich-server.spec.data = mkMerge [
                (mkIf services.postgres.enable (toList {
                  secretKey = "db_password.txt";
                  remoteRef.key = "immich.main.credentials.postgresql.acid.zalan.do";
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
