{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain services;
    inherit (lib) toList mkIf mkEnableOption;
    hostname = "grafana.${domain}";
    url = "https" + "://${hostname}";
  in {
    options.services.grafana.enable = mkEnableOption "Grafana";
    config = mkIf services.grafana.enable {
      nixos = {pkgs, ...}: let
        inherit (pkgs.dockerTools) pullImage;
      in {
        canivete.kubernetes.images = {
          bats = pullImage {
            imageName = "docker.io/bats/bats";
            imageDigest = "sha256:f9e5272f8ccd9a21554e461c596b08553d052af78e509b8dffbd80ba89a34164";
            hash = "sha256-7lwKAAaviV6ooSFlA6N+6iKJw7gu3mEE33PX7qU38mM=";
            finalImageTag = "v1.4.1";
          };
          sidecar = pullImage {
            imageName = "quay.io/kiwigrid/k8s-sidecar";
            imageDigest = "sha256:b50fb46b5b3291fb82e85429781a27a5c36fe97f330908afe00652ee6c425459";
            hash = "sha256-uOOusYZNegkmZ22HSQpf2SqnkvSbdBRsWFWIOBmKMDo=";
            finalImageTag = "1.30.5";
          };
          grafana = pullImage {
            imageName = "docker.io/grafana/grafana";
            imageDigest = "sha256:b5b59bfc7561634c2d7b136c4543d702ebcc94a3da477f21ff26f89ffd4214fa";
            hash = "sha256-or+YBB5b/WKrpYMbXBl9Ugn60LLl+bpfaA3QENcYnig=";
            finalImageTag = "12.0.2";
          };
        };
      };
      opentofu = {
        dotfiles.secrets.grafana.value = "\${ random_password.grafana.result }";
        modules.resource.random_password.grafana.length = 21;
      };
      nixidy = {charts, ...}: {
        applications.grafana = {
          namespace = "monitoring";
          helm.releases.grafana = {
            chart = charts.grafana.grafana;
            values = {
              # TODO dashboards + providers + plugins
              admin.existingSecret = "grafana-admin";
              annotations."reloader.stakater.com/auto" = "true";
              envFromConfigMaps = [{name = "grafana";}];
              # Image owned by kubelet-csr-approver
              initChownData.image.tag = "latest";
              persistence.enabled = true;
              route.main = {
                enabled = true;
                hostnames = [hostname];
                parentRefs = toList {
                  name = "internal";
                  namespace = "kube-system";
                  sectionName = "https";
                };
              };
              serviceAccount.create = true;
              serviceAccount.autoMount = true;
              serviceMonitor.enabled = services.prometheus.enable;
              sidecar = {
                dashboards.enabled = true;
                dashboards.searchNamespace = "ALL";
                datasources.enabled = true;
                datasources.searchNamespace = "ALL";
              };
            };
          };
          resources = {
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
            # FIXME get these permission right
            # NOTE /var/lib/grafana contents are frequently only owned by grafana
            replicationSources.volsync--grafana--grafana-src.spec.restic.moverSecurityContext.fsGroup = 472;
          };
          dotfiles.volsync.pvcs.grafana = {
            title = "grafana";
            uid = 472;
            gid = 472;
          };
        };
      };
    };
  };
}
