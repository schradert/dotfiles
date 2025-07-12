{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge optional toList;
    hostname = "autobrr.${config.domain}";
    image = {
      imageName = "ghcr.io/autobrr/autobrr";
      imageDigest = "sha256:b48822759bd28c4e1ea939070f68320748d3f788433c40d932d45a3268e6f040";
      hash = "sha256-EvSm3tMfPn471qtDzlWQZJxtkoTWUlZwO4EAnQWzNrY=";
      finalImageTag = "v1.63.1";
    };
  in {
    options.services.autobrr.enable = mkEnableOption "autobrr";
    config = mkIf services.autobrr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.autobrr = pkgs.dockerTools.pullImage image;};
      opentofu = {
        passwords.autobrr.length = 21;
        dotfiles.secrets.autobrr.value = "\${ random_password.autobrr.result }";
      };
      nixidy = {charts, ...}: {
        dotfiles.postgres.autobrr = {};
        applications.autobrr = {
          namespace = "media";
          dotfiles.volsync.pvcs.autobrr.title = "autobrr";
          helm.releases.autobrr = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.autobrr.containers.autobrr = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  envFrom = [{configMapRef.name = "autobrr";}];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.autobrr.ports.http.port = 7474;
                persistence.config = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "1G";
                };
                persistence.tmpfs = {
                  type = "emptyDir";
                  globalMounts = [
                    {
                      path = "/config/log";
                      subPath = "log";
                    }
                    {
                      path = "/tmp";
                      subPath = "tmp";
                    }
                  ];
                };
                configMaps.autobrr.data = {
                  AUTOBRR__CHECK_FOR_UPDATES = "false";
                  AUTOBRR__HOST = "0.0.0.0";
                  AUTOBRR__LOG_LEVEL = "INFO";
                  AUTOBRR__SESSION_SECRET_FILE = "/secrets/session_secret.txt";
                };
              }
              (mkIf services.reloader.enable {
                controllers.autobrr.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.autobrr = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.postgres.enable {
                AUTOBRR__DATABASE_TYPE = "postgres";
                AUTOBRR__POSTGRES_USER = "autobrr";
                AUTOBRR__POSTGRES_PASSWORD_FILE = "/secrets/db_password.txt";
                AUTOBRR__POSTGRES_HOST = "main.default.svc.cluster.local";
                AUTOBRR__POSTGRES_DATABASE = "autobrr";
              })
            ];
          };
          resources = mkMerge [
            (mkIf services.external-secrets.enable {
              externalSecrets.autobrr.spec = {
                data =
                  [
                    {
                      secretKey = "session_secret.txt";
                      remoteRef.key = "autobrr";
                      sourceRef.storeRef.name = "bitwarden";
                      sourceRef.storeRef.kind = "ClusterSecretStore";
                    }
                  ]
                  ++ (optional services.postgres.enable {
                    secretKey = "db_password.txt";
                    remoteRef.key = "autobrr.main.credentials.postgresql.acid.zalan.do";
                    remoteRef.property = "password";
                    sourceRef.storeRef.name = "kubernetes-default";
                    sourceRef.storeRef.kind = "ClusterSecretStore";
                  });
              };
            })
          ];
        };
      };
    };
  };
}
