{config, nix, ...}: let
  inherit (config.dotfiles) domain;
  inherit (nix) toList vals;
  inherit (vals) sops;
  subdomain = "jitsi.${domain}";
in {
  # TODO integrate with excalidraw https://github.com/jitsi/excalidraw-backend
  perSystem.dotfiles.opentofu.passwords = {
    jitsi-jigasi.length = 10;
    jitsi-jigasi.special = false;
    jitsi-jibri.length = 10;
    jitsi-jibri.special = false;
    jitsi-recorder.length = 10;
    jitsi-recorder.special = false;
    jitsi-jicofo.length = 10;
    jitsi-jicofo.special = false;
    jitsi-jvb.length = 10;
    jitsi-jvb.special = false;
  };
  perSystem.dotfiles.helm.jitsi = {
    namespace = "office";
    chart = {
      repo = "https://jitsi-contrib.github.io/jitsi-helm";
      chart = "jitsi-meet";
      version = "1.4.1";
      sha256 = "8eNkDUbUQQsc4j1kNH7gFot6mjEMTLuKFe/ThYXlslg=";
    };
    values = {
      enableAuth = true;
      enableGuests = false;
      publicURL = subdomain;
      jicofo.xmpp.password = sops "default.yaml#/passwords/jitsi-jicofo";
      jigasi.enabled = true;
      jigasi.xmpp.password = sops "default.yaml#/passwords/jitsi-jigasi";
      jibri = {
        enabled = true;
        metrics.enabled = true;
        persistence.enabled = true;
        persistence.existingClaim = "jitsi-jibri";
        shm.enabled = true;
        shm.useHost = true;
        singleUseMode = true;
        xmpp.password = sops "default.yaml#/passwords/jitsi-jibri";
        recorder.password = sops "default.yaml#/passwords/jitsi-recorder";
      };
      jvb = {
        metrics.enabled = true;
        metrics.grafanaDashboards.enabled = true;
        publicIPs = ["192.168.50.202"];
        service.externalIPs = ["192.168.50.202"];
        xmpp.password = sops "default.yaml#/passwords/jitsi-jvb";
      };
      prosody.persistence = {
        enabled = true;
        size = "1Gi";
        storageClassName = "ceph-filesystem";
      };
      # TODO look through useful plugins https://github.com/jitsi-contrib/prosody-plugins
      # prosody.extraVolumes = toList {
      #   name = "prosody-modules";
      #   configMap.name = "prosody-modules";
      # };
      # prosody.extraVolumeMounts = [
      #   {
      #      name = "prosody-modules";
      #      subPath = "mod_measure_client_presence.lua";
      #      mountPath = "/prosody-plugins-custom/mod_measure_client_presence.lua";
      #   }
      # ];
      # TODO should I deploy a STUN server?
      # stunServers = ["meet-jit-si-turnrelay.jitsi.net:443"];
      web.ingress = {
        enabled = true;
        ingressClassName = "external";
        annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
        hosts = toList {
          host = subdomain;
          paths = ["/"];
        };
      };
      web.resources.limits.memory = "512Mi";
      web.resources.requests = {
        cpu = "100m";
        memory = "128Mi";
      };
      websockets.colibri.enablied = true;
      websockets.xmpp.enabled = true;
    };
    resources = {
      objectbucketclaims.jitsi-jibri-bucket.spec = {
        bucketName = "jitsi-jibri";
        storageClassName = "ceph-bucket";
      };
      externalsecrets.jitsi-jibri-ceph.spec = {
        dataFrom = [
          {
            extract.key = "jitsi-jibri-bucket";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-office";
          }
          {
            extract.key = "volsync-restic-passwords";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-kube-system";
          }
        ];
        target.name = "jitsi-jibri-volsync-ceph";
        target.template.engineVersion = "v2";
        target.template.data = {
          # TODO how can I generate the endpoint from configMaps?
          RESTIC_REPOSITORY = "s3:http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80/jitsi-jibri";
          RESTIC_PASSWORD = "{{ .CEPH_RESTIC }}";
          AWS_ACCESS_KEY_ID = "{{ .AWS_ACCESS_KEY_ID }}";
          AWS_SECRET_ACCESS_KEY = "{{ .AWS_SECRET_ACCESS_KEY }}";
        };
      };
      # TODO restic repository and password? secret with block storage
      replicationdestinations.jitsi-jibri-ceph.spec = {
        trigger.manual = "1";
        restic = {
          copyMethod = "Snapshot";
          repository = "jitsi-jibri-volsync-ceph";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "10Gi";
          storageClassName = "ceph-block";
          volumeSnapshotClassName = "ceph-block";
          accessModes = ["ReadWriteOnce"];
          capacity = "10Gi";
        };
      };
      replicationsources.jitsi-jibri-ceph.spec = {
        sourcePVC = "jitsi-jibri";
        trigger.schedule = "0 * * * *";
        restic = {
          copyMethod = "Snapshot";
          repository = "jitsi-jibri-volsync-ceph";
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
      secrets.jitsi-jibri-volsync-b2.stringData = {
        RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/jitsi-jibri";
        RESTIC_PASSWORD = sops "default.yaml#/passwords/b2-restic";
        B2_ACCOUNT_ID = sops "default.yaml#/backblaze/application_key";
        B2_ACCOUNT_KEY = sops "default.yaml#/backblaze/application_key_id";
      };
      replicationsources.jitsi-jibri-b2.spec = {
        sourcePVC = "jitsi-jibri";
        trigger.schedule = "0 * * * *";
        restic = {
          copyMethod = "Snapshot";
          repository = "jitsi-jibri-volsync-b2";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "10Gi";
          storageClassName = "ceph-block";
          volumeSnapshotClassName = "ceph-block";
          pruneIntervalDays = 7;
          retain.daily = 7;
        };
      };
      persistentVolumeClaims.jitsi-jibri.spec = {
        accessModes = ["ReadWriteOnce"];
        dataSourceRef.kind = "ReplicationDestination";
        dataSourceRef.apiGroup = "volsync.backube";
        dataSourceRef.name = "jitsi-jibri-ceph";
        resources.requests.storage = "10Gi";
        storageClassName = "ceph-block";
      };
    };
  };
}
