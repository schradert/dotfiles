# https://github.com/grafana/grafana
{config, nix, ...}: let
  inherit (config.dotfiles) domain;
in {
  # TODO liveness probe failed
  perSystem.dotfiles.opentofu.passwords.grafana-admin-password.length = 21;
  perSystem.dotfiles.helm.grafana = {
    namespace = "observability";
    chart = {
      repo = "https://grafana.github.io/helm-charts";
      chart = "grafana";
      version = "8.5.1";
      sha256 = "rMWbpho4/HpV9ZyLoJboasXKDwdhbdiPzq+kdKUfCfc=";
    };
    values = {
      admin.existingSecret = "grafana-secret";
      annotations."reloader.stakater.com/auto" = "true";
      # dashboardProviders."dashboardproviders.yaml".apiVersion = 1;
      # dashboardProviders."dashboardproviders.yaml".providers = nix.toList {
      #   name = "default";
      #   type = "file";
      #   orgId = 1;
      #   editable = true;
      #   disableDeletion = false;
      #   folder = "";
      #   # TODO fix "path does not exist"
      #   options.path = "/var/lib/grafana/dashboards/default";
      # };
      # TODO find gnetId and revision
      # dashboards.default = {
      #   k8s-api-server.datasource = "Prometheus";
      #   k8s-global.datasource = "Prometheus";
      #   k8s-nodes.datasource = "Prometheus";
      #   k8s-namespaces.datasource = "Prometheus";
      #   k8s-pods.datasource = "Prometheus";
      #   k8s-volumes.datasource = "Prometheus";
      # };
      datasources."datasources.yaml".apiVersion = 1;
      envFromConfigMaps = [{name = "grafana-configmap";}];
      "grafana.ini".analytics = {
        check_for_updates = false;
        check_for_plugin_updates = false;
        reporting_enabled = false;
      };
      "grafana.ini"."auth.anonymous" = {
        enabled = true;
        org_id = 1;
        org_name = "Main Org.";
        org_role = "Viewer";
      };
      "grafana.ini".news.news_feed_enabled = false;
      imageRenderer.enabled = true;
      ingress = {
        enabled = true;
        ingressClassName = "internal";
        annotations."external-dns.alpha.kubernetes.io/target" = "internal.${domain}";
        hosts = ["grafana.${domain}"];
      };
      persistence.enabled = false;
      # TODO what other plugins do I want?
      plugins = [
        "grafana-clock-panel"
        "grafana-piechart-panel"
        "grafana-worldmap-panel"
        "natel-discrete-panel"
        "pr0ps-trackmap-panel"
        "vonage-status-panel"
      ];
      rbac.pspEnabled = true;
      resources.limits.memory = "512Mi";
      resources.requests.cpu = "50m";
      resources.requests.memory = "128Mi";
      serviceAccount.create = true;
      serviceAccount.autoMount = true;
      serviceMonitor.enabled = true;
      sidecar.dashboards = {
        enabled = true;
        searchNamespace = "ALL";
        label = "grafana_dashboard";
        folderAnnotation = "grafana_folder";
        provider.disableDelete = true;
        provider.foldersFromFilesStructure = true;
      };
      sidecar.datasources = {
        enabled = true;
        searchNamespace = "ALL";
        labelValue = "";
      };
      testFramework.enabled = false;
      topologySpreadConstraints = nix.toList {
        maxSkew = 1;
        topologyKey = "kubernetes.io/hostname";
        whenUnsatisfiable = "DoNotSchedule";
        labelSelector.matchLabels."app.kubernetes.io/name" = "grafana";
      };
    };
    resources.secrets.grafana-secret.stringData = {
      admin-user = "admin";
      admin-password = nix.vals.sops "default.yaml#/passwords/grafana-admin-password";
    };
    resources.configMaps.grafana-configmap.data = {
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
      GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS = nix.concatStringsSep "," ["natel-discrete-panel" "pr0ps-trackmap-panel" "panodata-map-panel"];
      GF_SECURITY_ANGULAR_SUPPORT_ENABLED = "true";
      GF_SECURITY_COOKIE_SAMESITE = "grafana";
      GF_SERVER_ROOT_URL = "https://grafana.${domain}";
    };
  };
}
