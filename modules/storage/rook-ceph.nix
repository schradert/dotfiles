{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkDefault mkEnableOption mkForce mkIf mkMerge toList;
    subdomain = "rook.${config.domain}";
    images.rook = {
      imageName = "ghcr.io/rook/ceph";
      imageDigest = "sha256:4ce4a273490031d8d3512101c78998d6f0e68191dc1e33df868ccb7163e468f6";
      hash = "sha256-a+COWM3wsZ8doqLV1nJwaXELPPoKCzjm+TPnHNBmB60=";
      finalImageTag = "v1.17.6";
    };
    images.ceph = {
      imageName = "quay.io/ceph/ceph";
      imageDigest = "sha256:8214ebff6133ac27d20659038df6962dbf9d77da21c9438a296b2e2059a56af6";
      hash = "sha256-el/MstpaPWTIV4nii17PXbek6IIoqfQxgbyYGGybGhQ=";
      finalImageTag = "v19.2.2";
    };
  in {
    options.services.rook-ceph.enable = mkEnableOption "Rook-Ceph storage cluster";
    config = mkIf services.rook-ceph.enable {
      nixos = {
        config,
        pkgs,
        ...
      }: {
        boot.kernelModules = mkIf config.canivete.kubernetes.enable ["nbd" "rbd"];
        canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;
      };
      opentofu = {
        passwords.rook-ceph.length = 21;
        dotfiles.secrets.rook-ceph.value = "\${ random_password.rook-ceph.result }";
      };
      nixidy = {lib, ...}: {
        applications.rook-ceph = {
          namespace = "storage";
          helm.releases.rook-ceph-operator = {
            chart = lib.helm.downloadHelmChart {
              chart = "rook-ceph";
              version = "v1.17.6";
              repo = "oci://ghcr.io/rook";
              chartHash = "sha256-tZWwtY5O671tQMktyLS6lx5xpABzRfD6aK1UGpPY2wk=";
            };
            values = mkMerge [
              {
                csi = {
                  cephFSKernelMountOptions = "ms_mode=prefer-crc";
                  enableCephfsDriver = false;
                  enableCephfsSnapshotter = false;
                };
                enableDiscoveryDaemon = true;
                image.repository = "ghcr.io/rook/ceph";
                image.pullPolicy = "Never";
                # TODO do I need this? actually unchangeable?
                # resources = {
                #   requests.memory = "128Mi";
                #   requests.cpu = "100m";
                #   limits = {};
                # };
              }
              {
                # Mount Nix store
                # TODO is this still needed?
                csi = {
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
                };
              }
              (mkIf services.prometheus.enable {
                csi.serviceMonitor.enabled = true;
                monitoring.enabled = true;
              })
            ];
          };
          helm.releases.rook-ceph-cluster = {
            chart = lib.helm.downloadHelmChart {
              chart = "rook-ceph-cluster";
              version = "v1.17.6";
              repo = "oci://ghcr.io/rook";
              chartHash = "sha256-E2d21wQM7JGDGNGaGhqlYsSERpK8fU/S14+miS2LDcE=";
            };
            values = mkMerge [
              {
                operatorNamespace = "storage";
                cephVersion.image = with images.ceph; "${imageName}:${finalImageTag}";
                cephClusterSpec = {
                  cephConfig.global = {
                    bdev_enable_discard = "true";
                    bdev_async_discard_threads = "1";
                    osd_class_update_on_start = "false";
                    device_failure_prediction_mode = "local";
                  };
                  # TODO useful?
                  # cephConfig.mgr = {
                  #   "mgr/dashboard/standby_behaviour" = "error";
                  #   "mgr/dashboard/standby_error_status_code = "503";
                  #   "mgr/dashboard/redirect_resolve_ip_addr" = "true";
                  #   "mgr/crash/warn_recent_interval" = "7200";
                  # };
                  cleanupPolicy.wipeDevicesFromOtherClusters = true;
                  csi.readAffinity.enabled = true;
                  dashboard.urlPrefix = "/";
                  dashboard.ssl = false;
                  mgr.modules = let
                    enable = name: {
                      inherit name;
                      enabled = true;
                    };
                  in [
                    (enable "diskprediction_local")
                    (enable "insights")
                    (enable "pg_autoscaler")
                    (enable "rook")
                  ];
                  network.provider = "host";
                  network.connections.requireMsgr2 = true;
                  storage.useAllNodes = false;
                  storage.useAllDevices = false;
                  storage.nodes = mkDefault [];
                };
                cephFileSystems = [];
                cephBlockPoolsVolumeSnapshotClass.enabled = true;
              }
              (mkIf services.prometheus.enable {
                monitoring.enabled = true;
                monitoring.createPrometheusRules = true;
                cephClusterSpec.dashboard.prometheusEndpoint = "http" + "://prometheus-operated.monitoring.svc.cluster.local:9090";
              })
            ];
          };
          resources = mkMerge [
            {
              storageClasses.ceph-bucket.parameters.region = mkForce "us-west-1";
              storageClasses.ceph-block = {
                # TODO should I prevent this from being the default storageclass?
                mountOptions = ["discard"];
                parameters.compression_mode = "aggressive";
                parameters.compression_algorithm = "zstd";
                parameters.imageFeatures = mkForce (builtins.concatStringsSep "," [
                  "layering"
                  "fast-diff"
                  "object-map"
                  "deep-flatten"
                  "exclusive-lock"
                ]);
              };
            }
            (mkIf services.cilium.enable {
              httpRoutes.rook-ceph-dashboard.spec = {
                hostnames = [subdomain];
                parentRefs = toList {
                  name = "internal";
                  namespace = "kube-system";
                  sectionName = "https";
                };
                rules = toList {
                  backendRefs = toList {
                    name = "rook-ceph-mgr-dashboard";
                    port = 7000;
                  };
                };
              };
              httpRoutes.rook-ceph-rados.spec = {
                hostnames = ["rados.${config.domain}"];
                parentRefs = toList {
                  name = "internal";
                  namespace = "kube-system";
                  sectionName = "https";
                };
                rules = toList {
                  backendRefs = toList {
                    # TODO get actual service name
                    name = "rook-ceph-radosgw";
                    port = 80;
                  };
                };
              };
            })
            (mkIf services.external-secrets.enable {
              # This secret name is expected by rook-ceph
              externalSecrets.rook-ceph-dashboard-password.spec.data = toList {
                secretKey = "password";
                remoteRef.key = "rook-ceph";
                sourceRef.storeRef.name = "bitwarden";
                sourceRef.storeRef.kind = "ClusterSecretStore";
              };
            })
          ];
        };
      };
    };
  };
}
