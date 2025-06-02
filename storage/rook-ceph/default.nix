{
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://charts.rook.io/release"];
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.rook-ceph.enable = lib.mkEnableOption "Rook-Ceph storage cluster";
    config = lib.mkIf config.services.rook-ceph.enable {
      opentofu.passwords = {
        rook-ceph-dashboard-password.length = 21;
        ceph-restic.length = 21;
      };
      nixos = {config, ...}: {
        boot.kernelModules = lib.mkIf config.canivete.kubernetes.enable ["nbd" "rbd"];
      };
      # FIXME back ceph storage up to backblaze
      kubenix = {canivete, ...}: let
        inherit (canivete.vals.sops) default;
      in {
        kubernetes.helm.releases.rook-ceph-cluster.extraResources = {
          secrets.jellyfin-volsync-b2.stringData = {
            RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/jellyfin";
            RESTIC_PASSWORD = default "passwords/b2-restic";
            B2_ACCOUNT_ID = default "backblaze/application_key";
            B2_ACCOUNT_KEY = default "backblaze/application_key_id";
          };
          replicationsources.jellyfin-b2.spec = {
            sourcePVC = "jellyfin";
            trigger.schedule = "0 * * * *";
            restic = {
              copyMethod = "Snapshot";
              repository = "jellyfin-volsync-b2";
              cacheStorageClassName = "openebs-hostpath";
              cacheAccessModes = ["ReadWriteOnce"];
              cacheCapacity = "10Gi";
              storageClassName = "ceph-block";
              volumeSnapshotClassName = "ceph-block";
              pruneIntervalDays = 7;
              retain.daily = 7;
            };
          };
        };
      };
    };
  };
}
