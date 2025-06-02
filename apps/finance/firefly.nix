{
  # TODO nix built image
  # TODO persistence + volsync
  # TODO LDAP? with authentication
  # TODO pod.enableServiceLinks?
  # NOTE https://github.com/firefly-iii/kubernetes
  # TODO https://github.com/bahuma20/firefly-iii-ai-categorize
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (canivete.vals.sops) default;
    inherit (config) domain;
    inherit (config.services) firefly external-secrets postgres;
    inherit (lib) mkEnableOption mkIf mkMerge;
    subdomain = "firefly.${domain}";
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.firefly.enable = mkEnableOption "firefly-iii";
    config = mkIf firefly.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.firefly = pkgs.dockerTools.pullImage image;};
      opentofu.passwords = {
        firefly.length = 21;
        firefly-appkey.length = 32;
        firefly-appkey.special = false;
      };
      kubenix = {helm, ...}: {
        dotfiles.postgres.firefly = {};
        kubernetes.helm.releases.firefly = {
          namespace = "office";
          chart = helm.fetch {
            repo = "https://firefly-iii.github.io/kubernetes";
            chart = "firefly-iii-stack";
            version = "0.7.3";
            sha256 = "4nPNT2EFm8dbBVdPoRZzPZYvPouWXVF84VzBo0qis3w=";
          };
          extraResources = mkMerge [
            {deployments.firefly-firefly-iii.metadata.annotations."reloader.stakater.com/auto" = "true";}
            (mkIf (external-secrets.enable && postgres.enable) {
              externalsecrets.firefly.spec = {
                secretStoreRef.name = "kubernetes-default";
                secretStoreRef.kind = "ClusterSecretStore";
                dataFrom = [{extract.key = "firefly.main.credentials.postgresql.acid.zalan.do";}];
                target.template.data = {
                  DB_PASSWORD = "{{ .password }}";
                  # TODO move to a separate secret
                  APP_PASSWORD = default "passwords/firefly";
                  APP_KEY = default "passwords/firefly-appkey";
                };
              };
            })
          ];
          values = {
            firefly-db.enabled = false;
            firefly-iii = {
              image.tag = "version-6.1.19";
              persistence.existingClaim = "firefly";
              config.env = {
                AUTHENTICATION_GUARD = "remote_user_guard";
                AUTHENTICATION_GUARD_HEADER = "HTTP_X_AUTH_REQUEST_PREFERRED_USERNAME";
                AUTHENTICATION_GUARD_EMAIL = "HTTP_X_AUTH_REQUEST_EMAIL";
                DB_HOST = "main.storage.svc.cluster.local";
              };
              config.existingSecret = "firefly-secret";
              ingress = {
                enabled = true;
                className = "external";
                annotations = {
                  "external-dns.alpha.kubernetes.io/target" = "external.${domain}";
                  "nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_groups=/family";
                  "nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
                  "nginx.ingress.kubernetes.io/auth-response-headers" = "X-Auth-Request-Email, X-Auth-Request-Preferred-Username";
                };
                hosts = [subdomain];
              };
              resources.requests.cpu = "100m";
              resources.requests.memory = "128Mi";
              resources.limits.memory = "256Mi";
              # TODO why does it mistakenly detect autoscaling/v2beta1
              # autoscaling.enabled = true;
              # autoscaling.maxReplicas = 3;
            };
            # TODO https://docs.firefly-iii.org/how-to/data-importer/how-to-configure/
            # TODO https://github.com/dvankley/firefly-plaid-connector-2
            importer = {
              enabled = true;
              # TODO create access token
              # fireflyiii.auth.accessToken = default "fireflay_pat";
              fireflyiii.vanityUrl = "https://${subdomain}";
              ingress = {
                enabled = true;
                className = "external";
                annotations = {
                  "external-dns.alpha.kubernetes.io/target" = "external.${domain}";
                  "nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
                  "nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
                  "nginx.ingress.kubernetes.io/auth-response-headers" = "X-Auth-Request-Email, X-Auth-Request-Preferred-Username";
                };
                hosts = ["firefly-importer-tristan.${domain}"];
              };
              resources.requests.cpu = "100m";
              resources.requests.memory = "128Mi";
              resources.limits.memory = "256Mi";
            };
          };
        };
      };
    };
  };
}
