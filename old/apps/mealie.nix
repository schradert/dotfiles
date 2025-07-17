{
  # TODO AI features https://docs.mealie.io/documentation/getting-started/installation/open-ai/
  # TODO bulk import some recipes https://docs.mealie.io/documentation/community-guide/bulk-url-import/
  # TODO bookmarklet https://docs.mealie.io/documentation/community-guide/import-recipe-bookmarklet/
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (config.services) external-secrets mealie postgres;
    inherit (lib) mkEnableOption mkIf toList;
    hostname = "mealie.${domain}";
    image = {
      imageName = "ghcr.io/mealie-recipes/mealie";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.mealie.enable = mkEnableOption "mealie";
    config = mkIf mealie.enable {
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
                  envFrom = [
                    {configMapRef.name = "mealie";}
                    {secret = "mealie";}
                  ];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.mealie.ports.http.port = 9000;
                configMaps.mealie.data = {
                  ALLOW_SIGNUP = "false";
                  BASE_URL = "https" + "://${hostname}";
                };
              }
              i
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
                };
              })
              (mkIf services.keycloak.enable {
                configMaps.mealie.data = {
                  OIDC_AUTH_ENABLED = "true";
                  OIDC_CONFIGURATION_URL = "https" + "://keycloak.${domain}/realms/primary/.well-known/openid-configuration";
                  OIDC_CLIENT_ID = "mealie";
                  OIDC_USER_GROUP = "/family";
                  OIDC_ADMIN_GROUP = "/admin";
                  OIDC_AUTO_REDIRECT = "true";
                  OIDC_REMEMBER_ME = "true";
                };
              })
            ];
          };
          resources = mkIf (services.external-secrets.enable && services.postgres.enable) {
            externalSecrets.mealie.spec = {
              secretStoreRef.name = "kubernetes-default";
              secretStoreRef.kind = "ClusterSecretStore";
              dataFrom = [{extract.key = "mealie.main.credentials.postgresql.acid.zalan.do";}];
              target.template.data.POSTGRES_PASSWORD = "{{ .password }}";
            };
          };
        };
      };
    };
  };
}
