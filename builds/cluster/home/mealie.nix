{
  config,
  lib,
  ...
}: let
  inherit (config.canivete.meta) domain;
  subdomain = "mealie.${domain}";
in {
  # TODO fix backups
  # TODO AI features https://docs.mealie.io/documentation/getting-started/installation/open-ai/
  # TODO export logs into Loki
  # TODO home-assistant widget
  # TODO bulk import some recipes https://docs.mealie.io/documentation/community-guide/bulk-url-import/
  # TODO bookmarklet https://docs.mealie.io/documentation/community-guide/import-recipe-bookmarklet/
  # TODO nix built image
  perSystem.canivete = {
    nix2container.mealie = {};
    kubenix.helm.postgres.resources.postgresqls.main.spec = {
      users.mealie = ["createdb"];
      databases.mealie = "mealie";
    };
    kubenix.helm.mealie = {
      namespace = "home";
      values = {
        controllers.mealie.annotations."reloader.stakater.com/auto" = "true";
        controllers.mealie.containers.mealie = {
          image.repository = "ghcr.io/mealie-recipes/mealie";
          image.tag = "v1.12.0";
          envFrom = [
            {configMapRef.name = "mealie-configmap";}
            {secret = "mealie-secret";}
          ];
          probes.liveness.enabled = true;
          probes.readiness.enabled = true;
          probes.startup.enabled = true;
          resources.requests.cpu = "5m";
          resources.requests.memory = "256Mi";
          resources.limits.memory = "512Mi";
        };
        service.mealie.controller = "mealie";
        service.mealie.ports.http.port = 9000;
        ingress.mealie = {
          annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
          className = "external";
          hosts = lib.toList {
            host = subdomain;
            paths = lib.toList {
              path = "/";
              service.identifier = "mealie";
              service.port = "http";
            };
          };
        };
      };
      resources.configMaps.mealie-configmap.data = {
        ALLOW_SIGNUP = "false";
        BASE_URL = "https://${subdomain}";
        DB_ENGINE = "postgres";
        OIDC_AUTH_ENABLED = "true";
        OIDC_CONFIGURATION_URL = "https://keycloak.${domain}/realms/primary/.well-known/openid-configuration";
        OIDC_CLIENT_ID = "mealie";
        OIDC_USER_GROUP = "/family";
        OIDC_ADMIN_GROUP = "/admin";
        OIDC_AUTO_REDIRECT = "true";
        OIDC_REMEMBER_ME = "true";
        POSTGRES_SERVER = "main.storage.svc.cluster.local";
      };
      resources.externalsecrets.mealie.spec = {
        dataFrom = lib.toList {
          extract.key = "mealie.main.credentials.postgresql.acid.zalan.do";
          sourceRef.storeRef.kind = "ClusterSecretStore";
          sourceRef.storeRef.name = "kubernetes-storage";
        };
        target.name = "mealie-secret";
        target.template.engineVersion = "v2";
        target.template.data.POSTGRES_PASSWORD = "{{ .password }}";
      };
    };
  };
}
