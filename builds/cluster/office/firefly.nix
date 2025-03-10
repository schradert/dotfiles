{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (canivete) vals;
  inherit (config.canivete.meta) domain;
  subdomain = "firefly.${domain}";
in {
  # TODO nix built image
  # TODO persistence + volsync
  # TODO LDAP? with authentication
  # TODO pod.enableServiceLinks?
  # NOTE https://github.com/firefly-iii/kubernetes
  # TODO https://github.com/bahuma20/firefly-iii-ai-categorize
  perSystem.canivete = {
    opentofu.workspaces.deploy.modules.firefly.canivete.passwords = {
      firefly.length = 21;
      firefly-appkey.length = 32;
      firefly-appkey.special = false;
    };
    kubenix.helm.postgres.resources.postgresqls.main.spec = {
      users.firefly = ["createdb"];
      databases.firefly = "firefly";
    };
    kubenix.helm.firefly = {
      namespace = "office";
      chart = {
        repo = "https://firefly-iii.github.io/kubernetes";
        chart = "firefly-iii-stack";
        version = "0.7.3";
        sha256 = "4nPNT2EFm8dbBVdPoRZzPZYvPouWXVF84VzBo0qis3w=";
      };
      values = {
        firefly-db.enabled = false;
        firefly-iii = {
          image.tag = "version-6.1.19";
          persistence.existingClaim = "firefly";
          config.env = {
            AUTHENTICATION_GUARD = "remote_user_guard";
            AUTHENTICATION_GUARD_HEADER = "HTTP_X_AUTH_REQUEST_PREFERRED_USERNAME";
            AUTHENTICATION_GUARD_EMAIL = "HTTP_X_AUTH_REQUEST_EMAIL";
            DB_HOST = "main.storage.svc.cluster.local";
          };
          config.existingSecret = "firefly-secret";
          ingress = {
            enabled = true;
            className = "external";
            annotations = {
              "external-dns.alpha.kubernetes.io/target" = "external.${domain}";
              "nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_groups=/family";
              "nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
              "nginx.ingress.kubernetes.io/auth-response-headers" = "X-Auth-Request-Email, X-Auth-Request-Preferred-Username";
            };
            hosts = [subdomain];
          };
          resources.requests.cpu = "100m";
          resources.requests.memory = "128Mi";
          resources.limits.memory = "256Mi";
          # TODO why does it mistakenly detect autoscaling/v2beta1
          # autoscaling.enabled = true;
          # autoscaling.maxReplicas = 3;
        };
        # TODO https://docs.firefly-iii.org/how-to/data-importer/how-to-configure/
        # TODO https://github.com/dvankley/firefly-plaid-connector-2
        importer = {
          enabled = true;
          fireflyiii.auth.accessToken = vals.sops "default.yaml#/fireflay_pat";
          fireflyiii.vanityUrl = "https://${subdomain}";
          ingress = {
            enabled = true;
            className = "external";
            annotations = {
              "external-dns.alpha.kubernetes.io/target" = "external.${domain}";
              "nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
              "nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
              "nginx.ingress.kubernetes.io/auth-response-headers" = "X-Auth-Request-Email, X-Auth-Request-Preferred-Username";
            };
            hosts = ["firefly-importer-tristan.${domain}"];
          };
          resources.requests.cpu = "100m";
          resources.requests.memory = "128Mi";
          resources.limits.memory = "256Mi";
        };
      };
      resources = {
        deployments.firefly-firefly-iii.metadata.annotations."reloader.stakater.com/auto" = "true";
        externalsecrets.firefly.spec = {
          dataFrom = lib.toList {
            extract.key = "firefly.main.credentials.postgresql.acid.zalan.do";
            sourceRef.storeRef.kind = "ClusterSecretStore";
            sourceRef.storeRef.name = "kubernetes-storage";
          };
          target.name = "firefly-secret";
          target.template.engineVersion = "v2";
          target.template.data = {
            DB_PASSWORD = "{{ .password }}";
            APP_PASSWORD = vals.sops "default.yaml#/passwords/firefly";
            APP_KEY = vals.sops "default.yaml#/passwords/firefly-appkey";
          };
        };
        objectbucketclaims.firefly-bucket.spec = {
          bucketName = "firefly";
          storageClassName = "ceph-bucket";
        };
        externalsecrets.firefly-ceph.spec = {
          dataFrom = [
            {
              extract.key = "firefly-bucket";
              sourceRef.storeRef.kind = "ClusterSecretStore";
              sourceRef.storeRef.name = "kubernetes-office";
            }
            {
              extract.key = "volsync-restic-passwords";
              sourceRef.storeRef.kind = "ClusterSecretStore";
              sourceRef.storeRef.name = "kubernetes-kube-system";
            }
          ];
          target.name = "firefly-volsync-ceph";
          target.template.engineVersion = "v2";
          target.template.data = {
            # TODO how can I generate the endpoint from configMaps?
            RESTIC_REPOSITORY = "s3:http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80/firefly";
            RESTIC_PASSWORD = "{{ .CEPH_RESTIC }}";
            AWS_ACCESS_KEY_ID = "{{ .AWS_ACCESS_KEY_ID }}";
            AWS_SECRET_ACCESS_KEY = "{{ .AWS_SECRET_ACCESS_KEY }}";
          };
        };
        # TODO restic repository and password? secret with block storage
        replicationdestinations.firefly-ceph.spec = {
          trigger.manual = "1";
          restic = {
            copyMethod = "Snapshot";
            repository = "firefly-volsync-ceph";
            cacheStorageClassName = "openebs-hostpath";
            cacheAccessModes = ["ReadWriteOnce"];
            cacheCapacity = "1Gi";
            storageClassName = "ceph-block";
            volumeSnapshotClassName = "ceph-block";
            accessModes = ["ReadWriteOnce"];
            capacity = "1Gi";
          };
        };
        replicationsources.firefly-ceph.spec = {
          sourcePVC = "firefly";
          trigger.schedule = "0 * * * *";
          restic = {
            copyMethod = "Snapshot";
            repository = "firefly-volsync-ceph";
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
        secrets.firefly-volsync-b2.stringData = {
          RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/firefly";
          RESTIC_PASSWORD = vals.sops "default.yaml#/passwords/b2-restic";
          B2_ACCOUNT_ID = vals.sops "default.yaml#/backblaze/application_key";
          B2_ACCOUNT_KEY = vals.sops "default.yaml#/backblaze/application_key_id";
        };
        replicationsources.firefly-b2.spec = {
          sourcePVC = "firefly";
          trigger.schedule = "0 * * * *";
          restic = {
            copyMethod = "Snapshot";
            repository = "firefly-volsync-b2";
            cacheStorageClassName = "openebs-hostpath";
            cacheAccessModes = ["ReadWriteOnce"];
            cacheCapacity = "1Gi";
            storageClassName = "ceph-block";
            volumeSnapshotClassName = "ceph-block";
            pruneIntervalDays = 7;
            retain.daily = 7;
          };
        };
        persistentVolumeClaims.firefly.spec = {
          accessModes = ["ReadWriteOnce"];
          dataSourceRef.kind = "ReplicationDestination";
          dataSourceRef.apiGroup = "volsync.backube";
          dataSourceRef.name = "firefly-ceph";
          resources.requests.storage = "1Gi";
          storageClassName = "ceph-block";
        };
      };
    };
  };
}
