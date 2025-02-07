{
  config,
  lib,
  ...
}: let
  inherit (lib) toList;
  inherit (config.dotfiles) domain;
  subdomain = "atuin.${domain}";
  port = 8888;
  metricsPort = 8080;
in {
  perSystem.dotfiles.nix2container.atuin = {};
  perSystem.dotfiles.helm.gatus.values.config.endpoints = toList {
    name = "atuin";
    group = "internal";
    url = "1.1.1.1";
    interval = "1m";
    ui.hide-hostname = true;
    ui.hide-url = true;
    dns.query-name = subdomain;
    dns.query-type = "A";
    conditions = ["len([BODY]) == 0"];
    # alerts = [{type = "custom";}]; TODO
  };
  perSystem.dotfiles.helm.postgres.resources.postgresqls.main.spec = {
    users.atuin = ["createdb"];
    databases.atuin = "atuin";
  };
  perSystem.dotfiles.helm.atuin = {
    namespace = "search";
    values = {
      controllers.atuin.annotations."reloader.stakater.com/auto" = "true";
      controllers.atuin.containers.atuin = {
        image.repository = "ghcr.io/atuinsh/atuin";
        image.tag = "18.3.0";
        args = ["server" "start"];
        envFrom = [
          {secret = "atuin-secret";}
          {configMapRef.name = "atuin-configmap";}
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
        annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
        annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
        annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
        className = "external";
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
    };
    resources.configMaps.atuin-configmap.data = {
      ATUIN_HOST = "0.0.0.0";
      ATUIN_PORT = toString port;
      ATUIN_OPEN_REGISTRATION = "true";
      ATUIN_TLS__ENABLE = "false";
      ATUIN_METRICS__ENABLE = "true";
      ATUIN_METRICS__HOST = "0.0.0.0";
      ATUIN_METRICS__PORT = toString metricsPort;
    };
    resources.externalsecrets.atuin.spec = {
      dataFrom = toList {
        extract.key = "atuin.main.credentials.postgresql.acid.zalan.do";
        sourceRef.storeRef.kind = "ClusterSecretStore";
        sourceRef.storeRef.name = "kubernetes-storage";
      };
      target.name = "atuin-secret";
      target.template.engineVersion = "v2";
      target.template.data.ATUIN_DB_URI = "postgres://atuin:{{ .password }}@main.storage.svc.cluster.local:5432/atuin";
    };
  };
}
