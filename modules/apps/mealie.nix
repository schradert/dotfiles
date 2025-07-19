{
  # TODO AI features https://docs.mealie.io/documentation/getting-started/installation/open-ai/
  # TODO bulk import some recipes https://docs.mealie.io/documentation/community-guide/bulk-url-import/
  # TODO bookmarklet https://docs.mealie.io/documentation/community-guide/import-recipe-bookmarklet/
  # TODO theme dracula / stylix
  # TODO keycloak OIDC secret
  # TODO ollama api key + model
  # TODO stalwart SMTP config
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "mealie.${config.domain}";
    image = {
      imageName = "ghcr.io/mealie-recipes/mealie";
      imageDigest = "sha256:4d7542becc4f5a2a87c13f1073c974430006f56207278ade541bd93450b8fb5f";
      hash = "sha256-WRSqIlZEzCm1RoGh/AeDEWmE+qD895Ns7a5fYLpEzCA=";
      finalImageTag = "v3.0.1";
    };
  in {
    options.services.mealie.enable = mkEnableOption "mealie";
    config = mkIf services.mealie.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.mealie = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        dotfiles.postgres.mealie = {};
        applications.mealie = {
          namespace = "dotfiles";
          helm.releases.mealie = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.mealie.containers.mealie = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  envFrom = [{configMapRef.name = "mealie";}];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.mealie.ports.http.port = 9000;
                persistence.secrets = {
                  type = "secret";
                  name = "mealie";
                };
                configMaps.mealie.data = {
                  BASE_URL = "https" + "://${hostname}";
                  ALLOW_SIGNUP = "False";
                  ALLOW_PASSWORD_LOGIN = "False";
                };
              }
              (mkIf services.reloader.enable {
                controllers.mealie.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.mealie = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
              (mkIf services.postgres.enable {
                configMaps.mealie.data = {
                  DB_ENGINE = "postgres";
                  POSTGRES_SERVER = "main.storage.svc.cluster.local";
                  POSTGRES_PASSWORD_FILE = "/secrets/db_password.txt";
                };
              })
              (mkIf services.keycloak.enable {
                configMaps.mealie.data = {
                  OIDC_AUTH_ENABLED = "True";
                  OIDC_CONFIGURATION_URL = "https" + "://keycloak.${config.domain}/realms/primary/.well-known/openid-configuration";
                  OIDC_CLIENT_ID = "mealie";
                  # OIDC_CLIENT_SECRET_FILE = "/secrets/oidc_secret.txt";
                  OIDC_USER_GROUP = "/family";
                  OIDC_ADMIN_GROUP = "/admin";
                  OIDC_AUTO_REDIRECT = "True";
                  OIDC_REMEMBER_ME = "True";
                };
              })
              # (mkIf services.stalwart.enable {
              #   configMaps.mealie.data = {
              #     SMTP_HOST = "";
              #     SMTP_USER = "";
              #     SMTP_PASSWORD_FILE = "/secrets/smtp_password.txt";
              #   };
              # })
              # (mkIf services.ollama.enable {
              #   configMaps.mealie.data = {
              #     OPENAI_BASE_URL = "";
              #     OPENAI_API_KEY_FILE = "/secrets/ai_key.txt";
              #     OPENAI_MODEL = "";
              #   };
              # })
            ];
          };
          resources = mkIf services.external-secrets.enable {
            externalSecrets.mealie.spec = {
              secretStoreRef.name = "bitwarden";
              secretStoreRef.kind = "ClusterSecretStore";
              data = mkMerge [
                (mkIf services.postgres.enable (toList {
                  secretKey = "db_password.txt";
                  remoteRef.key = "mealie.main.credentials.postgresql.acid.zalan.do";
                  remoteRef.property = "password";
                  sourceRef.storeRef.name = "kubernetes-default";
                  sourceRef.storeRef.kind = "ClusterSecretStore";
                }))
                # (mkIf services.keycloak.enable (toList {
                #   secretKey = "oidc_secret.txt";
                #   remoteRef.key = "keycloak/clients/mealie";
                # }))
                # (mkIf services.stalwart.enable (toList {
                #   secretKey = "smtp_password.txt";
                #   remoteRef.key = "stalwart/smtp";
                # }))
                # (mkIf services.ollama.enable (toList {
                #   secretKey = "ai_key.txt";
                #   remoteRef.key = "ollama";
                # }))
              ];
            };
          };
        };
      };
    };
  };
}
