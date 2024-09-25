{
  config,
  nix,
  self,
  ...
}:
with nix; let
  inherit (config.dotfiles) domain;
  subdomain = "keycloak.${domain}";
  passwords = map (prefix "keycloak-") ["superadmin" "postgres-postgres" "postgres-admin" "tristan" "tahoe"];
in {
  # NOTE https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/web-apps/keycloak.nix
  perSystem.dotfiles = {
    opentofu.passwords = genAttrs passwords (_: {length = mkDefault 21;});
    nix2container.keycloak = {};
    helm.keycloak = {
      namespace = "security";
      resources.secrets.keycloak-secret.stringData = genAttrs passwords (name: vals.sops "default.yaml#/passwords/${name}");
      resources.configMaps.keycloak-configmap.data = {
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
        version = "22.2.5";
        sha256 = "t1bM5+uhcWmbrFQ5HfCTcxbCjiK624kIaaPrv6Q12ok=";
      };
      values = {
        # TODO convert to postgres operator
        # TODO nix image
        # image = genAttrs ["registry" "repository" "tag"] (flip pipe [toUpper (prefix "ref+envsubst://KEYCLOAK_IMAGE_")]);
        auth.adminUser = "superadmin";
        auth.existingSecret = "keycloak-secret";
        auth.passwordSecretKey = "keycloak-superadmin";
        adminRealm = "admin";
        production = true;
        proxyHeaders = "xforwarded";
        extraEnvVarsCM = "keycloak-configmap";
        postgresql.auth = {
          existingSecret = "keycloak-secret";
          secretKeys.adminPasswordKey = "keycloak-postgres-postgres";
          secretKeys.userPasswordKey = "keycloak-postgres-admin";
        };
        startupProbe.enabled = true;
        livnessProbe.initialDelaySeconds = 0;
        readinessProbe.initialDelaySeconds = 0;
        podAnnotations."reloader.stakater.com/auto" = "true";
        ingress = {
          enabled = true;
          ingressClassName = "external";
          annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
          hostname = subdomain;
        };
        rbac.create = true;
        autoscaling.enabled = true;
        autoscaling.maxReplicas = 2;
        metrics = {
          enabled = true;
          serviceMonitor.enabled = true;
          serviceMonitor.namespace = "observability";
          prometheusRule.enabled = true;
          prometheusRule.namespace = "observability";
        };
        # TODO external database
        # TODO declarative realm config
        # TODO terraform vs keycloak-config-cli
        # TODO export realm config
        # keycloakConfigCli.enabled = true;
        # keycloakConfigCli.extraEnvVars = [(nameValuePair "KEYCLOAK_AVAILABILITYCHECK_ENABLED" "false")];
        # keycloakConfigCli.configuration."family.json" = toJSON {
        #   enabled = true;
        #   realm = "family";
        #   displayName = "Family";
        #   roles.realm = [{name = "admin";}];
        #   users = [
        #     {
        #       enabled = true;
        #       username = "tristan";
        #       email = "t0rdos@pm.me";
        #       firstName = "Tristan";
        #       lastName = "Schrader";
        #       realmRoles = ["admin"];
        #       credentials = toList {
        #         type = "password";
        #         userLabel = "initial";
        #         value = vals.sops "default.yaml#/passwords/keycloak-tristan";
        #       };
        #     }
        #     {
        #       enabled = true;
        #       username = "tahoe";
        #       email = "tahoeschrader@gmail.com";
        #       firstName = "Tahoe";
        #       lastName = "Schrader";
        #       realmRoles = ["admin"];
        #       credentials = toList {
        #         type = "password";
        #         userLabel = "initial";
        #         value = vals.sops "default.yaml#/passwords/keycloak-tahoe";
        #       };
        #     }
        #   ];
        #   clients = toList {
        #     enabled = true;
        #     name = "oauth2-proxy";
        #     description = "Oauth2 Proxy";
        #     clientId = "oauth2-proxy";
        #     clientAuthenticatorType = "client-secret";
        #     secret = vals.sops "default.yaml#/passwords/keycloak-oauth2_proxy-secret";
        #     standardFlowEnabled = true;
        #     directAccessGrantsEnabled = false;
        #     redirectUris = ["https://oauth2-proxy.${domain}/oauth2/callback"];
        #     protocolMappers = toList {
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
