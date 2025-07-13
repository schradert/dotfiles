{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkForce mkIf mkMerge toList;
    hostname = "readarr.${config.domain}";
    port = 80;
    image = {
      imageName = "ghcr.io/home-operations/readarr";
      imageDigest = "sha256:8f7551205fbdccd526db23a38a6fba18b0f40726e63bb89be0fb2333ff4ee4cd";
      hash = "sha256-ZKX5tGedpHTJFD8fFO4P0dUZrNUGzSEsNEA3LFVrc5s=";
      finalImageTag = "0.4.18.2805";
    };
    image-rg = {
      imageName = "blampe/rreading-glasses";
      imageDigest = "sha256:7029dbd4b24ce7854724d53451497f40b146198db928ff53d6dad63dad4b3257";
      hash = "sha256-tqFuLhXlEFuBCimd2wOZib88nj/4V+RdjQnWfFXUyoI=";
      finalImageTag = "hardcover";
    };
  in {
    options.services.readarr = {
      enable = mkEnableOption "readarr";
      # TODO can I programmatically set the metadata server?
      # TODO should this just be a different helm release under the same application?
      rreading-glasses.enable = mkEnableOption "rreading-glasses";
    };
    config = mkIf services.readarr.enable (mkMerge [
      {
        nixos = {pkgs, ...}: {canivete.kubernetes.images.readarr = pkgs.dockerTools.pullImage image;};
        opentofu = {
          passwords.readarr = {
            length = 21;
            upper = false;
            special = false;
          };
          dotfiles.secrets.readarr.value = "\${ random_password.readarr.result }";
        };
        nixidy = {charts, ...}: {
          dotfiles.gatus.endpoints.readarr.url = "https" + "://${hostname}";
          dotfiles.postgres.readarr.databases = mkForce {
            readarr-main = "readarr";
            readarr-log = "readarr";
            readarr-cache = "readarr";
          };
          applications.readarr = {
            namespace = "dotfiles";
            dotfiles.volsync.pvcs.readarr.title = "readarr";
            helm.releases.readarr = {
              chart = charts.bjw-s-labs.app-template;
              values = mkMerge [
                {
                  controllers.readarr.containers.readarr = {
                    image.repository = image.imageName;
                    image.tag = image.finalImageTag;
                    envFrom = [{secret = "readarr";} {configMapRef.name = "readarr";}];
                    probes.liveness.enabled = true;
                    probes.readiness.enabled = true;
                    probes.startup.enabled = true;
                  };
                  service.readarr.controller = "readarr";
                  service.readarr.ports.http.port = port;
                  persistence = {
                    config = {
                      type = "persistentVolumeClaim";
                      accessMode = "ReadWriteOnce";
                      size = "1Gi";
                    };
                    # TODO how should I actually store media?
                    # media = {
                    #   type = "nfs";
                    #   server = "nfs.internal";
                    #   path = "/mnt/...";
                    #   globalMounts = toList {
                    #     path = "/media";
                    #     readOnly = true;
                    #   };
                    # };
                    tmpfs = {
                      type = "emptyDir";
                      globalMounts = toList {
                        path = "/tmp";
                        subPath = "tmp";
                      };
                    };
                  };
                  configMaps.readarr.data = {
                    READARR__APP__INSTANCENAME = "readarr";
                    READARR__AUTH__METHOD = "External";
                    READARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
                    READARR__LOG__DBENABLED = "False";
                    READARR__LOG__LEVEL = "info";
                    READARR__SERVER__PORT = builtins.toString port;
                    READARR__UPDATE__BRANCH = "develop";
                  };
                }
                (mkIf services.reloader.enable {
                  controllers.readarr.annotations."reloader.stakater.com/auto" = "true";
                })
                (mkIf services.cilium.enable {
                  route.readarr = {
                    hostnames = [hostname];
                    parentRefs = toList {
                      name = "internal";
                      namespace = "kube-system";
                      sectionName = "https";
                    };
                    rules = toList {
                      backendRefs = toList {
                        name = "readarr";
                        inherit port;
                      };
                    };
                  };
                })
                (mkIf services.postgres.enable {
                  configMaps.readarr.data = {
                    READARR__POSTGRES__USER = "readarr";
                    READARR__POSTGRES__HOST = "main.default.svc.cluster.local";
                  };
                })
              ];
            };
            resources = mkMerge [
              (mkIf services.external-secrets.enable {
                externalSecrets.readarr.spec.data = mkMerge [
                  (toList {
                    secretKey = "READARR__AUTH__APIKEY";
                    remoteRef.key = "readarr";
                    sourceRef.storeRef.name = "bitwarden";
                    sourceRef.storeRef.kind = "ClusterSecretStore";
                  })
                  (mkIf services.postgres.enable (toList {
                    secretKey = "READARR__POSTGRES__PASSWORD";
                    remoteRef.key = "readarr.main.credentials.postgresql.acid.zalan.do";
                    remoteRef.property = "password";
                    sourceRef.storeRef.name = "kubernetes-default";
                    sourceRef.storeRef.kind = "ClusterSecretStore";
                  }))
                ];
              })
            ];
          };
        };
      }
      (mkIf services.readarr.rreading-glasses.enable {
        nixos = {pkgs, ...}: {canivete.kubernetes.images.rreading-glasses = pkgs.dockerTools.pullImage image-rg;};
        opentofu.dotfiles.secrets.hardcover.value = canivete.vals.sops.default "hardcover";
        nixidy = {
          dotfiles.postgres.rreading-glasses = {};
          applications.readarr = {
            helm.releases.readarr.values = mkMerge [
              {
                controllers.rreading-glasses.containers.rreading-glasses = {
                  image.repository = image-rg.imageName;
                  image.tag = image-rg.finalImageTag;
                  envFrom = [{configMapRef.name = "rreading-glasses";}];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.rreading-glasses.controller = "rreading-glasses";
                service.rreading-glasses.ports.http.port = 8788;
                persistence.secrets = {
                  type = "secret";
                  name = "rreading-glasses";
                  globalMounts = toList {
                    path = "/secrets";
                    readOnly = true;
                  };
                };
                configMaps.rreading-glasses.data = {
                  UPSTREAM = "readarr.media.svc.cluster.local";
                  HARDCOVER_AUTH_FILE = "/secrets/hardcover_token.txt";
                };
              }
              (mkIf services.reloader.enable {
                controllers.rreading-glasses.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.postgres.enable {
                configMaps.rreading-glasses.data = {
                  POSTGRES_USER = "rreading-glasses";
                  POSTGRES_PASSWORD_FILE = "/secrets/db_password.txt";
                  POSTGRES_HOST = "main.default.svc.cluster.local";
                };
              })
            ];
            resources = mkMerge [
              (mkIf services.external-secrets.enable {
                externalSecrets.rreading-glasses.spec.data = mkMerge [
                  (toList {
                    secretKey = "hardcover_token.txt";
                    remoteRef.key = "hardcover";
                    sourceRef.storeRef.name = "bitwarden";
                    sourceRef.storeRef.kind = "ClusterSecretStore";
                  })
                  (mkIf services.postgres.enable (toList {
                    secretKey = "db_password.txt";
                    remoteRef.key = "rreading-glasses.main.credentials.postgresql.acid.zalan.do";
                    remoteRef.property = "password";
                    sourceRef.storeRef.name = "kubernetes-default";
                    sourceRef.storeRef.kind = "ClusterSecretStore";
                  }))
                ];
              })
            ];
          };
        };
      })
    ]);
  };
}
