let
  repo = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator";
in {
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = [repo];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) attrValues concat hasSuffix mkEnableOption mkForce mkIf mkMerge mkOption pipe toList types;
    inherit (types) attrs attrsOf either listOf submodule str;
    databases = mkOption {
      default = {};
      type = attrsOf str;
      description = "Database to owning user mapping for this application";
    };
  in {
    options.services.postgres.enable = mkEnableOption "Postgres";
    config = mkMerge [
      {
        kubenix = {pkgs, ...}: {
          options.dotfiles.postgres = mkOption {
            default = {};
            description = "Main postgres instance configuration";
            type = attrsOf (submodule ({name, ...}: {
              freeformType = (pkgs.formats.yaml {}).type;
              options = {
                inherit databases;
                users = mkOption {
                  default = {};
                  type = attrsOf (listOf str);
                  description = "Users to create in the database for this application";
                };
              };
              config.databases.${name} = name;
              config.users.${name} = ["createdb"];
            }));
          };
        };
      }
      (mkIf config.services.postgres.enable {
        nixos = {pkgs, ...}: let
          inherit (pkgs.dockerTools) pullImage;
        in {
          canivete.kubernetes.images = {
            postgres = pullImage {
              imageName = "ghcr.io/zalando/postgres-operator";
              imageDigest = "sha256:4f40cfc2283b8389ff2e85c3af17c428dee29963be20ddb28b451ead9984b6a9";
              hash = "sha256-Bzz5K7G1trg+aptqS73y1TByLad4KXDDLU8JYw5qobA=";
              finalImageTag = "v1.14.0";
            };
            spilo-17 = pullImage {
              imageName = "ghcr.io/zalando/spilo-17";
              imageDigest = "sha256:23861da069941ff5345e6a97455e60a63fc2f16c97857da8f85560370726cbe7";
              hash = "sha256-+z4BmHLAvCOcJZQskV0FiM0ud8edOTjSYr9GO67n5VQ=";
              finalImageTag = "4.0-p2";
            };
            # NOTE pending decision on logical-backup
            # logical-backup = pullImage {
            #   imageName = "ghcr.io/zalando/postgres-operator/logical-backup";
            #   imageDigest = "sha256:c8c600e4ca0acdfb7843e2943ae0274763c8f1c03fef5245dc0912a4cbd15c18";
            #   hash = "sha256-8cRPlsaITKxW5bO+dHIWWf/pWqY1asqnY+oPAVMH3Ew=";
            #   finalImageTag = "v1.14.0";
            # };
          };
        };
        kubenix = {
          canivete,
          config,
          helm,
          pkgs,
          ...
        }: {
          canivete.ifd.crds = {
            operatorconfigurations = "acid.zalan.do/v1/OperatorConfiguration";
            postgresqls = "acid.zalan.do/v1/postgresql";
          };
          kubernetes.imports =
            pipe {
              owner = "zalando";
              repo = "postgres-operator";
              rev = "v1.14.0";
              hash = "sha256-DK7H43rZY93jN4ONOmcAnAZzuNEdqESGa0b6FEfg23s=";
            } [
              pkgs.fetchFromGitHub
              (source: source + "/charts/postgres-operator/crds")
              (canivete.filesets.files (name: _: hasSuffix ".yaml" name))
            ];
          kubernetes.helm.releases.postgres = {
            chart = helm.fetch {
              inherit repo;
              chart = "postgres-operator";
              version = "1.14.0";
              sha256 = "sha256-VB3RglaZ9Zu3F2GdcLpVh899d6o7LRg6VDsiq5U6NsA=";
            };
            extraResources.postgresqls.main.spec = pipe config.dotfiles.postgres [
              attrValues
              (concat (toList {
                teamId = "acid";
                volume.size = "10Gi";
                numberOfInstances = 1;
                users.superadmin = ["superuser"];
                postgresql.version = "16";
              }))
              mkMerge
            ];
            dotfiles.volsync.pvcs.postgres = {
              title = "pgdata-main-0";
              gid = 103;
            };
            # NOTE /home/postgres/pgdata/pgroot/data is only accessible by the postgres user
            extraResources.replicationsources.volsync--postgres--postgres-src.spec.restic.moverSecurityContext.runAsUser = 101;
            # TODO are there advantages over this logical-backup process compared to volsync?
            # NOTE this path was considered because there is no way to override dataSourceRef
            # extraResources.secrets.postgres-logical-backup.data = mapAttrs (_: toBase64) {
            #   AWS_ACCESS_KEY_ID = minio.minio_user;
            #   AWS_SECRET_ACCESS_KEY = minio.minio_password;
            # };
            # values.configLogicalBackup = {
            #   logical_backup_docker_image = "ghcr.io/zalando/postgres-operator/logical-backup:v1.14.0";
            #   logical_backup_s3_bucket = vals.sops.default "hetzner/s3/bucket";
            #   logical_backup_s3_bucket_prefix = "backups/volsync--postgres--pgdata-main-0";
            #   logical_backup_s3_region = minio.minio_region;
            #   logical_backup_s3_endpoint = minio.minio_server;
            #   logical_backup_s3_retention_time = "8 days";
            #   logical_backup_schedule = "0 4 * * *";
            #   logical_backup_cronjob_environment_secret = "postgres-logical-backup";
            # };
          };

          # Overrides
          kubernetes.api = _: {
            options.resources."acid.zalan.do".v1 = {
              # NOTE https://github.com/hall/kubenix/issues/34#issuecomment-1724690532
              OperatorConfiguration = mkOption {
                type = attrsOf (submodule {
                  # TODO why doesn't this work? how can I provide a better type?
                  # options.configuration = (config.kubernetes.customTypes.operatorconfigurations.module.configuration;
                  options.configuration = mkOption {type = types.attrsOf types.anything;};
                });
              };
              # Doesn't seem to merge properly without this...
              postgresql = mkOption {
                type = attrsOf (submodule {
                  options.spec = mkOption {
                    type = either attrs (submodule {
                      options = {inherit databases;};
                    });
                  };
                });
              };
            };
            # TODO is there a cleaner way to ensure the value is parsed correctly, like type casting? bug report?
            # NOTE https://github.com/zalando/postgres-operator/blob/68c4b496365f02afb57b9066492dfa319120622a/charts/postgres-operator/values.yaml#L488
            config.resources."scheduling.k8s.io".v1.PriorityClass.postgres-postgres-operator-pod.value = mkForce 1000000;
          };
        };
      })
    ];
  };
}
