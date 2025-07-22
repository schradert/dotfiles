{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "grafana.${config.domain}";
    url = "https" + "://${hostname}";
    images = {
      grafana = {
        imageName = "docker.io/grafana/grafana";
        imageDigest = "sha256:b5b59bfc7561634c2d7b136c4543d702ebcc94a3da477f21ff26f89ffd4214fa";
        hash = "sha256-or+YBB5b/WKrpYMbXBl9Ugn60LLl+bpfaA3QENcYnig=";
        finalImageTag = "12.0.2";
      };
      grafana-bats = {
        imageName = "docker.io/bats/bats";
        imageDigest = "sha256:8f4fa2cf9e259ae190560b5266e6e9154467cdb662404180f0f6fe81b929bb87";
        hash = "sha256-sCZd8Jj2g9EScz7Y+AmIwy9y4EaZsg+JLZu6CssdPO8=";
        finalImageTag = "1.12.0";
      };
      grafana-sidecar = {
        imageName = "quay.io/kiwigrid/k8s-sidecar";
        imageDigest = "sha256:318ca0734fe454e41584fe47421a07fd98eeef2721c5c0d4def2c4f0258e034b";
        hash = "sha256-ru9JOE/q4hick3m28mCYMTV58eyWqmG0+CY8wwh3LDE=";
        finalImageTag = "1.30.7";
      };
      grafana-busybox = {
        imageName = "busybox";
        imageDigest = "sha256:18ac7a6883a86416ade8178063c26deff577cd831445f5c5ac5c7a931cb60983";
        hash = "sha256-7hNq1iGGAsJsTTzI/UrLm7S4MKBaNPcLh3rFp2xqkP4=";
        finalImageTag = "1.37.0-glibc";
      };
    };
  in {
    options.services.grafana.enable = mkEnableOption "Grafana";
    config = mkIf services.grafana.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      opentofu = {
        dotfiles.secrets.grafana.value = "\${ random_password.grafana.result }";
        modules.resource.random_password.grafana.length = 21;
      };
      nixidy = {charts, ...}: {
        applications.grafana = {
          namespace = "monitoring";
          dotfiles.volsync.pvcs.grafana = {
            title = "grafana";
            uid = 472;
            gid = 472;
          };
          helm.releases.grafana = {
            chart = charts.grafana.grafana;
            values = mkMerge [
              {
                # TODO dashboards + providers + plugins
                envFromConfigMaps = [{name = "grafana";}];
                persistence.enabled = true;
                serviceAccount.create = true;
                serviceAccount.autoMount = true;
                sidecar = {
                  dashboards.enabled = true;
                  dashboards.searchNamespace = "ALL";
                  datasources.enabled = true;
                  datasources.searchNamespace = "ALL";
                };

                image = with images.grafana; {
                  repository = imageName;
                  tag = finalImageTag;
                  pullPolicy = "Never";
                };
                testFramework.image = with images.grafana-bats; {
                  repository = imageName;
                  tag = finalImageTag;
                  pullPolicy = "Never";
                };
                initChownData.image = with images.grafana-busybox; {
                  repository = imageName;
                  tag = finalImageTag;
                  pullPolicy = "Never";
                };
                sidecar.imagePullPolicy = "Never";
                sidecar.image = with images.grafana-sidecar; {
                  repository = imageName;
                  tag = finalImageTag;
                };
              }
              (mkIf services.external-secrets.enable {admin.existingSecret = "grafana-admin";})
              (mkIf services.reloader.enable {annotations."reloader.stakater.com/auto" = "true";})
              (mkIf services.prometheus.enable {serviceMonitor.enabled = true;})
              (mkIf services.cilium.enable {
                route.main = {
                  enabled = true;
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
            ];
          };
          resources = mkMerge [
            {
              configMaps.grafana.data = {
                GF_ANALYTICS_CHECK_FOR_UPDATES = "false";
                GF_ANALYTICS_CHECK_FOR_PLUGIN_UPDATES = "false";
                GF_ANALYTICS_REPORTING_ENABLED = "false";
                GF_AUTH_ANONYMOUS_ENABLED = "false";
                GF_AUTH_BASIC_ENABLED = "false";
                GF_DATE_FORMATS_USE_BROWSER_LOCALE = "true";
                GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH = "/tmp/dashboards/home.json";
                GF_EXPLORE_ENABLED = "true";
                GF_FEATURE_TOGGLES_ENABLE = "publicDashboards";
                GF_LOG_MODE = "console";
                GF_NEWS_NEWS_FEED_ENABLED = "false";
                GF_SECURITY_COOKIE_SAMESITE = "grafana";
                GF_SERVER_ROOT_URL = url;
              };
            }
            (mkIf services.external-secrets.enable {
              externalSecrets.grafana-admin.spec = {
                secretStoreRef.name = "bitwarden";
                secretStoreRef.kind = "ClusterSecretStore";
                data = toList {
                  secretKey = "password";
                  remoteRef.key = "grafana";
                };
                target.template.data = {
                  admin-user = "admin";
                  admin-password = "{{ .password }}";
                };
              };
            })
            (mkIf services.volsync.enable {
              # FIXME get these permission right
              # NOTE /var/lib/grafana contents are frequently only owned by grafana
              replicationSources.volsync--grafana--grafana-src.spec.restic.moverSecurityContext.fsGroup = 472;
            })
          ];
        };
      };
    };
  };
}
