{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (config.services) keycloak external-secrets postgres;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "keycloak.${domain}";
    image = {
      imageName = "bitnami/keycloak";
      imageDigest = "sha256:17aff522766636a7a315188481662b4bf4ce846731c06da261ba5b6a95fea70d";
      hash = "sha256-ZGLUzdTmiCkEP5yYVbpAO8lxzqbG0lIHkknKy3QI3bc=";
      finalImageTag = "26.2.5-debian-12-r3";
    };
  in {
    options.services.keycloak.enable = mkEnableOption "keycloak";
    config = mkIf keycloak.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.keycloak = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.keycloak-superadmin.length = 21;
      kubenix = {helm, ...}: {
        dotfiles.postgres.keycloak = {};
        kubernetes.helm.releases.keycloak = {
          namespace = "security";
          chart = helm.fetch {
            chartUrl = "oci://registry-1.docker.io/bitnamicharts/keycloak";
            chart = "keycloak";
            version = "24.7.4";
            sha256 = "sha256-HZIRUzTfgTktIo3okfqGmnJ71gezFunGlbRkgsc73BE=";
          };
          values = {
            auth.adminUser = "superadmin";
            auth.existingSecret = "keycloak";
            auth.passwordSecretKey = "superadmin";
            adminRealm = "admin";
            production = true;
            proxyHeaders = "xforwarded";
            extraEnvVarsCM = "keycloak";
            startupProbe.enabled = true;
            livnessProbe.initialDelaySeconds = 0;
            readinessProbe.initialDelaySeconds = 0;
            podAnnotations."reloader.stakater.com/auto" = "true";
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
                KC_HOSTNAME = hostname;
                KC_METRICS_ENABLED = "true";
                KC_HEALTH_ENABLED = "true";
                KC_HTTP_ENABLED = "true";
              };
              httproutes.keycloak.spec = {
                hostnames = [hostname];
                parentRefs = toList {
                  name = "external";
                  namespace = "kube-system";
                  sectionName = "https";
                };
                rules = toList {
                  backendRefs = toList {
                    name = "{{ template \"common.names.fullname\" . }}";
                    port = "http";
                  };
                };
              };
            }
            (mkIf (external-secrets.enable && postgres.enable) {
              externalsecrets.keycloak.spec = {
                secretStoreRef.name = "kubernetes-default";
                secretStoreRef.kind = "ClusterSecretStore";
                dataFrom = [{extract.key = "keycloak.main.credentials.postgresql.acid.zalan.do";}];
                target.template.data = {
                  db-password = "{{ .password }}";
                  superadmin = canivete.vals.sops.default "passwords/keycloak-superadmin";
                };
              };
            })
          ];
        };
      };
    };
  };
}
