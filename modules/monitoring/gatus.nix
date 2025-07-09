{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (config.services) external-secrets gatus postgres prometheus reloader;
    inherit (lib) attrValues mkEnableOption mkIf mkMerge mkOption toList types;
    inherit (types) attrsOf str submodule;
    hostname = "gatus.${domain}";
    image = {
      imageName = "twinproduction/gatus";
      imageDigest = "sha256:e655d13d0cb89c64a2e53a853bbca9556a7238e788bc4a08c19aa5fb7938d0da";
      hash = "sha256-aJJsrHBS8TYe4/MQumvWuE6Trl3gSZSGyosNTdK6ItQ=";
      finalImageTag = "v5.20.0";
    };
  in {
    options.services.gatus.enable = mkEnableOption "gatus";
    config = mkMerge [
      {
        nixidy = {pkgs, ...}: {
          options.dotfiles.gatus.endpoints = mkOption {
            default = {};
            description = "Endpoints for Gatus to query on intervals";
            type = attrsOf (submodule ({name, ...}: {
              freeformType = (pkgs.formats.yaml {}).type;
              options.name = mkOption {
                default = name;
                type = str;
                description = "Endpoint title";
              };
              options.url = mkOption {
                type = str;
                description = "Location Gatus needs to query, shows up as subtitle";
              };
              config = {
                # TODO define options
                # NOTE name HAD to be defined to avoid infinite recursion from "inherit name"
                # TODO what other fields/tests should I use?
                group = "external";
                interval = "1m";
                client.dns-resolver = "tcp://1.1.1.1:53";
                conditions = ["[STATUS] == 200"];
              };
            }));
          };
        };
      }
      (mkIf gatus.enable {
        nixos = {pkgs, ...}: {canivete.kubernetes.images.gatus = pkgs.dockerTools.pullImage image;};
        nixidy = {
          config,
          lib,
          ...
        }: {
          dotfiles.gatus.endpoints.gatus.url = "https" + "://${hostname}";
          dotfiles.postgres.gatus = {};
          applications.gatus = {
            resources = mkMerge [
              {
                httpRoutes.gatus.spec = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "external";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                  rules = toList {
                    backendRefs = toList {
                      name = "gatus";
                      port = 80;
                    };
                  };
                };
              }
              (mkIf (external-secrets.enable && postgres.enable) {
                externalSecrets.gatus.spec = {
                  secretStoreRef.name = "kubernetes-default";
                  secretStoreRef.kind = "ClusterSecretStore";
                  dataFrom = [{extract.key = "gatus.main.credentials.postgresql.acid.zalan.do";}];
                  target.template.data.GATUS_DB_URI = "postgres://gatus:{{ .password }}@main.default.svc.cluster.local:5432/gatus";
                };
              })
            ];
            helm.releases.gatus = {
              namespace = "monitoring";
              chart = lib.helm.downloadHelmChart {
                chart = "gatus";
                version = "1.3.0";
                repo = "https://twin.github.io/helm-charts";
                chartHash = "sha256-Yx25xKWMiXYqXDHcI5rmbo4v0jcBleY9FzFKCRx/vCI=";
              };
              values = {
                image.tag = image.finalImageTag;
                annotations = mkIf reloader.enable {"secret.reloader.stakater.com/auto" = "true";};
                serviceAccount.create = true;
                serviceAccount.autoMount = true;
                secrets = true;
                serviceMonitor.enabled = prometheus.enable;
                config = {
                  storage = mkIf postgres.enable {
                    type = "postgres";
                    path = "$GATUS_DB_URI";
                    caching = true;
                  };
                  metrics = true;
                  debug = false;
                  ui.title = "Status | Gatus";
                  ui.header = "Status";
                  connectivity.checker.target = "1.1.1.1:53";
                  connectivity.checker.interval = "1m";
                  endpoints = attrValues config.dotfiles.gatus.endpoints;
                };
              };
            };
          };
        };
      })
    ];
  };
}
