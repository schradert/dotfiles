{config, nix, ...}: with nix; let
  inherit (config.dotfiles) domain;
  subdomain = "mealie.${domain}";
in {
  # TODO fix backups
  # TODO AI features https://docs.mealie.io/documentation/getting-started/installation/open-ai/
  # TODO export logs into Loki
  # TODO home-assistant widget
  # TODO bulk import some recipes https://docs.mealie.io/documentation/community-guide/bulk-url-import/
  # TODO bookmarklet https://docs.mealie.io/documentation/community-guide/import-recipe-bookmarklet/
  # TODO nix built image
  perSystem.dotfiles = {
    nix2container.mealie = {};
    helm.postgres.resources.postgresqls.main.spec = {
      users.mealie = ["createdb"];
      databases.mealie = "mealie";
    };
    helm.mealie = {
      namespace = "home";
      values = {
        controllers.mealie.annotations."reloader.stakater.com/auto" = "true";
        controllers.mealie.containers.mealie = {
          image.repository = "ghcr.io/mealie-recipes/mealie";
          image.tag = "v1.12.0";
          envFrom = [
            {configMapRef.name = "mealie-configmap";}
            {secret = "mealie-secret";}
          ];
          probes.liveness.enabled = true;
          probes.readiness.enabled = true;
          probes.startup.enabled = true;
          resources.requests.cpu = "5m";
          resources.requests.memory = "256Mi";
          resources.limits.memory = "512Mi";
        };
        service.mealie.controller = "mealie";
        service.mealie.ports.http.port = 9000;
        ingress.mealie = {
          annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
          className = "external";
          hosts = toList {
            host = subdomain;
            paths = toList {
              path = "/";
              service.identifier = "mealie";
              service.port = "http";
            };
          };
        };
        # persistence.data.existingClaim = "mealie";
        # persistence.data.globalMounts = [{path = "/app/data";}];
      };
      resources.configMaps.mealie-configmap.data = {
        ALLOW_SIGNUP = "false";
        BASE_URL = "https://${subdomain}";
        DB_ENGINE = "postgres";
        OIDC_AUTH_ENABLED = "true";
        OIDC_CONFIGURATION_URL = "https://keycloak.${domain}/realms/primary/.well-known/openid-configuration";
        OIDC_CLIENT_ID = "mealie";
        OIDC_USER_GROUP = "/family";
        OIDC_ADMIN_GROUP = "/admin";
        OIDC_AUTO_REDIRECT = "true";
        OIDC_REMEMBER_ME = "true";
        POSTGRES_SERVER = "main.storage.svc.cluster.local";
      };
      resources.externalsecrets.mealie.spec = {
        dataFrom = toList {
          extract.key = "mealie.main.credentials.postgresql.acid.zalan.do";
          sourceRef.storeRef.kind = "ClusterSecretStore";
          sourceRef.storeRef.name = "kubernetes-storage";
        };
        target.name = "mealie-secret";
        target.template.engineVersion = "v2";
        target.template.data.POSTGRES_PASSWORD = "{{ .password }}";
      };
      # resources.objectbucketclaims.mealie-bucket.spec = {
      #   bucketName = "mealie";
      #   storageClassName = "ceph-bucket";
      # };
      # resources.externalsecrets.mealie-ceph.spec = {
      #   dataFrom = [
      #     {
      #       extract.key = "mealie-bucket";
      #       sourceRef.storeRef.kind = "ClusterSecretStore";
      #       sourceRef.storeRef.name = "kubernetes-home";
      #     }
      #     {
      #       extract.key = "volsync-restic-passwords";
      #       sourceRef.storeRef.kind = "ClusterSecretStore";
      #       sourceRef.storeRef.name = "kubernetes-kube-system";
      #     }
      #   ];
      #   target.name = "mealie-volsync-ceph";
      #   target.template.engineVersion = "v2";
      #   target.template.data = {
      #     # TODO how can I generate the endpoint from configMaps?
      #     RESTIC_REPOSITORY = "s3:http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80/mealie";
      #     RESTIC_PASSWORD = "{{ .CEPH_RESTIC }}";
      #     AWS_ACCESS_KEY_ID = "{{ .AWS_ACCESS_KEY_ID }}";
      #     AWS_SECRET_ACCESS_KEY = "{{ .AWS_SECRET_ACCESS_KEY }}";
      #   };
      # };
      # # TODO restic repository and password? secret with block storage
      # resources.replicationdestinations.mealie-ceph.spec = {
      #   trigger.manual = "1";
      #   restic = {
      #     copyMethod = "Snapshot";
      #     repository = "mealie-volsync-ceph";
      #     cacheStorageClassName = "openebs-hostpath";
      #     cacheAccessModes = ["ReadWriteOnce"];
      #     cacheCapacity = "1Gi";
      #     storageClassName = "ceph-block";
      #     volumeSnapshotClassName = "ceph-block";
      #     accessModes = ["ReadWriteOnce"];
      #     capacity = "1Gi";
      #   };
      # };
      # resources.replicationsources.mealie-ceph.spec = {
      #   sourcePVC = "mealie";
      #   trigger.schedule = "0 * * * *";
      #   restic = {
      #     copyMethod = "Snapshot";
      #     repository = "mealie-volsync-ceph";
      #     cacheStorageClassName = "openebs-hostpath";
      #     cacheAccessModes = ["ReadWriteOnce"];
      #     cacheCapacity = "1Gi";
      #     storageClassName = "ceph-block";
      #     volumeSnapshotClassName = "ceph-block";
      #     pruneIntervalDays = 7;
      #     retain.hourly = 24;
      #     retain.daily = 7;
      #     retain.weekly = 5;
      #   };
      # };
      # resources.secrets.mealie-volsync-b2.stringData = {
      #   RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/mealie";
      #   RESTIC_PASSWORD = nix.vals.sops "default.yaml#/passwords/b2-restic";
      #   B2_ACCOUNT_ID = nix.vals.sops "default.yaml#/backblaze/application_key";
      #   B2_ACCOUNT_KEY = nix.vals.sops "default.yaml#/backblaze/application_key_id";
      # };
      # resources.replicationsources.mealie-b2.spec = {
      #   sourcePVC = "mealie";
      #   trigger.schedule = "0 * * * *";
      #   restic = {
      #     copyMethod = "Snapshot";
      #     repository = "mealie-volsync-b2";
      #     cacheStorageClassName = "openebs-hostpath";
      #     cacheAccessModes = ["ReadWriteOnce"];
      #     cacheCapacity = "1Gi";
      #     storageClassName = "ceph-block";
      #     volumeSnapshotClassName = "ceph-block";
      #     pruneIntervalDays = 7;
      #     retain.daily = 7;
      #   };
      # };
      # resources.persistentVolumeClaims.mealie.spec = {
      #   accessModes = ["ReadWriteOnce"];
      #   dataSourceRef.kind = "ReplicationDestination";
      #   dataSourceRef.apiGroup = "volsync.backube";
      #   dataSourceRef.name = "mealie-ceph";
      #   resources.requests.storage = "1Gi";
      #   storageClassName = "ceph-block";
      # };
    };
  };
}
