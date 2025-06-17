{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) toList mkIf mkOption types;
    inherit (types) attrsOf submodule str;
  in {
    config = mkIf config.services.rook-ceph.enable {
      kubenix = {
        canivete,
        helm,
        ...
      }: {
        # Kubenix bug means fields outside of expected spec won't register, so we define them here
        # NOTE https://github.com/hall/kubenix/issues/34
        options.kubernetes.api.resources."snapshot.storage.k8s.io".v1.VolumeSnapshotClass = mkOption {
          type = attrsOf (submodule {
            options.deletionPolicy = mkOption {type = str;};
            options.driver = mkOption {type = str;};
            options.parameters = mkOption {type = attrsOf str;};
          });
        };
        config.kubernetes.helm.releases.rook-ceph = {
          namespace = "storage";
          chart = helm.fetch {
            repo = "https://charts.rook.io/release";
            chart = "rook-ceph";
            version = "1.15.0";
            sha256 = "VnfWg3sftim8hXA5tgd4zxU0hFWTH7gSD+vo/A6PLsk=";
          };
          extraResources.secrets.rook-ceph-dashboard-password.data.password = canivete.toBase64 (canivete.vals.sops.default "passwords/rook-ceph-dashboard-password");
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
        };
      };
    };
  };
}
