{
  # NOTE this is currently a symptom of lychee not handling dynamic url building well with explicit protocol
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://oauth2-proxy"];
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (canivete) mkNullableOption toBase64 vals;
    inherit (vals.sops) default;
    inherit (config) domain services;
    inherit (services.oauth2-proxy) enable provider;
    inherit (lib) mapAttrs mkEnableOption mkIf mkMerge getExe types pipe mergeAttrs;
    hostname = "oauth2-proxy.${domain}";
  in {
    options.services.oauth2-proxy = {
      enable = mkEnableOption "oauth2-proxy";
      provider = mkNullableOption (types.enum ["google" "keycloak"]) {description = "Identity provider";};
    };
    config = mkIf enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.oauth2-proxy = pkgs.dockerTools.pullImage {
          imageName = "quay.io/oauth2-proxy/oauth2-proxy";
          imageDigest = "sha256:6f01695a729a2f88d7bc6e1158797d3cbdc0381c358ba86e1aa5da739586b3e0";
          hash = "sha256-ply9GcHR17+Dl7dcUTI9Dv95ckVE8FQ64OCuMQ4dPwE=";
          finalImageTag = "v7.8.2";
        };
      };
      opentofu = mkMerge [
        {
          plugins = ["scottwinkler/shell"];
          sops.oauth2-proxy-cookie = {
            path = ["oauth2-proxy" "cookie-secret"];
            value = "\${ shell_script.oauth2-proxy-cookie.output[\"value\"] }";
          };
          modules = {pkgs, ...}: let
            inherit (pkgs) jq openssl coreutils;
          in {
            # TODO does this even work?!
            resource.shell_script.oauth2-proxy-cookie.lifecycle_commands = {
              create = ''
                ${getExe openssl} rand -base64 32 |
                ${coreutils}/bin/head -c 32 |
                ${coreutils}/bin/base64 |
                ${getExe jq} --raw-input '{"value":.}'
              '';
              delete = "echo";
            };
          };
        }
        # FIXME how can I reliably trigger this after kubernetes is deployed?
        (mkIf (provider == "keycloak") {
          sops.keycloak-oauth2-proxy-client-id = {
            path = ["keycloak" "oauth2-proxy" "client-id"];
            value = "\${ keycloak_openid_client.oauth2-proxy.client_id }";
          };
          sops.keycloak-oauth2-proxy-client-secret = {
            path = ["keycloak" "oauth2-proxy" "client-secret"];
            value = "\${ keycloak_openid_client.oauth2-proxy.client_secret }";
          };
          modules.resource = let
            realm_id = "\${ keycloak_realm.primary.id }";
            client_id = "\${ keycloak_openid_client.oauth2-proxy.client_id }";
          in {
            keycloak_openid_client.oauth2-proxy = {
              inherit realm_id;
              client_id = "oauth2-proxy";
              name = "OAuth2 Proxy";
              description = "OAuth2 Proxy";
              access_type = "PUBLIC";
              standard_flow_enabled = true;
              valid_redirect_uris = ["https://${hostname}/oauth2/callback"];
            };
            keycloak_openid_audience_protocol_mapper.oauth2-proxy = {
              inherit realm_id client_id;
              name = "aud-mapper-${client_id}";
              included_client_audience = client_id;
            };
            keycloak_openid_client_default_scopes.oauth2-proxy = {
              inherit realm_id client_id;
              default_scopes = ["profile" "email" "roles" "web-origins" "\${ keycloak_openid_client_scope.groups.name }"];
            };
          };
        })
      ];
      kubenix = {
        helm,
        pkgs,
        ...
      }: {
        kubernetes.helm.releases.oauth2-proxy = {
          namespace = "security";
          chart = helm.fetch {
            repo = "https://oauth2-proxy.github.io/manifests";
            chart = "oauth2-proxy";
            version = "7.12.8";
            sha256 = "sha256-68jnRK85tWzoPQ3V5/EGQYl0j6mGuSWj7ei+/wMDu/Q=";
          };
          values = {
            config.existingSecret = "oauth2-proxy-secret";
            config.existingConfig = "oauth2-proxy-configmap";
            deploymentAnnotations."reloader.stakater.com/auto" = "true";
            ingress = {
              enabled = true;
              className = "external";
              annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
              hosts = [hostname];
            };
            metrics.serviceMonitor.enabled = services.prometheus.enable;
          };
          extraResources.configMaps.oauth2-proxy-configmap.data."oauth2_proxy.cfg" =
            pipe
            {
              google.provider = "google";
              keycloak.provider = "keycloak-oidc";
              # TODO dynamic realm name
              keycloak.oidc_issuer_url = "https://${"keycloak." + domain}/realms/primary";
            }.${
              provider
            } [
              (mergeAttrs {
                redirect_url = "https://${hostname}/oauth2/callback";
                email_domains = ["*"];
                code_challenge_method = "S256";
                skip_provider_button = true;
                cookie_secure = true;
                reverse_proxy = true;
                whitelist_domains = [".${domain}"];
                cookie_domains = [".${domain}"];
                set_xauthrequest = true;
              })
              (pkgs.writers.writeTOML "oauth2-proxy.cfg")
              builtins.readFile
            ];
          extraRresources.secrets.oauth2-proxy-secret.data =
            pipe
            {
              # NOTE These cannot be created programmatically yet because Google has no API for configuring redirection for external apps
              # You can follow their inactivity here https://issuetracker.google.com/issues/116182848?pli=1
              # In the meantime, we do this manually in the interface
              google.client-id = default "google/iap/client-id";
              google.client-secret = default "google/iap/client-secret";
              keycloak.client-id = default "keycloak/oauth2-proxy/client-id";
              keycloak.client-secret = default "keycloak/oauth2-proxy/client-secret";
            }.${
              provider
            } [
              (mergeAttrs {cookie-secret = default "oauth2-proxy/cookie-secret";})
              (mapAttrs (_: toBase64))
            ];
        };
      };
    };
  };
}
