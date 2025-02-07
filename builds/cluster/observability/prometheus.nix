{config, ...}: let
  inherit (config.dotfiles) domain;
in {
  # TODO figure out prometheus in nix
  # TODO make sure to get all the endpoints like sonarr, radarr, lidarr
  # TODO alertmanager
  # [ ] [prometheus-node-exporter](https://github.com/prometheus/node_exporter)
  # [ ] [prometheus-smartctl-exporter](https://github.com/prometheus-community/smartctl_exporter)
  # [ ] [prometheus-snmp-exporter](https://github.com/prometheus/snmp_exporter)
  perSystem.dotfiles.helm = {
    prometheus = {
      namespace = "observability";
      chart = {
        repo = "https://prometheus-community.github.io/helm-charts";
        chart = "kube-prometheus-stack";
        version = "61.7.0";
        sha256 = "U5BvJnBbgGe1KFS2nFd8Bc3v+sqjR1CWQDCzDlq6ebk=";
      };
      values = rec {
        # crds.enabled = false;
        crds.enabled = true;
        cleanPrometheusOperatorObjectNames = true;
        alertmanager.ingress = {
          enabled = true;
          annotations."external-dns.alpha.kubernetes.io/target" = "internal.${domain}";
          ingressClassName = "internal";
          hosts = ["alertmanager.${domain}"];
          pathType = "Prefix";
        };
        alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec = {
          storageClassName = "openebs-hostpath";
          resources.requests.storage = "1Gi";
        };
        kubeApiServer.serviceMonitor.selector.k8s-app = "kube-apiserver";
        kubeScheduler.service.selector.k8s-app = "kube-scheduler";
        kubeControllerManager.service.selector.k8s-app = "kube-controller-manager";
        kubeEtcd = kubeControllerManager;
        kubeProxy.enabled = false;
        prometheus.ingress = alertmanager.ingress // {hosts = ["alertmanager.${domain}"];};
        prometheus.prometheusSpec = {
          ruleSelectorNilUsesHelmValues = false;
          serviceMonitorSelectorNilUsesHelmValues = false;
          podMonitorSelectorNilUsesHelmValues = false;
          probeSelectorNilUsesHelmValues = false;
          scrapeConfigSelectorNilUsesHelmValues = false;
          enableAdminAPI = true;
          walCompression = true;
          scrapeInterval = "1m";  # Must match interval in Grafana Helm chart
          enableFeatures = ["auto-gomemlimit" "auto-gomaxprocs" "memory-snapshot-on-shutdown" "new-service-discovery-manager"];
          replicas = 1;
          retention = "14d";
          retentionSize = "50GB";
          resources.requests.cpu = "100m";
          resources.limits.memory = "1500Mi";
          storageSpec.volumeClaimTemplate.spec = {
            storageClassName = "openebs-hostpath";
            resources.requests.storage = "75Gi";
          };
        };
        kube-state-metrics.prometheus.monitor.enabled = true;
        grafana.enabled = false;
        grafana.forceDeployDashboards = true;
        grafana.sidecar.dashboards.annotations.grafana_folder = "kubernetes";
      };
    };
  };
}
