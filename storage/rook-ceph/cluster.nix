{
  # TODO why does the CephBlockPool sit in Failed phase? signal interrupt for creation
  # NOTE https://github.com/rook/rook/blob/master/Documentation/Helm-Charts/ceph-cluster-chart.md
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) toList mkIf mkOption types;
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
    config = mkIf config.services.rook-ceph.enable {
      kubenix = {helm, ...}: {
        # Kubenix bug means fields outside of expected spec won't register, so we define them here
        # NOTE https://github.com/hall/kubenix/issues/34
        options.kubernetes.api.resources."snapshot.storage.k8s.io".v1.VolumeSnapshotClass = mkOption {
          type = attrsOf (submodule {
            options.deletionPolicy = mkOption {type = str;};
            options.driver = mkOption {type = str;};
            options.parameters = mkOption {type = attrsOf str;};
          });
        };
        config.kubernetes.helm.releases.rook-ceph-cluster = {
          namespace = "storage";
          chart = helm.fetch {
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
    };
  };
}
