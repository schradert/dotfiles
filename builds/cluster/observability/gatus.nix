{
  config,
  lib,
  ...
}: let
  inherit (config.canivete.meta) domain;
  subdomain = "gatus.${domain}";
in {
  # https://github.com/TwiN/gatus
  # TODO compare with https://github.com/cachethq/cachet
  # TODO compare with https://github.com/louislam/uptime-kuma
  perSystem.canivete.kubenix.helm.postgres.resources.postgresqls.main.spec = {
    users.gatus = ["createdb"];
    databases.gatus = "gatus";
  };
  perSystem.canivete.kubenix.helm.gatus = {
    namespace = "observability";
    chart = {
      repo = "https://twin.github.io/helm-charts";
      chart = "gatus";
      version = "1.0.0";
      sha256 = "+i0h3T5R9vF0z4o8dGy9EqLL2VQnX192iLJkaHOJ9mk=";
    };
    values = {
      image.tag = "latest";
      image.sha = "fca1fbb4b8474f3a8049501bd58a20b61ad011843da6940f86c378c8e9fcfc28";
      annotations."secret.reloader.stakater.com/reload" = "gatus";
      serviceAccount.create = true;
      serviceAccount.autoMount = true;
      ingress = {
        enabled = true;
        annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
        ingressClassName = "external";
        hosts = [subdomain];
      };
      resources.requests.cpu = "10m";
      resources.requests.memory = "128Mi";
      resources.limits.memory = "256Mi";
      serviceMonitor.enabled = true;
      secrets = true;
      env.GATUS_DELAY_START_SECONDS = "5";
      config = {
        storage.type = "postgres";
        storage.path = "$GATUS_DB_URI";
        storage.caching = true;
        metrics = true;
        debug = false;
        ui.title = "Status | Gatus";
        ui.header = "Status";
        alerting = {}; # TODO
        connectivity.checker.target = "1.1.1.1:53";
        connectivity.checker.interval = "1m";
        endpoints = lib.toList {
          name = "status";
          group = "external";
          url = "https://${subdomain}";
          interval = "1m";
          client.dns-resolver = "tcp://1.1.1.1:53";
          conditions = ["[STATUS] == 200"];
          # alerts = [{type = "custom";}]; TODO
        };
      };
    };
    resources.externalsecrets.gatus.spec = {
      dataFrom = lib.toList {
        extract.key = "gatus.main.credentials.postgresql.acid.zalan.do";
        sourceRef.storeRef.kind = "ClusterSecretStore";
        sourceRef.storeRef.name = "kubernetes-storage";
      };
      target.name = "gatus";
      target.template.engineVersion = "v2";
      target.template.data.GATUS_DB_URI = "postgres://gatus:{{ .password }}@main.storage.svc.cluster.local:5432/gatus";
    };
  };
}
