{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (canivete) vals;
  inherit (config.dotfiles) domain;
  subdomain = "plex.${domain}";
in {
  # TODO request button on plex!
  # TODO plugins? Audnexus.bundle and Absolute-Series-Scanner
  # TODO nodeAffinity for bonobo, chinchilla, dingo, and axolotl
  # https://github.com/Kometa-Team/ImageMaid
  # https://www.reddit.com/r/PleX/comments/143cviv/plex_image_cleanup_clean_up_your_metadata_with/
  # [ ] [plex-auto-languages](https://github.com/bjw-s/home-ops/blob/main/kubernetes/main/apps/media/plex/plex-auto-languages/helmrelease.yaml)
  # https://github.com/RemiRigal/Plex-Auto-Languages
  # https://github.com/blacktwin/JBOPS
  perSystem.dotfiles.helm.plex = {
    namespace = "media";
    values = {
      controllers.plex = {
        annotations."reloader.stakater.com/auto" = "true";
        # TODO selector for Intel Quick Sync Video
        pod.nodeSelector."kubernetes.io/hostname" = "octopus";
        # TODO nix image
        containers.plex = {
          image.repository = "ghcr.io/onedr0p/plex";
          image.tag = "1.41.0.8992-8463ad060@sha256:d4c31adff5f2ed92152de7c2fb73464e71bea72c28fc7b4ebe74eefab2d9d048";
          probes.liveness.enabled = true;
          probes.readiness.enabled = true;
          probes.startup = {
            enabled = true;
            spec.failureThreshold = 30;
            spec.periodSeconds = 5;
          };
          # TODO how much space do I need?
          resources.requests = {
            cpu = "100m";
            # TODO specify device with Intel Quick Sync Video
            memory = "10Gi";
          };
          resources.limits.memory = "10Gi";
        };
      };
      service.plex = {
        controller = "plex";
        type = "LoadBalancer";
        annotations."lbipam.cilium.io/ips" = "192.168.50.203";
        ports.http.port = 32400;
      };
      ingress.plex = {
        annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
        annotations."nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS";
        className = "external";
        hosts = lib.toList {
          host = subdomain;
          paths = lib.toList {
            path = "/";
            service.identifier = "plex";
            service.port = "http";
          };
        };
      };
      persistence = {
        data.existingClaim = "plex-data";
        data.advancedMounts.plex.plex = [{path = "/config";}];
        config.existingClaim = "plex-config";
        config.advancedMounts.plex.plex = [{path = "/config";}];
        cache.existingClaim = "plex-cache";
        cache.advancedMounts.plex.plex = [{path = "/config/Library/Application Support/Plex Media Server/Cache";}];
        logs.type = "emptyDir";
        logs.advancedMounts.plex.plex = [{path = "/config/Library/Application Support/Plex Media Server/Logs";}];
        transcode.type = "emptyDir";
        transcode.advancedMounts.plex.plex = [{path = "/transcode";}];
      };
    };

    # Cache
    resources.persistentVolumeClaims.plex-cache.spec = {
      accessModes = ["ReadWriteOnce"];
      resources.requests.storage = "10Gi";
      storageClassName = "ceph-block";
    };

    # Data
    resources.objectbucketclaims.plex-data-bucket.spec = {
      bucketName = "plex-data";
      storageClassName = "ceph-bucket";
    };
    resources.externalsecrets.plex-data-ceph.spec = {
      dataFrom = [
        {
          extract.key = "plex-data-bucket";
          sourceRef.storeRef.kind = "ClusterSecretStore";
          sourceRef.storeRef.name = "kubernetes-media";
        }
        {
          extract.key = "volsync-restic-passwords";
          sourceRef.storeRef.kind = "ClusterSecretStore";
          sourceRef.storeRef.name = "kubernetes-kube-system";
        }
      ];
      target.name = "plex-data-volsync-ceph";
      target.template.engineVersion = "v2";
      target.template.data = {
        # TODO how can I generate the endpoint from configMaps?
        RESTIC_REPOSITORY = "s3:http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80/plex/data";
        RESTIC_PASSWORD = "{{ .CEPH_RESTIC }}";
        AWS_ACCESS_KEY_ID = "{{ .AWS_ACCESS_KEY_ID }}";
        AWS_SECRET_ACCESS_KEY = "{{ .AWS_SECRET_ACCESS_KEY }}";
      };
    };
    # TODO restic repository and password? secret with block storage
    resources.replicationdestinations.plex-data-ceph.spec = {
      trigger.manual = "1";
      restic = {
        copyMethod = "Snapshot";
        repository = "plex-data-volsync-ceph";
        cacheStorageClassName = "openebs-hostpath";
        cacheAccessModes = ["ReadWriteOnce"];
        cacheCapacity = "10Gi";
        storageClassName = "ceph-filesystem";
        volumeSnapshotClassName = "ceph-filesystem";
        accessModes = ["ReadWriteOnce"];
        capacity = "10Gi";
      };
    };
    resources.replicationsources.plex-data-ceph.spec = {
      sourcePVC = "plex-data";
      trigger.schedule = "0 * * * *";
      restic = {
        copyMethod = "Snapshot";
        repository = "plex-data-volsync-ceph";
        cacheStorageClassName = "openebs-hostpath";
        cacheAccessModes = ["ReadWriteOnce"];
        cacheCapacity = "10Gi";
        storageClassName = "ceph-filesystem";
        volumeSnapshotClassName = "ceph-filesystem";
        pruneIntervalDays = 7;
        retain.hourly = 24;
        retain.daily = 7;
        retain.weekly = 5;
      };
    };
    resources.secrets.plex-data-volsync-b2.stringData = {
      RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/plex/data";
      RESTIC_PASSWORD = vals.sops "default.yaml#/passwords/b2-restic";
      B2_ACCOUNT_ID = vals.sops "default.yaml#/backblaze/application_key";
      B2_ACCOUNT_KEY = vals.sops "default.yaml#/backblaze/application_key_id";
    };
    resources.replicationsources.plex-data-b2.spec = {
      sourcePVC = "plex-data";
      trigger.schedule = "0 * * * *";
      restic = {
        copyMethod = "Snapshot";
        repository = "plex-data-volsync-b2";
        cacheStorageClassName = "openebs-hostpath";
        cacheAccessModes = ["ReadWriteOnce"];
        cacheCapacity = "10Gi";
        storageClassName = "ceph-filesystem";
        volumeSnapshotClassName = "ceph-filesystem";
        pruneIntervalDays = 7;
        retain.daily = 7;
      };
    };
    resources.persistentVolumeClaims.plex-data.spec = {
      accessModes = ["ReadWriteOnce"];
      dataSourceRef.kind = "ReplicationDestination";
      dataSourceRef.apiGroup = "volsync.backube";
      dataSourceRef.name = "plex-data-ceph";
      resources.requests.storage = "10Gi";
      storageClassName = "ceph-filesystem";
    };

    # Config
    resources.objectbucketclaims.plex-config-bucket.spec = {
      bucketName = "plex-config";
      storageClassName = "ceph-bucket";
    };
    resources.externalsecrets.plex-config-ceph.spec = {
      dataFrom = [
        {
          extract.key = "plex-config-bucket";
          sourceRef.storeRef.kind = "ClusterSecretStore";
          sourceRef.storeRef.name = "kubernetes-media";
        }
        {
          extract.key = "volsync-restic-passwords";
          sourceRef.storeRef.kind = "ClusterSecretStore";
          sourceRef.storeRef.name = "kubernetes-kube-system";
        }
      ];
      target.name = "plex-config-volsync-ceph";
      target.template.engineVersion = "v2";
      target.template.data = {
        # TODO how can I generate the endpoint from configMaps?
        RESTIC_REPOSITORY = "s3:http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80/plex/config";
        RESTIC_PASSWORD = "{{ .CEPH_RESTIC }}";
        AWS_ACCESS_KEY_ID = "{{ .AWS_ACCESS_KEY_ID }}";
        AWS_SECRET_ACCESS_KEY = "{{ .AWS_SECRET_ACCESS_KEY }}";
      };
    };
    # TODO restic repository and password? secret with block storage
    resources.replicationdestinations.plex-config-ceph.spec = {
      trigger.manual = "1";
      restic = {
        copyMethod = "Snapshot";
        repository = "plex-config-volsync-ceph";
        cacheStorageClassName = "openebs-hostpath";
        cacheAccessModes = ["ReadWriteOnce"];
        cacheCapacity = "1Gi";
        storageClassName = "ceph-block";
        volumeSnapshotClassName = "ceph-block";
        accessModes = ["ReadWriteOnce"];
        capacity = "1Gi";
      };
    };
    resources.replicationsources.plex-config-ceph.spec = {
      sourcePVC = "plex-config";
      trigger.schedule = "0 * * * *";
      restic = {
        copyMethod = "Snapshot";
        repository = "plex-config-volsync-ceph";
        cacheStorageClassName = "openebs-hostpath";
        cacheAccessModes = ["ReadWriteOnce"];
        cacheCapacity = "1Gi";
        storageClassName = "ceph-block";
        volumeSnapshotClassName = "ceph-block";
        pruneIntervalDays = 7;
        retain.hourly = 24;
        retain.daily = 7;
        retain.weekly = 5;
      };
    };
    resources.secrets.plex-config-volsync-b2.stringData = {
      RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/plex/config";
      RESTIC_PASSWORD = vals.sops "default.yaml#/passwords/b2-restic";
      B2_ACCOUNT_ID = vals.sops "default.yaml#/backblaze/application_key";
      B2_ACCOUNT_KEY = vals.sops "default.yaml#/backblaze/application_key_id";
    };
    resources.replicationsources.plex-config-b2.spec = {
      sourcePVC = "plex-config";
      trigger.schedule = "0 * * * *";
      restic = {
        copyMethod = "Snapshot";
        repository = "plex-config-volsync-b2";
        cacheStorageClassName = "openebs-hostpath";
        cacheAccessModes = ["ReadWriteOnce"];
        cacheCapacity = "1Gi";
        storageClassName = "ceph-block";
        volumeSnapshotClassName = "ceph-block";
        pruneIntervalDays = 7;
        retain.daily = 7;
      };
    };
    resources.persistentVolumeClaims.plex-config.spec = {
      accessModes = ["ReadWriteOnce"];
      dataSourceRef.kind = "ReplicationDestination";
      dataSourceRef.apiGroup = "volsync.backube";
      dataSourceRef.name = "plex-config-ceph";
      resources.requests.storage = "1Gi";
      storageClassName = "ceph-block";
    };
  };
}
