let
  repo = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator";
  repo-ui = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui";
in {
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = [repo];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (lib) attrValues concat hasSuffix mkEnableOption mkForce mkIf mkMerge mkOption pipe toList types;
    inherit (types) attrs anything attrsOf either listOf nullOr submodule str;
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
        nixidy = {pkgs, ...}: {
          options.dotfiles.postgres = mkOption {
            default = {};
            description = "Main postgres instance configuration";
            type = attrsOf (submodule ({name, ...}: {
              freeformType = (pkgs.formats.yaml {}).type;
              options = {
                inherit databases;
                users = mkOption {
                  default = {};
                  # TODO i think this really should be a list, but something weird with generated `loaOf str`
                  # type = attrsOf (listOf str);
                  type = attrsOf str;
                  description = "Users to create in the database for this application";
                };
              };
              config.databases.${name} = name;
              config.users.${name} = "createdb";
            }));
          };
        };
      }
      (mkIf config.services.postgres.enable {
        nixos = {config, pkgs, ...}: let
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
            postgres-ui = pullImage {
              imageName = "ghcr.io/zalando/postgres-operator-ui";
              imageDigest = "sha256:e4ecdaebeaabe6e5444ada2a2409b1c94bba627290a652c10e1322cd29fb0c14";
              hash = "sha256-wYQVXdljf303Jdy/8v5+XwwWTL6xztO8IT2Ic3OHt1g=";
              finalImageTag = "v1.12.2";
            };
          };
          home-manager.sharedModules = mkIf config.dotfiles.profiles.client.workstation.enable [
            ({pkgs, ...}: {
              home.packages = with pkgs; [
                dbeaver-bin
                gobang
                lazysql
                rainfrog
                harlequin
                dblab
              ];
            })
          ];
        };
        nixidy = {config, lib, ...}: let
          chart = lib.helm.downloadHelmChart {
            chart = "postgres-operator";
            version = "1.14.0";
            inherit repo;
            chartHash = "sha256-VB3RglaZ9Zu3F2GdcLpVh899d6o7LRg6VDsiq5U6NsA=";
          };
        in {
          dotfiles.crds.postgres = {
            src = chart;
            prefix = "crds/";
            crds = ["operatorconfigurations" "postgresqls" "postgresteams"];
          };
          nixidy.applicationImports = [
            ({options, config, ...}: {
              # TODO why is metadata not determined from the CRD?
              # NOTE this is how it is done in the generated kubernetes core modules
              options.resources."acid.zalan.do".v1 = {
                OperatorConfiguration = mkOption {
                  type = attrsOf (submodule {
                    options.metadata = mkOption {
                      type = nullOr (submodule {
                        options = config.definitions."io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta".options or {};
                        config = config.definitions."io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta".config or {};
                      });
                    };
                  });
                };
                postgresql = mkOption {
                  type = attrsOf (submodule {
                    options.metadata = mkOption {
                      type = nullOr (submodule {
                        options = config.definitions."io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta".options or {};
                        config = config.definitions."io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta".config or {};
                      });
                    };
                    # options.spec = mkOption {
                    #   type = submodule {
                    #     options.users = mkOption {
                    #       type = attrsOf (listOf str);
                    #       default = {};
                    #     };
                    #     # Doesn't seem to merge properly without this...
                    #     # options = {inherit databases;};
                    #   };
                    # };
                  });
                };
              };
            })
          ];
          applications.postgres = {
            namespace = "storage";
            dotfiles.volsync.pvcs.postgres = {
              title = "pgdata-main-0";
              gid = 103;
            };
            helm.releases.postgres = {inherit chart;};
            helm.releases.postgres-ui = {
              chart = lib.helm.downloadHelmChart {
                chart = "postgres-operator-ui";
                version = "1.12.2";
                repo = repo-ui;
                chartHash = "SkuTSWzFhQV4lYgTnSWCuwAHloOz4dz7K8YreNEltes=";
              };
              values.envs.resourcesVisible = "True";
              values.envs.targetNamespace = "*";
            };
            resources = {
              "gateway.networking.k8s.io".v1.HTTPRoute.postgres-ui.spec = {
                hostnames = ["postgres.${domain}"];
                parentRefs = toList {
                  name = "internal";
                  namespace = "kube-system";
                  sectionName = "https";
                };
                rules = toList {
                  backendRefs = toList {
                    name = "postgres-ui-postgres-operator-ui";
                    port = 80;
                  };
                };
              };
              # NOTE /home/postgres/pgdata/pgroot/data is only accessible by the postgres user
              "volsync.backube".v1alpha1.ReplicationSource.volsync--postgres--postgres-src.spec.restic.moverSecurityContext.runAsUser = 101;
              "acid.zalan.do".v1.postgresql.main.spec = pipe config.dotfiles.postgres [
                attrValues
                (concat (toList {
                  teamId = "acid";
                  volume.size = "10Gi";
                  numberOfInstances = 1;
                  users.superadmin = "superuser";  # TODO ["superuser"]
                  postgresql.version = "16";
                }))
                mkMerge
              ];
              # TODO is there a cleaner way to ensure the value is parsed correctly, like type casting? bug report?
              # NOTE https://github.com/zalando/postgres-operator/blob/68c4b496365f02afb57b9066492dfa319120622a/charts/postgres-operator/values.yaml#L488
              "scheduling.k8s.io".v1.PriorityClass.postgres-postgres-operator-pod.value = mkForce 1000000;
            };
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
          kubernetes.helm.releases = {
            postgres = {
              namespace = "storage";
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
            };
            postgres-ui = {
              namespace = "storage";
              chart = helm.fetch {
                repo = repo-ui;
                chart = "postgres-operator-ui";
                version = "1.12.2";
                sha256 = "SkuTSWzFhQV4lYgTnSWCuwAHloOz4dz7K8YreNEltes=";
              };
              values.envs.resourcesVisible = "True";
              values.envs.targetNamespace = "*";
              extraResources.httproutes.postgres-ui.spec = {
                hostnames = ["postgres.${domain}"];
                parentRefs = toList {
                  name = "internal";
                  namespace = "kube-system";
                  sectionName = "https";
                };
                rules = toList {
                  backendRefs = toList {
                    name = "postgres-ui-postgres-operator-ui";
                    port = 80;
                  };
                };
              };
            };
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
