{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types toList;
  inherit (types) attrsOf submodule anything;
  inherit (canivete) vals;
  inherit (config.canivete.meta) domain;
in {
  canivete.deploy.system.homeModules.database = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.profiles.databases = lib.mkEnableOption "database administration tools";
    config = lib.mkIf config.dotfiles.profiles.databases {
      home.packages = with pkgs; [dbeaver-bin gobang lazysql rainfrog harlequin dblab];
    };
  };
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = [
    "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
    "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui"
  ];
  # TODO https://github.com/hydradatabase/hydra vs https://github.com/apache/age vs https://github.com/paradedb/paradedb
  # TODO https://github.com/ankane/pghero
  # OperatorConfiguration has a configuration field, not spec, so we need this to pass validation
  # NOTE https://github.com/hall/kubenix/issues/34
  perSystem.canivete.kubenix.clusters.prod.modules.postgres-patch.options.kubernetes.api.resources."acid.zalan.do".v1.OperatorConfiguration = mkOption {
    type = attrsOf (submodule {options.configuration = mkOption {type = attrsOf anything;};});
  };
  perSystem.canivete.kubenix.helm = {
    postgres = {
      namespace = "storage";
      chart = {
        repo = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator";
        chart = "postgres-operator";
        version = "1.12.2";
        sha256 = "3LJs4TYJob9lwB5lmSdNYRq8r7kB8EMxG0WqkQX93aU=";
      };
      values.configGeneral.enable_crd_registration = true;
      values.configKubernetes = {
        pod_environment_configmap = "storage/postgres";
        pod_environment_secret = "postgres-bucket";
      };
      resources = {
        postgresqls.main.spec = {
          teamId = "acid";
          volume.size = "10Gi";
          numberOfInstances = 2;
          users.superadmin = ["superuser"];
          postgresql.version = "16";
        };
        configMaps.postgres.data = {
          AWS_ENDPOINT = "http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local";
          BACKUP_NUM_TO_RETAIN = "7";
          BACKUP_SCHEDULE = "0 3 * * *";
          USE_WALG_BACKUP = "true";
          USE_WALG_RESTORE = "true";
          WAL_S3_BUCKET = "postgres";
        };
        objectbucketclaims.postgres-bucket.spec = {
          bucketName = "postgres";
          storageClassName = "ceph-bucket";
        };
        secrets.postgres-volsync-b2.stringData = {
          RESTIC_REPOSITORY = "s3:http://s3.us-west-004.backblazeb2.com:80/t0rdos/postgres";
          RESTIC_PASSWORD = vals.sops "default.yaml#/passwords/b2-restic";
          B2_ACCOUNT_ID = vals.sops "default.yaml#/backblaze/application_key";
          B2_ACCOUNT_KEY = vals.sops "default.yaml#/backblaze/application_key_id";
        };
        replicationsources.postgres-b2.spec = {
          sourcePVC = "pgdata-main-0";
          trigger.schedule = "0 3 * * *";
          restic = {
            copyMethod = "Snapshot";
            repository = "postgres-volsync-b2";
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
    postgres-ui = {
      namespace = "storage";
      chart = {
        repo = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui";
        chart = "postgres-operator-ui";
        version = "1.12.2";
        sha256 = "SkuTSWzFhQV4lYgTnSWCuwAHloOz4dz7K8YreNEltes=";
      };
      values.envs.resourcesVisible = "True";
      values.envs.targetNamespace = "*";
      values.ingress = {
        enabled = true;
        annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
        annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_groups=/admin";
        annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
        ingressClassName = "external";
        hosts = toList {
          host = "postgres.${domain}";
          paths = ["/"];
        };
      };
    };
  };
}
