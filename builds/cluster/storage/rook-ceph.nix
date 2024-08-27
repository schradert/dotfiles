# https://github.com/rook/rook/blob/master/Documentation/Helm-Charts/ceph-cluster-chart.md
{
  config,
  nix,
  ...
}:
with nix; let
  subdomain = "rook.${config.dotfiles.domain}";
in {
  # Kubenix bug means fields outside of expected spec won't register, so we define them here
  # NOTE https://github.com/hall/kubenix/issues/34
  perSystem.canivete.kubenix.clusters.prod.modules.rook-ceph-patch = {
    options.kubernetes.api.resources."snapshot.storage.k8s.io".v1.VolumeSnapshotClass = mkOption {
      type = attrsOf (submodule {
        options.deletionPolicy = mkOption {type = str;};
        options.driver = mkOption {type = str;};
        options.parameters = mkOption {type = attrsOf str;};
      });
    };
    # NOTE rook-ceph-cluster creates some of the same resources so we force any collisions here
    # TODO why couldn't I do this with helm overrides!!!
    config.kubernetes.api.resources = {
      core.v1.ServiceAccount = {
        rook-ceph-default.metadata.labels."canivete/chart" = mkForce "rook-ceph";
        rook-ceph-purge-osd.metadata.labels."canivete/chart" = mkForce "rook-ceph";
        rook-ceph-cmd-reporter = {
          metadata.labels."canivete/chart" = mkForce "rook-ceph";
          metadata.labels."helm.sh/chart" = mkForce "rook-ceph-v1.15.0";
        };
        rook-ceph-mgr = {
          metadata.labels."canivete/chart" = mkForce "rook-ceph";
          metadata.labels."helm.sh/chart" = mkForce "rook-ceph-v1.15.0";
        };
        rook-ceph-osd = {
          metadata.labels."canivete/chart" = mkForce "rook-ceph";
          metadata.labels."helm.sh/chart" = mkForce "rook-ceph-v1.15.0";
        };
        rook-ceph-rgw = {
          metadata.labels."canivete/chart" = mkForce "rook-ceph";
          metadata.labels."helm.sh/chart" = mkForce "rook-ceph-v1.15.0";
        };
      };
      "rbac.authorization.k8s.io".v1.Role = {
        rook-ceph-osd.metadata.labels."canivete/chart" = mkForce "rook-ceph";
        rook-ceph-purge-osd.metadata.labels."canivete/chart" = mkForce "rook-ceph";
        rook-ceph-cmd-reporter.metadata.labels."canivete/chart" = mkForce "rook-ceph";
        rook-ceph-mgr.metadata.labels."canivete/chart" = mkForce "rook-ceph";
        rook-ceph-monitoring.metadata.labels."canivete/chart" = mkForce "rook-ceph";
        rook-ceph-monitoring-mgr.metadata.labels."canivete/chart" = mkForce "rook-ceph";
      };
      "rbac.authorization.k8s.io".v1.RoleBinding = {
        rook-ceph-osd.metadata.labels."canivete/chart" = mkForce "rook-ceph";
        rook-ceph-cluster-mgmt.metadata.labels."canivete/chart" = mkForce "rook-ceph";
      };
    };
  };
  perSystem.dotfiles.opentofu.passwords.rook-ceph-dashboard-password.length = 21;
  perSystem.dotfiles.helm = {
    rook-ceph = {
      namespace = "storage";
      chart = {
        repo = "https://charts.rook.io/release";
        chart = "rook-ceph";
        version = "1.15.0";
        sha256 = "VnfWg3sftim8hXA5tgd4zxU0hFWTH7gSD+vo/A6PLsk=";
      };
      values.csi = {
        cephFSKernelMountOptions = "ms_mode=prefer-crc";
        enableliveness = true;
        serviceMonitor.enabled = true;
      };
      values.monitoring.enabled = true;
      resources.secrets.rook-ceph-dashboard-password.stringData.password = "ref+envsubst://ROOK_CEPH_DASHBOARD_PASSWORD";
    };
    rook-ceph-cluster = {
      namespace = "storage";
      chart = {
        repo = "https://charts.rook.io/release";
        chart = "rook-ceph-cluster";
        version = "1.15.0";
        sha256 = "obXkbYfC0pjeJU+0uroBi1unCrGAeZBqHSMpOSQVPfo=";
      };
      values = {
        operatorNamespace = "storage";
        monitoring.enabled = true;
        monitoring.createPrometheusRules = true;
        ingress.dashboard = {
          ingressClassName = "internal";
          host.name = subdomain;
          host.path = "/";
        };
        toolbox.enabled = true;
        cephClusterSpec = {
          dashboard.urlPrefix = "/";
          dashboard.ssl = false;
          # TODO do I need this? I wasn't specified in the Helm chart
          # dashboard.prometheusEndpoint = "http://prometheus-operated.observability.svc.cluster.local:9090";
          mgr.modules = toList {
            name = "pg_autoscaler";
            enabled = true;
          };
          network.provider = "host";
          network.connections.requireMsgr2 = true;
          storage.config.osdsPerDevice = "1";
        };
        cephBlockPoolsVolumeSnapshotClass.enabled = true;
        cephFileSystemVolumeSnapshotClass.enabled = true;
        cephFileSystemVolumeSnapshotClass.isDefault = false;
        cephObjectStores = [];
      };
    };
  };
}
