{
  config,
  lib,
  ...
}: let
  inherit (lib) toList;
  inherit (config.canivete.meta) domain;
  subdomain = "atuin.${domain}";
  port = 8888;
  metricsPort = 8080;
  image = {
    imageName = "ghcr.io/atuinsh/atuin";
    imageDigest = "";
    hash = "";
    finalImageTag = "18.3.0";
  };
in {
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config.services) atuin external-secrets postgres;
  in {
    options.services.atuin.enable = lib.mkEnableOption "Atuin";
    config = lib.mkIf atuin.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.atuin = pkgs.dockerTools.pullImage image;};
      kubenix.dotfiles = {
        gatus.endpoints.atuin.url = "https://${subdomain}";
        postgres.atuin = {};
      };
      kubenix.kubernetes.helm.releases.atuin = {
        namespace = "search";
        extraResources = lib.mkIf (external-secrets.enable && postgres.enable) {
          externalsecrets.atuin.spec = {
            secretStoreRef.name = "kubernetes-default";
            secretStoreRef.kind = "ClusterSecretStore";
            dataFrom = [{extract.key = "atuin.main.credentials.postgresql.acid.zalan.do";}];
            target.template.data.ATUIN_DB_URI = "postgres://atuin:{{ .password }}@main.default.svc.cluster.local:5432/atuin";
          };
        };
        values = {
          controllers.atuin.annotations."reloader.stakater.com/auto" = "true";
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
            resources.requests.cpu = "10m";
            resources.requests.memory = "128Mi";
            resources.limits.memory = "512Mi";
          };
          service.atuin.controller = "atuin";
          service.atuin.ports = {
            http.primary = true;
            http.port = port;
            metrics.port = metricsPort;
          };
          serviceMonitor.atuin.serviceName = "atuin";
          serviceMonitor.atuin.endpoints = toList {
            port = "metrics";
            scheme = "http";
            path = "/metrics";
            interval = "1m";
            scrapeTimeout = "10s";
          };
          ingress.atuin = {
            annotations."external-dns.alpha.kubernetes.io/target" = "internal.${domain}";
            className = "internal";
            hosts = toList {
              host = subdomain;
              paths = toList {
                path = "/";
                service.identifier = "atuin";
                service.port = "http";
              };
            };
          };
          persistence.config.type = "emptyDir";
          configMaps.atuin.data = {
            ATUIN_HOST = "0.0.0.0";
            ATUIN_PORT = toString port;
            ATUIN_OPEN_REGISTRATION = "true";
            ATUIN_TLS__ENABLE = "false";
            ATUIN_METRICS__ENABLE = "true";
            ATUIN_METRICS__HOST = "0.0.0.0";
            ATUIN_METRICS__PORT = toString metricsPort;
          };
        };
      };
    };
  };
}
