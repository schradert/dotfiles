{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (canivete) vals;
  inherit (lib) toList;
  inherit (config.dotfiles) domain;
  subdomain = "actual.${domain}";
  port = 5006;
in {
  # TODO nix built image
  # TODO persistence + volsync
  # TODO LDAP? with authentication
  # TODO pod.enableServiceLinks?
  perSystem.dotfiles.opentofu.passwords.actual = {
    length = 21;
    special = false;
  };
  perSystem.dotfiles.helm.actual = {
    namespace = "office";
    values = {
      controllers.actual.annotations."reloader.stakater.com/auto" = "true";
      controllers.actual.containers.actual = {
        image.repository = "ghcr.io/actualbudget/actual-server";
        image.tag = "24.9.0";
        envFrom = toList {configMapRef.name = "actual-configmap";};
        probes.liveness.enabled = true;
        probes.readiness.enabled = true;
        probes.startup.enabled = true;
        resources.requests.cpu = "12m";
        resources.requests.memory = "128Mi";
        resources.limits.memory = "512Mi";
      };
      service.actual.controller = "actual";
      service.actual.ports.http.port = port;
      ingress.actual = {
        annotations = {
          "external-dns.alpha.kubernetes.io/target" = "external.${domain}";
          "nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
          "nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
          "nginx.ingress.kubernetes.io/auth-snippet" = "proxy_set_header X-Actual-Password ${vals.sops "default.yaml#/passwords/actual"}";
          "nginx.ingress.kubernetes.io/auth-response-headers" = "X-Actual-Password";
        };
        className = "external";
        hosts = toList {
          host = subdomain;
          paths = toList {
            path = "/";
            service.identifier = "actual";
            service.port = "http";
          };
        };
      };
      persistence.data.existingClaim = "actual";
      persistence.data.globalMounts = [{path = "/data";}];
    };
    resources = {
      configMaps.actual-configmap.data = {
        ACTUAL_PORT = builtins.toString port;
        ACTUAL_LOGIN_METHOD = "header";
      };
      objectbucketclaims.actual-bucket.spec = {
        bucketName = "actual";
        storageClassName = "ceph-bucket";
      };
      externalsecrets.actual-ceph.spec = {
        dataFrom = [
          {
            extract.key = "actual-bucket";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-office";
          }
          {
            extract.key = "volsync-restic-passwords";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-kube-system";
          }
        ];
        target.name = "actual-volsync-ceph";
        target.template.engineVersion = "v2";
        target.template.data = {
          # TODO how can I generate the endpoint from configMaps?
          RESTIC_REPOSITORY = "s3:http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80/actual";
          RESTIC_PASSWORD = "{{ .CEPH_RESTIC }}";
          AWS_ACCESS_KEY_ID = "{{ .AWS_ACCESS_KEY_ID }}";
          AWS_SECRET_ACCESS_KEY = "{{ .AWS_SECRET_ACCESS_KEY }}";
        };
      };
      # TODO restic repository and password? secret with block storage
      replicationdestinations.actual-ceph.spec = {
        trigger.manual = "1";
        restic = {
          copyMethod = "Snapshot";
          repository = "actual-volsync-ceph";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "1Gi";
          storageClassName = "ceph-block";
          volumeSnapshotClassName = "ceph-block";
          accessModes = ["ReadWriteOnce"];
          capacity = "1Gi";
        };
      };
      replicationsources.actual-ceph.spec = {
        sourcePVC = "actual";
        trigger.schedule = "0 * * * *";
        restic = {
          copyMethod = "Snapshot";
          repository = "actual-volsync-ceph";
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
      secrets.actual-volsync-b2.stringData = {
        RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/actual";
        RESTIC_PASSWORD = vals.sops "default.yaml#/passwords/b2-restic";
        B2_ACCOUNT_ID = vals.sops "default.yaml#/backblaze/application_key";
        B2_ACCOUNT_KEY = vals.sops "default.yaml#/backblaze/application_key_id";
      };
      replicationsources.actual-b2.spec = {
        sourcePVC = "actual";
        trigger.schedule = "0 * * * *";
        restic = {
          copyMethod = "Snapshot";
          repository = "actual-volsync-b2";
          cacheStorageClassName = "openebs-hostpath";
          cacheAccessModes = ["ReadWriteOnce"];
          cacheCapacity = "1Gi";
          storageClassName = "ceph-block";
          volumeSnapshotClassName = "ceph-block";
          pruneIntervalDays = 7;
          retain.daily = 7;
        };
      };
      persistentVolumeClaims.actual.spec = {
        accessModes = ["ReadWriteOnce"];
        dataSourceRef.kind = "ReplicationDestination";
        dataSourceRef.apiGroup = "volsync.backube";
        dataSourceRef.name = "actual-ceph";
        resources.requests.storage = "1Gi";
        storageClassName = "ceph-block";
      };
    };
  };
}
