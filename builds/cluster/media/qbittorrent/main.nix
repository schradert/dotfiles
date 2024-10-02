{config, nix, ...}: let
  inherit (config.dotfiles) domain;
  inherit (nix) toList readFile vals;
  subdomain = "qbittorrent.${domain}";
  port = 8080;
  probe.enabled = true;
  probe.custom = true;
  probe.spec = {
    httpGet.path = "/api/v2/app/version";
    httpGet.port = port;
    initialDelaySeconds = 30;
    periodSeconds = 30;
    timeoutSeconds = 10;
    failureThreshold = 6;
  };
in {
  # NOTE https://qbittorrent-docs.readthedocs.io/en/latest/cookbook.html#modernized-configuration-template
  perSystem.dotfiles.helm.gatus.values.config.endpoints = toList {
    name = "qbittorrent";
    group = "internal";
    url = "1.1.1.1";
    interval = "1m";
    ui.hide-hostname = true;
    ui.hide-url = true;
    dns.query-name = subdomain;
    dns.query-type = "A";
    conditions = ["len([BODY]) == 0"];
    # alerts = [{type = "custom";}]; FIXME
  };
  perSystem.dotfiles.helm.qbittorrent = {
    namespace = "media";
    values = {
      controllers.qbittorrent.annotations = {
        "reloader.stakater.com/auto" = "true";
        "configmap.reloader.stakater.com/reload" = "qbittorrent-gluetun,qbittorrent-sync,qbittorrent-files";
      };
      controllers.qbittorrent.containers = {
        qbittorrent = {
          image.repository = "ghcr.io/onedr0p/qbittorrent";
          image.tag = "4.6.7@sha256:5391f94b321d563c3b44136a5e799b7e4e4888926c1c31d3081a1cf3e74a9aec";
          envFrom = [
            {configMapRef.name = "qbittorrent-configmap";}
            {secret = "qbittorrent-secret";}
          ];
          probes.liveness = probe;
          probes.readiness = probe;
          probes.startup = {
            enabled = true;
            spec.failureThreshold = 30;
            spec.periodSeconds = 10;
          };
          resources.requests.cpu = "100m";
          resources.requests.memory = "1Gi";
          resources.limits.memory = "8Gi";
        };
        dnsdist.image.repository = "powerdns/dnsdist-19";
        dnsdist.image.tag = "1.9.6@sha256:340c15afe8de8b4ac45856192e506392e29fbc28680b53f560adfd0fb3527606";
        gluetun = {
          image.repository = "qmcgaw/gluetun";
          image.tag = "latest@sha256:33053890f0f703368c4cee603a068490c23fe4d1d6dc2e04a19549825157469d";
          envFrom = [
            {configMapRef.name = "qbittorrent-gluetun";}
            {secret = "qbittorrent-secret";}
          ];
          resources.limits."squat.ai/tun" = "1";
        };
        sync.image.repository = "ghcr.io/bjw-s-labs/gluetun-qb-port-sync";
        sync.image.tag = "0.0.2@sha256:3e800b1eb0ea5b8e5aa70d37f9a012bd6d50f1a7cf4e2e6833cd921d1ef0d994";
        sync.envFrom = [{configMapRef.name = "qbittorrent-sync";}];
      };
      service.qbittorrent.controller = "qbittorrent";
      service.qbittorrent.ports.http.port = port;
      ingress.qbittorrent = {
        annotations."external-dns.alpha.kubernetes.io/target" = "internal.${domain}";
        className = "internal";
        hosts = toList {
          host = subdomain;
          paths = toList {
            path = "/";
            service.identifier = "qbittorrent";
            service.port = "http";
          };
        };
      };
      persistence = {
        config.existingClaim = "qbittorrent-config";
        config.advancedMounts.qbittorrent.qbittorrent = [{path = "/config";}];
        dnsdist.type = "configMap";
        dnsdist.name = "qbittorrent-files";
        dnsdist.advancedMounts.qbittorrent.dnsdist = toList {
          path = "/etc/dnsdist/dnsdist.conf";
          subPath = "dnsdist.conf";
          readOnly = true;
        };
        media.existingClaim = "qbittorrent-media";
        media.advancedMounts.qbittorrent.qbittorrent = [{path = "/downloads";}];
        sync.type = "emptyDir";
        sync.advancedMounts.qbittorrent.sync = [{path = "/config";}];
      };
    };
    resources = {
      configMaps = {
        qbittorrent-configmap.data = {
          QBITTORRENT__PORT = toString port;
          QBT_Preferences__WebUI__AlternativeUIEnabled = "false";
          QBT_Preferences__WebUI__AuthSubnetWhitelistEnabled = "true";
          QBT_Preferences__WebUI__AuthSubnetWhitelist = "10.42.0.0/16,192.168.50.0/24";
        };
        qbittorrent-gluetun.data = {
          DOT = "off";
          DNS_ADDRESS = "127.0.0.2";
          VPN_SERVICE_PROVIDER = "custom";
          VPN_TYPE = "wireguard";
          VPN_INTERFACE = "wg0";
          WIREGUARD_ENDPOINT_PORT = "51820";
          VPN_PORT_FORWARDING = "on";
          VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
          FIREWALL_INPUT_PORTS = toString port;
          FIREWALL_OUTBOUND_SUBNETS = "10.43.0.0/16,192.168.50.0/24";
        };
        qbittorrent-sync.data = {
          CRON_ENABLED = "true";
          QBITTORRENT_WEBUI_PORT = toString port;
          LOG_TIMESTAMP = "false";
        };
        qbittorrent-files.data."dnsdist.conf" = readFile ./dnsdist.conf;
      };
      objectbucketclaims.qbittorrent-config-bucket.spec = {
        bucketName = "qbittorrent-config";
        storageClassName = "ceph-bucket";
      };
      externalsecrets.qbittorrent-config-ceph.spec = {
        dataFrom = [
          {
            extract.key = "qbittorrent-config-bucket";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-office";
          }
          {
            extract.key = "volsync-restic-passwords";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-kube-system";
          }
        ];
        target.name = "qbittorrent-config-volsync-ceph";
        target.template.engineVersion = "v2";
        target.template.data = {
          # TODO how can I generate the endpoint from configMaps?
          RESTIC_REPOSITORY = "s3:http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80/qbittorrent-config";
          RESTIC_PASSWORD = "{{ .CEPH_RESTIC }}";
          AWS_ACCESS_KEY_ID = "{{ .AWS_ACCESS_KEY_ID }}";
          AWS_SECRET_ACCESS_KEY = "{{ .AWS_SECRET_ACCESS_KEY }}";
        };
      };
      # TODO restic repository and password? secret with block storage
      replicationdestinations.qbittorrent-config-ceph.spec = {
        trigger.manual = "1";
        restic = {
          copyMethod = "Snapshot";
          repository = "qbittorrent-config-volsync-ceph";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "2Gi";
          storageClassName = "ceph-filesystem";
          volumeSnapshotClassName = "ceph-filesystem";
          accessModes = ["ReadWriteOnce"];
          capacity = "2Gi";
        };
      };
      replicationsources.qbittorrent-config-ceph.spec = {
        sourcePVC = "qbittorrent-config";
        trigger.schedule = "0 * * * *";
        restic = {
          copyMethod = "Snapshot";
          repository = "qbittorrent-config-volsync-ceph";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "2Gi";
          storageClassName = "ceph-filesystem";
          volumeSnapshotClassName = "ceph-filesystem";
          pruneIntervalDays = 7;
          retain.hourly = 24;
          retain.daily = 7;
          retain.weekly = 5;
        };
      };
      secrets.qbittorrent-config-volsync-b2.stringData = {
        RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/qbittorrent-config";
        RESTIC_PASSWORD = vals.sops "default.yaml#/passwords/b2-restic";
        B2_ACCOUNT_ID = vals.sops "default.yaml#/backblaze/application_key";
        B2_ACCOUNT_KEY = vals.sops "default.yaml#/backblaze/application_key_id";
      };
      replicationsources.qbittorrent-config-b2.spec = {
        sourcePVC = "qbittorrent-config";
        trigger.schedule = "0 * * * *";
        restic = {
          copyMethod = "Snapshot";
          repository = "qbittorrent-config-volsync-b2";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "2Gi";
          storageClassName = "ceph-filesystem";
          volumeSnapshotClassName = "ceph-filesystem";
          pruneIntervalDays = 7;
          retain.daily = 7;
        };
      };
      persistentVolumeClaims.qbittorrent-config.spec = {
        accessModes = ["ReadWriteOnce"];
        dataSourceRef.kind = "ReplicationDestination";
        dataSourceRef.apiGroup = "volsync.backube";
        dataSourceRef.name = "qbittorrent-config-ceph";
        resources.requests.storage = "2Gi";
        storageClassName = "ceph-filesystem";
      };

      objectbucketclaims.qbittorrent-media-bucket.spec = {
        bucketName = "qbittorrent-media";
        storageClassName = "ceph-bucket";
      };
      externalsecrets.qbittorrent-media-ceph.spec = {
        dataFrom = [
          {
            extract.key = "qbittorrent-media-bucket";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-office";
          }
          {
            extract.key = "volsync-restic-passwords";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-kube-system";
          }
        ];
        target.name = "qbittorrent-media-volsync-ceph";
        target.template.engineVersion = "v2";
        target.template.data = {
          # TODO how can I generate the endpoint from configMaps?
          RESTIC_REPOSITORY = "s3:http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80/qbittorrent-media";
          RESTIC_PASSWORD = "{{ .CEPH_RESTIC }}";
          AWS_ACCESS_KEY_ID = "{{ .AWS_ACCESS_KEY_ID }}";
          AWS_SECRET_ACCESS_KEY = "{{ .AWS_SECRET_ACCESS_KEY }}";
        };
      };
      # TODO restic repository and password? secret with block storage
      replicationdestinations.qbittorrent-media-ceph.spec = {
        trigger.manual = "1";
        restic = {
          copyMethod = "Snapshot";
          repository = "qbittorrent-media-volsync-ceph";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "2Gi";
          storageClassName = "ceph-filesystem";
          volumeSnapshotClassName = "ceph-filesystem";
          accessModes = ["ReadWriteOnce"];
          capacity = "10Gi";
        };
      };
      replicationsources.qbittorrent-media-ceph.spec = {
        sourcePVC = "qbittorrent-media";
        trigger.schedule = "0 * * * *";
        restic = {
          copyMethod = "Snapshot";
          repository = "qbittorrent-media-volsync-ceph";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "2Gi";
          storageClassName = "ceph-filesystem";
          volumeSnapshotClassName = "ceph-filesystem";
          pruneIntervalDays = 7;
          retain.hourly = 24;
          retain.daily = 7;
          retain.weekly = 5;
        };
      };
      secrets.qbittorrent-media-volsync-b2.stringData = {
        RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/qbittorrent-media";
        RESTIC_PASSWORD = vals.sops "default.yaml#/passwords/b2-restic";
        B2_ACCOUNT_ID = vals.sops "default.yaml#/backblaze/application_key";
        B2_ACCOUNT_KEY = vals.sops "default.yaml#/backblaze/application_key_id";
      };
      replicationsources.qbittorrent-media-b2.spec = {
        sourcePVC = "qbittorrent-media";
        trigger.schedule = "0 * * * *";
        restic = {
          copyMethod = "Snapshot";
          repository = "qbittorrent-media-volsync-b2";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "2Gi";
          storageClassName = "ceph-filesystem";
          volumeSnapshotClassName = "ceph-filesystem";
          pruneIntervalDays = 7;
          retain.daily = 7;
        };
      };
      persistentVolumeClaims.qbittorrent-media.spec = {
        accessModes = ["ReadWriteOnce"];
        dataSourceRef.kind = "ReplicationDestination";
        dataSourceRef.apiGroup = "volsync.backube";
        dataSourceRef.name = "qbittorrent-media-ceph";
        resources.requests.storage = "10Gi";
        storageClassName = "ceph-filesystem";
      };
    };
  };
}
