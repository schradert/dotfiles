{
  # TODO theme dracula / stylix
  # TODO connect meilisearch
  # TODO federation
  # TODO stalwart
  # TODO keycloak oauth
  # TODO rook-ceph object store
  # FIXME convert config scripts to declarative settings
  # FIXME persistence filesystem + volsync
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "forgejo.${config.domain}";
    image = {
      imageName = "code.forgejo.org/forgejo/forgejo";
      imageDigest = "sha256:f4c16d0a40959cb83652cb4ac8cdad3273b68fee52dff64b5bf42db95c5c3baa";
      hash = "sha256-6tQwdy5fuKIGfBzWPzvPNSJ8g9BXLtmX/GB4s56VTNY=";
      finalImageTag = "12.0.0";
    };
  in {
    options.services.forgejo.enable = mkEnableOption "forgejo";
    config = mkIf services.forgejo.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.forgejo = pkgs.dockerTools.pullImage image;};
      nixidy = {
        charts,
        pkgs,
        ...
      }: {
        dotfiles.postgres.forgejo = {};
        applications.forgejo = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs.forgejo = "gitea-shared-storage";
          helm.releases.forgejo = _: {
            imports = [
              ({config, ...}: {
                options.settings = canivete.mkNullableOption (pkgs.formats.ini {}).type {};
                config = mkIf (config.settings != null) {
                  values.configMaps.forgejo.data."app.ini" = (pkgs.formats.ini {}).generate "forgejo.ini" config.settings;
                };
              })
            ];
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.forgejo.containers.forgejo = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  envFrom = [{secret = "forgejo";}];
                  probes.readiness = {
                    enabled = true;
                    custom = true;
                    spec = {
                      httpGet.path = "/api/healthz";
                      httpGet.port = "http";
                      initialDelaySeconds = 5;
                      timeoutSeconds = 1;
                      periodSeconds = 10;
                      successThreshold = 1;
                      failureThreshold = 3;
                    };
                  };
                  probes.startup = {
                    enabled = true;
                    custom = true;
                    spec = {
                      tcpSocket.port = "http";
                      initialDelaySeconds = 60;
                      timeoutSeconds = 1;
                      periodSeconds = 10;
                      successThreshold = 1;
                      failureThreshold = 10;
                    };
                  };
                  # TODO is there another way to configure this?
                  env = {
                    GITEA_ADMIN_PASSWORD_MODE = "keepUpdated";
                    GITEA_ADMIN_USERNAME = "superadmin";
                  };
                };
                service.forgejo.ports.http.port = 3000;
                persistence = {
                  config = {
                    type = "persistentVolumeClaim";
                    size = "1Gi";
                    accessMode = "ReadWriteOnce";
                    globalMounts = [{path = "/etc/forgejo";}];
                  };
                  app-ini = {
                    type = "configMap";
                    name = "forgejo";
                    globalMounts = toList {
                      path = "/etc/forgejo/app.ini";
                      subPath = "app.ini";
                    };
                  };
                  data = {
                    type = "persistentVolumeClaim";
                    accessMode = "ReadWriteOnce";
                    size = "1Gi";
                  };
                };
                settings = {
                  actions.ENABLED = true;
                  actions.DEFAULT_ACTIONS_URL = "https://github.com";
                  admin.DISABLE_REGULAR_ORG_CREATION = true;
                  admin.DEFAULT_EMAIL_NOTIFICATIONS = "enabled";
                  server.ROOT_URL = "https" + "://${hostname}";
                  service.DISABLE_REGISTRATION = true;
                  service.EMAIL_NOTIFY_MAIL = true;
                  service.REQUIRE_SIGNIN_VIEW = false;
                };
              }
              (mkIf services.reloader.enable {controllers.forgejo.annotations."reloader.stakater.com/auto" = "true";})
              (mkIf services.cilium.enable {
                route.forgejo = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.postgres.enable {
                settings.database = {
                  DB_TYPE = "postgres";
                  HOST = "main.default.svc.cluster.local";
                  USER = "forgejo";
                };
              })
              (mkIf services.dragonflydb.enable {
                settings.queue.TYPE = "redis";
                settings.session.PROVIDER = "redis";
                settings.cache.ADAPTER = "redis";
              })
              (mkIf services.prometheus.enable {
                settings.metrics = {
                  ENABLED = true;
                  ENABLED_ISSUE_BY_LABEL = true;
                  ENABLED_ISSUE_BY_REPOSITORY = true;
                };
                settings.server.ENABLE_PPROF = true;
                serviceMonitor.forgejo.endpoints = [{port = "http";}];
              })
              (mkIf services.keycloak.enable {
                controllers.forgejo.containers.forgejo.env.GITEA_OAUTH_KEY_0 = "forgejo";
              })
              # (mkIf services.meilisearch.enable {
              #   settings.indexer = {
              #     ISSUE_INDEXER_CONN_STR = "http" + "://meilisearch.storage.svc.cluster.local";
              #     ISSUE_INDEXER_ENABLED = true;
              #     ISSUE_INDEXER_TYPE = "meilisearch";
              #     # NOTE https://github.com/go-gitea/gitea/issues/25976
              #     # REPO_INDEXER_ENABLED = true;
              #     # REPO_INDEXER_TYPE = "meilisearch";
              #   };
              # })
              # (mkIf services.stalwart.enable {
              #   settings.mailer = {
              #     ENABLED = true;
              #     PROTOCOL = "smtp+starttls";
              #     SMTP_ADDR = "";
              #     FROM = "";
              #     USER = "";
              #   };
              # })
            ];
          };
          resources = mkMerge [
            (mkIf services.dragonflydb.enable {
              dragonflies.forgejo.spec = mkMerge [
                {
                  replicas = 1;
                  snapshot.cron = "*/5 * * * *";
                  snapshot.persistentVolumeClaimSpec = {
                    accessModes = ["ReadWriteOnce"];
                    resources.requests.storage = "2Gi";
                  };
                }
                (mkIf services.external-secrets.enable {
                  authentication.passwordFromSecret = {
                    name = "forgejo";
                    key = "DRAGONFLY_PASSWORD";
                  };
                })
              ];
            })
            (mkIf services.external-secrets.enable {
              externalSecrets.forgejo.spec = mkMerge [
                {
                  secretStoreRef.name = "bitwarden";
                  secretStoreRef.kind = "ClusterSecretStore";
                  target.template.data.GITEA_ADMIN_PASSWORD = "{{ .admin }}";
                  data = toList {
                    secretKey = "admin";
                    remoteRef.key = "forgejo";
                  };
                }
                (mkIf services.dragonflydb.enable {
                  data = toList {
                    secretKey = "dragonfly";
                    remoteRef.key = "dragonflydb/forgejo";
                  };
                  target.template.data = let
                    dragonfly = "redis://:{{ .dragonfly }}@forgejo-dragonfly.dotfiles.svc.cluster.local:6379/0?pool_size=100&idle_timeout=180s";
                  in {
                    DRAGONFLY_PASSWORD = "{{ .dragonfly }}";
                    FORGEJO__cache__HOST = dragonfly;
                    FORGEJO__queue__CONN_STR = dragonfly;
                    FORGEJO__session__PROVIDER_CONFIG = dragonfly;
                  };
                })
                (mkIf services.postgres.enable {
                  target.template.data.FORGEJO__database__PASSWD = "{{ .postgres }}";
                  data = toList {
                    secretKey = "postgres";
                    remoteRef.key = "forgejo.main.credentials.postgresql.acid.zalan.do";
                    remoteRef.property = "password";
                    sourceRef.storeRef.name = "kubernetes-default";
                    sourceRef.storeRef.kind = "ClusterSecretStore";
                  };
                })
                (mkIf services.keycloak.enable {
                  target.template.data.GITEA_OAUTH_SECRET_0 = "{{ .keycloak }}";
                  data = toList {
                    secretKey = "{{ .keycloak }}";
                    remoteRef.key = "keycloak/clients/forgejo";
                  };
                })
                # (mkIf services.stalwart.enable {
                #   target.template.data.FORGEJO__mailer__PASSWD = "{{ .stalwart }}";
                #   data = toList {
                #     secretKey = "{{ .stalwart }}";
                #     remoteRef.key = "stalwart/smtp";
                #   };
                # })
              ];
            })
          ];
        };
      };
    };
  };
}
