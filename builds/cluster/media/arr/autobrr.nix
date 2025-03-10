{
  config,
  lib,
  ...
}: let
  subdomain = "autobrr.${config.canivete.meta.domain}";
  port = 7878;
in {
  # [ ] [autobrr](https://github.com/autobrr/autobrr)
  perSystem.canivete.opentofu.workspaces.deploy.modules.autobrr.canivete.passwords = {
    autobrr-session-secret.length = 21;
    autobrr-postgres-password.length = 21;
  };
  perSystem.canivete.kubenix.helm.autobrr = {
    namespace = "media";
    values = {
      controllers.autobrr.containers.autobrr = {
        image.repository = "ghcr.io/autobrr/autobrr";
        image.tag = "v1.44.0@sha256:313e146f0d64f489ffb0bc10c8c2e1bfa072c20cb220b7317f2b1eeda712f49b";
        envFrom = [
          {secret = "autobrr";}
          {configMapRef.name = "autobrr";}
        ];
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
      };
      service.autobrr.controller = "autobrr";
      service.autobrr.ports.http.port = port;
      ingress.autobrr.className = "internal";
      ingress.autobrr.hosts = lib.toList {
        host = subdomain;
        paths = lib.toList {
          path = "/";
          service.identifier = "autobrr";
          service.port = "http";
        };
      };
      secrets.autobrr.enabled = true;
      secrets.autobrr.stringData = {
        AUTOBRR__POSTGRES_PASS = "ref+envsubst://AUTOBRR_POSTGRES_PASSWORD";
        AUTOBRR__SESSION_SECRET = "ref+envsubst://AUTOBRR_SESSION_SECRET";
      };
      configMaps.autobrr.enabled = true;
      configMaps.autobrr.data = {
        AUTOBRR__DATABASE_TYPE = "postgres";
        AUTOBRR__POSTGRES_HOST = "postgres-autobrr.arr.svc.cluster.local";
        AUTOBRR__POSTGRES_PORT = "5432";
        AUTOBRR__POSTGRES_DATABASE = "autobrr";
        AUTOBRR__POSTGRES_USER = "autobrr";
        AUTOBRR__CHECK_FOR_UPDATES = "false";
        AUTOBRR__HOST = "0.0.0.0";
        AUTOBRR__PORT = toString port;
        AUTOBRR__LOG_LEVEL = "INFO";
      };
    };
    resources.postgresqls.autobrr.spec = {
      teamId = "acid";
      volume.size = "1Gi";
      numberOfInstances = 1;
      users.autobrr = ["superuser" "createdb"];
      databases.autobrr = "autobrr";
      postgresql.version = "16";
    };
  };
}
