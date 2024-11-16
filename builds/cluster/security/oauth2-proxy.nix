{config, nix, ...}: {
  perSystem = {pkgs, ...}: let
    inherit (config.dotfiles) domain;
    inherit (nix) getExe readFile vals;
    inherit (pkgs) writeText git jq sops openssl coreutils;
    subdomain = "oauth2-proxy.${domain}";
    cookie = "oauth2-proxy-cookie";
    cookiePath = "'[\"oauth2-proxy\"][\"cookie\"]'";
    sopsFile = "\"$(${getExe git} rev-parse --show-toplevel)/.canivete/sops/default.yaml\"";
    realm_id = "\${ keycloak_realm.primary.id }";
    client_id = "\${ keycloak_openid_client.oauth2-proxy.client_id }";
  in {
    canivete.opentofu.workspaces.deploy = {
      plugins = ["scottwinkler/shell"];
      modules.oauth2-proxy.resource = {
        shell_script.${cookie}.lifecycle_commands = {
          create = ''
            ${getExe openssl} rand -base64 32 |
            ${coreutils}/bin/head -c 32 |
            ${coreutils}/bin/base64 |
            ${getExe jq} --raw-input '{"value":.}'
          '';
          delete = "echo";
        };
        keycloak_openid_client.oauth2-proxy = {
          inherit realm_id;
          client_id = "oauth2-proxy";
          name = "OAuth2 Proxy";
          description = "OAuth2 Proxy";
          access_type = "PUBLIC";
          standard_flow_enabled = true;
          valid_redirect_uris = ["https://oauth2-proxy.${domain}/oauth2/callback"];
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
    };
    dotfiles.opentofu.sops.oauth2-proxy-cookie = {
      path = ["oauth2-proxy" "cookie"];
      value = "\${ shell_script.${cookie}.output[\"value\"] }";
    };
    dotfiles.helm.oauth2-proxy = {
      namespace = "security";
      chart = {
        repo = "https://oauth2-proxy.github.io/manifests";
        chart = "oauth2-proxy";
        version = "7.7.20";
        sha256 = "GuTKF87zrkCbqvZjO3zty1SKF2KNyPOh1pcY3vGfSz0=";
      };
      # TODO query client ID and secret by splitting keycloak or using terraform
      values = {
        config.existingSecret = "oauth2-proxy-secret";
        config.existingConfig = "oauth2-proxy-configmap";
        deploymentAnnotations."reloader.stakater.com/auto" = "true";
        ingress = {
          enabled = true;
          className = "external";
          annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
          hosts = [subdomain];
        };
        metrics.serviceMonitor.enabled = true;
      };
      resources.configMaps.oauth2-proxy-configmap.data."oauth2_proxy.cfg" = readFile (pkgs.writers.writeTOML "oauth2-proxy.cfg" {
        provider = "keycloak-oidc";
        redirect_url = "https://oauth2-proxy.${domain}/oauth2/callback";
        oidc_issuer_url = "https://keycloak.${domain}/realms/primary";
        email_domains = ["*"];
        code_challenge_method = "S256";
        skip_provider_button = true;
        cookie_secure = true;
        reverse_proxy = true;
        whitelist_domains = [".${domain}"];
        cookie_domains = [".${domain}"];
        set_xauthrequest = true;
      });
      resources.secrets.oauth2-proxy-secret.stringData = {
        client-id = vals.sops "default.yaml#/keycloak/oauth2-proxy/client-id";
        client-secret = vals.sops "default.yaml#/keycloak/oauth2-proxy/client-secret";
        # TODO get this working from opentofu
        cookie-secret = "V0xzc3NIa1d0ditsRFFZMXlYZ1VUVm43eGp3WnBuU2c="; # vals.sops "default.yaml#/oauth2-proxy/cookie";
      };
    };
  };
}
