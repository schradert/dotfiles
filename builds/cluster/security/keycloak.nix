{
  config,
  nix,
  self,
  ...
}:
with nix; let
  subdomain = config.dotfiles.domain;
  passwords = map (prefix "keycloak-") ["superadmin" "postgres-postgres" "postgres-admin" "tristan" "tahoe" "oauth2_proxy-secret"];
in {
  # NOTE https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/web-apps/keycloak.nix
  perSystem = {
    dotfiles.opentofu.passwords = genAttrs passwords (_: {length = 21;});
    dotfiles.nix2container.keycloak = {};
    dotfiles.helm.keycloak = {
      namespace = "security";
      resources.secrets.keycloak.stringData = genAttrs passwords (flip pipe [self.lib.nixToEnv (prefix "ref+envsubst://")]);
      resources.configMaps.keycloak.data = {
        KC_DB = "postgres";
        KC_FEATURES = "hostname:v2";
        KC_HOSTNAME = subdomain;
        KC_METRICS_ENABLED = "true";
        KC_HEALTH_ENABLED = "true";
        KC_HTTP_ENABLED = "true";
      };
      chart = {
        chartUrl = "oci://registry-1.docker.io/bitnamicharts/keycloak";
        chart = "keycloak";
        version = "22.1.0";
        sha256 = "hhGdnPDoLxNJYQnrnUSF38Djbxk1U/tkHvFGvLyM+gw=";
      };
      values = {
        image = genAttrs ["registry" "repository" "tag"] (flip pipe [toUpper (prefix "ref+envsubst://KEYCLOAK_IMAGE_")]);
        auth.adminUser = "superadmin";
        auth.existingSecret = "keycloak";
        auth.passwordSecretKey = "keycloak-superadmin";
        adminRealm = "admin";
        production = true;
        proxyHeaders = "xforwarded";
        extraEnvVarsCM = "keycloak";
        postgresql.auth = {
          existingSecret = "keycloak";
          secretKeys.adminPasswordKey = "keycloak-postgres-postgres";
          secretKeys.userPasswordKey = "keycloak-postgres-admin";
        };
        # keycloakConfigCli.enabled = true;
        # keycloakConfigCli.configuration."realm.json" = nix.toJSON {
        #   realm = "family";
        #   displayName = "Family";
        #   enabled = true;
        #   roles.realm = [{name = "admin";}];
        #   users = [
        #     {
        #       enabled = true;
        #       username = "tristan";
        #       email = "t0rdos@pm.me";
        #       firstName = "Tristan";
        #       lastName = "Schrader";
        #       realmRoles = ["admin"];
        #       credentials = nix.toList {
        #         type = "password";
        #         userLabel = "initial";
        #         value = "ref+envsubst://KEYCLOAK_TRISTAN";
        #       };
        #     }
        #     {
        #       enabled = true;
        #       username = "tahoe";
        #       email = "tahoeschrader@gmail.com";
        #       firstName = "Tahoe";
        #       lastName = "Schrader";
        #       realmRoles = ["admin"];
        #       credentials = nix.toList {
        #         type = "password";
        #         userLabel = "initial";
        #         value = "ref+envsubst://KEYCLOAK_TRISTAN";
        #       };
        #     }
        #   ];
        #   clients = nix.toList {
        #     enabled = true;
        #     name = "oauth2-proxy";
        #     description = "Oauth2 Proxy";
        #     clientId = "oauth2-proxy";
        #     clientAuthenticatorType = "client-secret";
        #     secret = "ref+envsubst://KEYCLOAK_OAUTH2_PROXY_SECRET";
        #     standardFlowEnabled = true;
        #     directAccessGrantsEnabled = false;
        #     redirectUris = ["https://oauth2-proxy.${domain}/oauth2/callback"];
        #     protocolMappers = nix.toList {
        #       name = "oauth2-proxy";
        #       protocol = "openid-connect";
        #       config."id.token.claim" = true;
        #       config."access.token.claim" = true;
        #     };
        #   };
        # };
      };
    };
  };
}
