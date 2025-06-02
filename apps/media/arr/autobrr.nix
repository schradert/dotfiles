{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config.services) autobrr external-secrets postgres;
    inherit (lib) mkEnableOption mkIf toList;
    subdomain = "autobrr.${config.domain}";
    port = 7878;
    image = {
      imageName = "ghcr.io/autobrr/autobrr";
      imageDigest = "sha256:313e146f0d64f489ffb0bc10c8c2e1bfa072c20cb220b7317f2b1eeda712f49b";
      hash = "";
      finalImageTag = "v1.44.0";
    };
  in {
    options.services.autobrr.enable = mkEnableOption "autobrr";
    config = mkIf autobrr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.autobrr = pkgs.dockerTools.pullImage image;};
      opentofu.passwords.autobrr-session-secret.length = 21;
      kubenix.dotfiles.postgres.autobrr = {};
      kubenix.kubernetes.helm.releases.autobrr = {
        namespace = "media";
        extraResources = mkIf (external-secrets.enable && postgres.enable) {
          externalsecrets.autobrr-postgres.spec = {
            secretStoreRef.name = "kubernetes-default";
            secretStoreRef.kind = "ClusterSecretStore";
            dataFrom = [{extract.key = "autobrr.main.credentials.postgresql.acid.zalan.do";}];
            target.template.data.AUTOBRR__POSTGRES_PASS = "{{ .password }}";
          };
        };
        values = {
          controllers.autobrr.annotations."reloader.stakater.com/auto" = "true";
          controllers.autobrr.containers.autobrr = {
            image.repository = image.imageName;
            image.tag = image.finalImageTag;
            envFrom = [
              {secret = "autobrr";}
              {secret = "autobrr-postgres";}
              {configMapRef.name = "autobrr";}
            ];
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.autobrr.controller = "autobrr";
          service.autobrr.ports.http.port = port;
          ingress.autobrr.className = "internal";
          ingress.autobrr.hosts = toList {
            host = subdomain;
            paths = toList {
              path = "/";
              service.identifier = "autobrr";
              service.port = "http";
            };
          };
          secrets.autobrr.data.AUTOBRR__SESSION_SECRET = canivete.toBase64 (canivete.vals.sops.default "passwords/autobrr-session-secret");
          configMaps.autobrr.data = {
            AUTOBRR__DATABASE_TYPE = "postgres";
            AUTOBRR__POSTGRES_HOST = "main.default.svc.cluster.local";
            AUTOBRR__POSTGRES_PORT = "5432";
            AUTOBRR__POSTGRES_DATABASE = "autobrr";
            AUTOBRR__POSTGRES_USER = "autobrr";
            AUTOBRR__CHECK_FOR_UPDATES = "false";
            AUTOBRR__HOST = "0.0.0.0";
            AUTOBRR__PORT = toString port;
            AUTOBRR__LOG_LEVEL = "INFO";
          };
        };
      };
    };
  };
}
