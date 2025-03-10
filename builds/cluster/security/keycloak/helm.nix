{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (config.canivete.meta) domain;
  subdomain = "keycloak.${domain}";
in {
  # TODO should I be considering newer and faster alternatives that offer support for newer features?
  # NOTE https://github.com/ory/kratos
  perSystem.canivete.kubenix.helm = {
    postgres.resources.postgresqls.main.spec = {
      users.keycloak = ["createdb"];
      databases.keycloak = "keycloak";
    };
    keycloak = {
      namespace = "security";
      resources.configMaps.keycloak-configmap.data = {
        KC_DB = "postgres";
        KC_FEATURES = "hostname:v2";
        KC_HOSTNAME = subdomain;
        KC_METRICS_ENABLED = "true";
        KC_HEALTH_ENABLED = "true";
        KC_HTTP_ENABLED = "true";
      };
      resources.externalsecrets.keycloak.spec = {
        dataFrom = lib.toList {
          extract.key = "keycloak.main.credentials.postgresql.acid.zalan.do";
          sourceRef.storeRef.kind = "ClusterSecretStore";
          sourceRef.storeRef.name = "kubernetes-storage";
        };
        target.name = "keycloak-secret";
        target.template.engineVersion = "v2";
        target.template.data = {
          db-password = "{{ .password }}";
          keycloak-superadmin = canivete.vals.sops "default.yaml#/passwords/keycloak-superadmin";
        };
      };
      chart = {
        chartUrl = "oci://registry-1.docker.io/bitnamicharts/keycloak";
        chart = "keycloak";
        version = "22.2.5";
        sha256 = "t1bM5+uhcWmbrFQ5HfCTcxbCjiK624kIaaPrv6Q12ok=";
      };
      values = {
        auth.adminUser = "superadmin";
        auth.existingSecret = "keycloak-secret";
        auth.passwordSecretKey = "keycloak-superadmin";
        adminRealm = "admin";
        production = true;
        proxyHeaders = "xforwarded";
        extraEnvVarsCM = "keycloak-configmap";
        startupProbe.enabled = true;
        livnessProbe.initialDelaySeconds = 0;
        readinessProbe.initialDelaySeconds = 0;
        podAnnotations."reloader.stakater.com/auto" = "true";
        ingress = {
          enabled = true;
          ingressClassName = "external";
          annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
          hostname = subdomain;
        };
        rbac.create = true;
        autoscaling.enabled = true;
        autoscaling.maxReplicas = 2;
        metrics = {
          enabled = true;
          serviceMonitor.enabled = true;
          serviceMonitor.namespace = "observability";
          prometheusRule.enabled = true;
          prometheusRule.namespace = "observability";
        };
        postgresql.enabled = false;
        externalDatabase = {
          host = "main.storage.svc.cluster.local";
          user = "keycloak";
          database = "keycloak";
          existingSecret = "keycloak-secret";
        };
      };
    };
  };
}
