{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (canivete.vals) sops;
  inherit (config.dotfiles) domain;
  port = 8096;
  subdomain = "jellyfin.${domain}";
  probe.enabled = true;
  probe.custom = true;
  probe.spec = {
    httpGet.path = "/health";
    httpGet.port = port;
    initialDelaySeconds = 0;
    periodSeconds = 10;
    timeoutSeconds = 1;
    failureThreshold = 3;
  };
in {
  # TODO https://github.com/CyferShepard/Jellystat
  # TODO figure out hardware acceleration and nodeAffinity
  # TODO find a good helm chart or roll with app-template
  # NOTE https://gitlab.com/bunkbed/backbone/-/blob/migrate-to-on-prem/src/cluster/jellyfin.nix?ref_type=heads
  # NOTE https://jellyfin.org/docs/general/administration/configuration
  #   perSystem.canivete.arion.modules.jellyfin.services.jellyfin = {
  #     nixos.configuration.services = {
  #       jellyfin.enable = true;
  #       jellyseer.enable = true;
  #     };
  #     nixos.useSystemd = true;
  #   };
  perSystem.dotfiles.helm.gatus.values.config.endpoints = lib.toList {
    name = "jellyfin";
    group = "external";
    url = "1.1.1.1";
    interval = "1m";
    ui.hide-hostname = true;
    ui.hide-url = true;
    dns.query-name = subdomain;
    dns.query-type = "A";
    conditions = ["len([BODY]) == 0"];
    # alerts = [{type = "custom";}]; TODO
  };
  perSystem.dotfiles.helm.jellyfin = {
    namespace = "media";
    values = {
      controllers.jellyfin = {
        annotations."reloader.stakater.com/auto" = "true";
        # TODO selector for Intel Quick Sync Video
        pod.nodeSelector."kubernetes.io/hostname" = "octopus";
        containers.jellyfin = {
          image.repository = "ghcr.io/onedr0p/jellyfin";
          image.tag = "10.8.11@sha256:926e2a9f6677a0c7b12feba29f36c954154869318d6a52df72f72ff9c74cf494";
          envFrom = [{configMapRef.name = "jellyfin-configmap";}];
          probes.liveness = probe;
          probes.readiness = probe;
          probes.startup.enabled = false;
          resources.requests.cpu = "100m";
          resources.requests.memory = "512Mi";
          resources.limits.memory = "4Gi";
        };
      };
      service.jellyfin.controller = "jellyfin";
      service.jellyfin.ports.http.port = port;
      ingress.jellyfin = {
        # annotations."nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS";
        annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
        annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_groups=/family";
        annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
        className = "external";
        hosts = lib.toList {
          host = subdomain;
          paths = lib.toList {
            path = "/";
            service.identifier = "jellyfin";
            service.port = "http";
          };
        };
      };
      persistence = {
        transcode.type = "emptyDir";
        transcode.advancedMounts.jellyfin.jellyfin = [{path = "/transcode";}];
        config.existingClaim = "jellyfin";
        config.advancedMounts.jellyfin.jellyfin = [{path = "/config";}];
      };
    };
    resources = {
      configMaps.jellyfin-configmap.data = {
        DOTNET_SYSTEM_IO_DISABLEFILELOCKING = "true";
        JELLYFIN_FFmpeg__probesize = "50000000";
        JELLYFIN_FFmpeg__analyzeduration = "50000000";
        JELLYFIN_PublishedServerUrl = subdomain;
      };
      objectbucketclaims.jellyfin-bucket.spec = {
        bucketName = "jellyfin";
        storageClassName = "ceph-bucket";
      };
      externalsecrets.jellyfin-ceph.spec = {
        dataFrom = [
          {
            extract.key = "jellyfin-bucket";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-office";
          }
          {
            extract.key = "volsync-restic-passwords";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-kube-system";
          }
        ];
        target.name = "jellyfin-volsync-ceph";
        target.template.engineVersion = "v2";
        target.template.data = {
          # TODO how can I generate the endpoint from configMaps?
          RESTIC_REPOSITORY = "s3:http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80/jellyfin";
          RESTIC_PASSWORD = "{{ .CEPH_RESTIC }}";
          AWS_ACCESS_KEY_ID = "{{ .AWS_ACCESS_KEY_ID }}";
          AWS_SECRET_ACCESS_KEY = "{{ .AWS_SECRET_ACCESS_KEY }}";
        };
      };
      # TODO restic repository and password? secret with block storage
      replicationdestinations.jellyfin-ceph.spec = {
        trigger.manual = "1";
        restic = {
          copyMethod = "Snapshot";
          repository = "jellyfin-volsync-ceph";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "10Gi";
          storageClassName = "ceph-block";
          volumeSnapshotClassName = "ceph-block";
          accessModes = ["ReadWriteOnce"];
          capacity = "10Gi";
        };
      };
      replicationsources.jellyfin-ceph.spec = {
        sourcePVC = "jellyfin";
        trigger.schedule = "0 * * * *";
        restic = {
          copyMethod = "Snapshot";
          repository = "jellyfin-volsync-ceph";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "10Gi";
          storageClassName = "ceph-block";
          volumeSnapshotClassName = "ceph-block";
          pruneIntervalDays = 7;
          retain.hourly = 24;
          retain.daily = 7;
          retain.weekly = 5;
        };
      };
      secrets.jellyfin-volsync-b2.stringData = {
        RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/jellyfin";
        RESTIC_PASSWORD = sops "default.yaml#/passwords/b2-restic";
        B2_ACCOUNT_ID = sops "default.yaml#/backblaze/application_key";
        B2_ACCOUNT_KEY = sops "default.yaml#/backblaze/application_key_id";
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
      persistentVolumeClaims.jellyfin.spec = {
        accessModes = ["ReadWriteOnce"];
        dataSourceRef.kind = "ReplicationDestination";
        dataSourceRef.apiGroup = "volsync.backube";
        dataSourceRef.name = "jellyfin-ceph";
        resources.requests.storage = "10Gi";
        storageClassName = "ceph-block";
      };
    };
  };
}
