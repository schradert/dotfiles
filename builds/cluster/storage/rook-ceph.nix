# https://github.com/rook/rook/blob/master/Documentation/Helm-Charts/ceph-cluster-chart.md
# TODO why does the CephBlockPool sit in Failed phase? signal interrupt for creation
{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (lib) toList mkOption types mkForce;
  inherit (types) attrsOf submodule str;
  inherit (config.canivete.meta) domain;
  subdomain = "rook.${domain}";
  placement = nodes: label: let
    topologyKey = "kubernetes.io/hostname";
    labelSelector.matchExpressions = toList {
      key = "app";
      operator = "In";
      values = [label];
    };
  in {
    nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = toList {
      matchExpressions = toList {
        key = topologyKey;
        operator = "In";
        values = nodes;
      };
    };
    podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution = toList {inherit topologyKey labelSelector;};
    topologySpreadConstraints = toList {
      inherit topologyKey labelSelector;
      maxSkew = 1;
      whenUnsatisfiable = "DoNotSchedule";
    };
  };
in {
  canivete.deploy.nixos.modules.rook-ceph = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.canivete.kubernetes.enable {
      boot.kernelModules = ["nbd" "rbd"];
    };
  };
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://charts.rook.io/release"];
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
    #    config.kubernetes.api.resources = {
    #      core.v1.ServiceAccount = {
    #        rook-ceph-default.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #        rook-ceph-purge-osd.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #        rook-ceph-cmd-reporter = {
    #          metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #          metadata.labels."helm.sh/chart" = mkForce "rook-ceph-v1.15.0";
    #        };
    #        rook-ceph-mgr = {
    #          metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #          metadata.labels."helm.sh/chart" = mkForce "rook-ceph-v1.15.0";
    #        };
    #        rook-ceph-osd = {
    #          metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #          metadata.labels."helm.sh/chart" = mkForce "rook-ceph-v1.15.0";
    #        };
    #        rook-ceph-rgw = {
    #          metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #          metadata.labels."helm.sh/chart" = mkForce "rook-ceph-v1.15.0";
    #        };
    #      };
    #      "rbac.authorization.k8s.io".v1.Role = {
    #        rook-ceph-osd.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #        rook-ceph-purge-osd.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #        rook-ceph-cmd-reporter.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #        rook-ceph-mgr.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #        rook-ceph-monitoring.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #        rook-ceph-monitoring-mgr.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #      };
    #      "rbac.authorization.k8s.io".v1.RoleBinding = {
    #        rook-ceph-osd.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #        rook-ceph-cluster-mgmt.metadata.labels."canivete/chart" = mkForce "rook-ceph";
    #      };
    #    };
  };
  perSystem.canivete.opentofu.workspaces.deploy.modules.rook-ceph.canivete.passwords.rook-ceph-dashboard-password.length = 21;
  perSystem.canivete.kubenix.helm = {
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
        csiRBDPluginVolume = [
          {
            name = "lib-modules";
            hostPath.path = "/run/current-system/kernel-modules/lib/modules/";
          }
          {
            name = "host-nix";
            hostPath.path = "/nix";
          }
        ];
        csiRBDPluginVolumeMount = toList {
          name = "host-nix";
          mountPath = "/nix";
          readOnly = true;
        };
        csiCephFSPluginVolume = [
          {
            name = "lib-modules";
            hostPath.path = "/run/current-system/kernel-modules/lib/modules/";
          }
          {
            name = "host-nix";
            hostPath.path = "/nix";
          }
        ];
        csiCephFSPluginVolumeMount = toList {
          name = "host-nix";
          mountPath = "/nix";
          readOnly = true;
        };
        enableliveness = true;
        serviceMonitor.enabled = true;
      };
      values.monitoring.enabled = true;
      resources.secrets.rook-ceph-dashboard-password.stringData.password = canivete.vals.sops "default.yaml#/passwords/rook-ceph-dashboard-password";
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
          ingressClassName = "external";
          annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
          annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
          annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
          host.name = subdomain;
          host.path = "/";
        };
        toolbox.enabled = true;
        configOverride = ''
          [mgr]
          mgr/dashboard/standby_behaviour = "error"
          mgr/dashboard/standby_error_status_code = 503
        '';
        # mgr/dashboard/redirect_resolve_ip_addr = true
        cephBlockPoolsVolumeSnapshotClass.enabled = true;
        cephClusterSpec = {
          removeOSDsIfOutAndSafeToRemove = true;
          crashCollector.disable = false;
          dashboard = {
            enabled = true;
            ssl = false;
            urlPrefix = "/";
            prometheusEndpoint = "http://prometheus-operated.observability.svc.cluster.local:9090";
          };
          mgr.modules = [
            {
              name = "pg_autoscaler";
              enabled = true;
            }
            {
              name = "rook";
              enabled = true;
            }
          ];
          network.hostNetwork = false;
          network.provider = "host";
          network.connections.requireMsgr2 = true;
          placement.osd = placement ["sirver" "octopus" "bonobo" "chinchilla" "dingo"] "rook-ceph-osd";
          storage.storageClassDeviceSets = [
            {
              count = 4;
              name = "rook-ceph-osd-lvm-big";
              placement = placement ["sirver" "octopus"] "rook-ceph-osd-prepare";
              resources.limits.memory = "4Gi";
              resources.requests.cpu = "500m";
              resources.requests.memory = "4Gi";
              volumeClaimTemplates = toList {
                metadata.name = "data";
                spec = {
                  accessModes = ["ReadWriteOnce"];
                  resources.requests.storage = "93Gi";
                  storageClassName = "openebs-lvm";
                  volumeMode = "Block";
                };
              };
            }
            {
              count = 3;
              name = "rook-ceph-osd-lvm-small";
              placement = placement ["bonobo" "chinchilla" "dingo"] "rook-ceph-osd-prepare";
              resources.limits.memory = "4Gi";
              resources.requests.cpu = "500m";
              resources.requests.memory = "4Gi";
              volumeClaimTemplates = toList {
                metadata.name = "data";
                spec = {
                  accessModes = ["ReadWriteOnce"];
                  resources.requests.storage = "46Gi";
                  storageClassName = "openebs-lvm";
                  volumeMode = "Block";
                };
              };
            }
          ];
        };
        cephFileSystemVolumeSnapshotClass.enabled = true;
        cephFileSystemVolumeSnapshotClass.isDefault = false;
        cephObjectStores = toList {
          name = "ceph-objectstore";
          spec = {
            metadataPool.failureDomain = "host";
            metadataPool.replicated.size = 3;
            dataPool.failureDomain = "host";
            dataPool.erasureCoded.dataChunks = 2;
            dataPool.erasureCoded.codingChunks = 1;
            preservePoolsOnDelete = true;
            gateway = {
              hostNetwork = false;
              port = 80;
              resources.requests.cpu = "100m";
              resources.requests.memory = "1Gi";
              resources.limits.memory = "2Gi";
              instances = 1;
              priorityClassName = "system-cluster-critical";
            };
            healthCheck.bucket.interval = "60s";
          };
          storageClass = {
            enabled = true;
            name = "ceph-bucket";
            reclaimPolicy = "Delete";
            volumeBindingMode = "Immediate";
            parameters.region = "us-west-1";
          };
          ingress = {
            enabled = true;
            ingressClassName = "internal";
            host.name = "radosgw.${domain}";
            host.path = "/";
            annotations."external-dns.alpha.kubernetes.io/target" = "internal.${domain}";
          };
        };
      };
    };
  };
}
