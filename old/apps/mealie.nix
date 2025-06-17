{
  # TODO fix backups
  # TODO AI features https://docs.mealie.io/documentation/getting-started/installation/open-ai/
  # TODO export logs into Loki
  # TODO home-assistant widget
  # TODO bulk import some recipes https://docs.mealie.io/documentation/community-guide/bulk-url-import/
  # TODO bookmarklet https://docs.mealie.io/documentation/community-guide/import-recipe-bookmarklet/
  # TODO nix built image
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (config.services) external-secrets mealie postgres;
    inherit (lib) mkEnableOption mkIf toList;
    subdomain = "mealie.${domain}";
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
      kubenix.dotfiles.postgres.mealie = {};
      kubenix.kubernetes.helm.releases.mealie = {
        namespace = "home";
        extraResources = mkIf (external-secrets.enable && postgres.enable) {
          externalsecrets.mealie.spec = {
            secretStoreRef.name = "kubernetes-default";
            secretStoreRef.kind = "ClusterSecretStore";
            dataFrom = [{extract.key = "mealie.main.credentials.postgresql.acid.zalan.do";}];
            target.template.data.POSTGRES_PASSWORD = "{{ .password }}";
          };
        };
        values = {
          controllers.mealie.annotations."reloader.stakater.com/auto" = "true";
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
          configMaps.mealie-configmap.data = {
            ALLOW_SIGNUP = "false";
            BASE_URL = "https://${subdomain}";
            DB_ENGINE = "postgres";
            OIDC_AUTH_ENABLED = "true";
            OIDC_CONFIGURATION_URL = "https://${"keycloak." + domain}/realms/primary/.well-known/openid-configuration";
            OIDC_CLIENT_ID = "mealie";
            OIDC_USER_GROUP = "/family";
            OIDC_ADMIN_GROUP = "/admin";
            OIDC_AUTO_REDIRECT = "true";
            OIDC_REMEMBER_ME = "true";
            POSTGRES_SERVER = "main.storage.svc.cluster.local";
          };
        };
      };
    };
  };
}
