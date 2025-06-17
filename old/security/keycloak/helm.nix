{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (config.services) keycloak external-secrets postgres;
    inherit (lib) mkEnableOption mkIf mkMerge;
    subdomain = "keycloak.${domain}";
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.keycloak.enable = mkEnableOption "keycloak";
    config = mkIf keycloak.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.keycloak = pkgs.dockerTools.pullImage image;};
      kubenix = {helm, ...}: {
        dotfiles.postgres.keycloak = {};
        opentofu.passwords.keycloak-superadmin.length = 21;
        kubernetes.helm.releases.keycloak = {
          namespace = "security";
          chart = helm.fetch {
            chartUrl = "oci://registry-1.docker.io/bitnamicharts/keycloak";
            chart = "keycloak";
            version = "22.2.5";
            sha256 = "t1bM5+uhcWmbrFQ5HfCTcxbCjiK624kIaaPrv6Q12ok=";
          };
          values = {
            auth.adminUser = "superadmin";
            auth.existingSecret = "keycloak";
            auth.passwordSecretKey = "keycloak-superadmin";
            adminRealm = "admin";
            production = true;
            proxyHeaders = "xforwarded";
            extraEnvVarsCM = "keycloak";
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
              existingSecret = "keycloak";
            };
          };
          extraResources = mkMerge [
            {
              configMaps.keycloak.data = {
                KC_DB = "postgres";
                KC_FEATURES = "hostname:v2";
                KC_HOSTNAME = subdomain;
                KC_METRICS_ENABLED = "true";
                KC_HEALTH_ENABLED = "true";
                KC_HTTP_ENABLED = "true";
              };
            }
            (mkIf (external-secrets.enable && postgres.enable) {
              externalsecrets.keycloak.spec = {
                secretStoreRef.name = "kubernetes-default";
                secretStoreRef.kind = "ClusterSecretStore";
                dataFrom = [{extract.key = "keycloak.main.credentials.postgresql.acid.zalan.do";}];
                target.template.data = {
                  db-password = "{{ .password }}";
                  keycloak-superadmin = canivete.vals.sops.default "passwords/keycloak-superadmin";
                };
              };
            })
          ];
        };
      };
    };
  };
}
