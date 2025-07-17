{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "atuin.${config.domain}";
    port = 8888;
    metricsPort = 8080;
    image = {
      imageName = "ghcr.io/atuinsh/atuin";
      imageDigest = "sha256:869a85bcc169ae9a3ea65dcf32a99dae982d28d8562172e2712d3313d7349203";
      hash = "";
      finalImageTag = "v18.6.1";
    };
  in {
    options.services.atuin.enable = mkEnableOption "Atuin";
    config = mkIf services.atuin.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.atuin = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.atuin.url = "https" + "://${hostname}";
        dotfiles.postgres.atuin = {};
        applications.atuin = {
          namespace = "dotfiles";
          helm.releases.atuin = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.atuin.containers.atuin = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  args = ["server" "start"];
                  envFrom = [
                    {secret = "atuin";}
                    {configMapRef.name = "atuin";}
                  ];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.atuin.ports.http = {
                  primary = true;
                  inherit port;
                };
                persistence.config.type = "emptyDir";
                configMaps.atuin.data = {
                  ATUIN_HOST = "0.0.0.0";
                  ATUIN_PORT = builtins.toString port;
                };
              }
              (mkIf services.reloader.enable {
                controllers.atuin.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.atuin = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.prometheus.enable {
                configMaps.atuin.data = {
                  ATUIN_METRICS__ENABLE = "true";
                  ATUIN_METRICS__HOST = "0.0.0.0";
                  ATUIN_METRICS__PORT = builtins.toString metricsPort;
                };
                service.atuin.ports.metrics.port = metricsPort;
                serviceMonitor.atuin.endpoints = toList {
                  port = "metrics";
                  scheme = "http";
                  path = "/metrics";
                  interval = "1m";
                  scrapeTimeout = "10s";
                };
              })
            ];
          };
          resources = mkIf (services.external-secrets.enable && services.postgres.enable) {
            externalSecrets.atuin.spec = {
              secretStoreRef.name = "kubernetes-default";
              secretStoreRef.kind = "ClusterSecretStore";
              dataFrom = [{extract.key = "atuin.main.credentials.postgresql.acid.zalan.do";}];
              target.template.data.ATUIN_DB_URI = "postgres://atuin:{{ .password }}@main.default.svc.cluster.local:5432/atuin";
            };
          };
        };
      };
    };
  };
}
